import type { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT, type JWK } from 'jose';
import postgres from 'postgres';
import request from 'supertest';
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { MaintenanceService } from '../../src/account/maintenance.service';
import { AppModule } from '../../src/app.module';
import { configureApp } from '../../src/app';
import { JWT_KEY_RESOLVER } from '../../src/auth/jwt-verifier';
import { ProviderError, WEB_PAYMENT_PROVIDER } from '../../src/billing/billing.types';
import {
  PLAY_API,
  type PlayApi,
  type ProductPurchase,
} from '../../src/billing/google-play/play-client';
import { RTDN_KEY_RESOLVER } from '../../src/billing/google-play/rtdn-verifier';
import { ProductCatalog } from '../../src/billing/product-catalog';
import { DodoProvider } from '../../src/billing/providers/dodo.provider';
import { FeatureFlags } from '../../src/common/feature-flags.service';
import { loadEnv } from '../../src/config/env';
import { makeKeys, setTestEnv, signEs256 } from '../helpers';
import { DODO_SECRET, dodoHeaders, dodoPayment, dodoRefund } from './sign';

const DB_URL = process.env.TEST_DATABASE_URL;
const USER_A = '00000000-0000-4000-8000-0000000000c1';
const USER_B = '00000000-0000-4000-8000-0000000000c2';
const RTDN_AUD = 'https://api.test/v1/billing/google-play/rtdn';
const RTDN_SA = 'pubsub-push@mirthmix.iam.gserviceaccount.com';

describe.skipIf(!DB_URL)('billing (database e2e)', () => {
  let app: NestExpressApplication;
  let sql: postgres.Sql;
  let flags: FeatureFlags;
  let tokenA: string;
  let tokenB: string;
  let signRtdn: (claims: Record<string, unknown>) => Promise<string>;
  const dodoCalls: { url: string; body: Record<string, unknown> }[] = [];
  const play = {
    configured: true,
    getProductPurchase: vi.fn<PlayApi['getProductPurchase']>(),
    acknowledge: vi.fn<PlayApi['acknowledge']>(),
  };

  beforeAll(async () => {
    setTestEnv({
      DATABASE_URL: DB_URL!,
      MAINTENANCE_ENABLED: 'false',
      WEB_PAYMENT_PROVIDER: 'dodo',
      DODO_API_KEY: 'dodo_test_key',
      DODO_WEBHOOK_SECRET: DODO_SECRET,
      DODO_PRODUCT_PREMIUM: 'pdt_unlock',
      GOOGLE_PLAY_RTDN_AUDIENCE: RTDN_AUD,
      GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT: RTDN_SA,
      BILLING_ACCOUNT_SECRET: 'test-billing-account-secret-0123456789abcdef',
    });
    const env = loadEnv();
    const fakeDodoFetch = (async (url: string, init?: RequestInit) => {
      dodoCalls.push({ url: String(url), body: JSON.parse(String(init?.body ?? '{}')) });
      return new Response(
        JSON.stringify({ session_id: 'cks_1', checkout_url: 'https://checkout.dodo.test/cks_1' }),
      );
    }) as unknown as typeof fetch;

    const keys = await makeKeys();
    const rtdn = await generateKeyPair('RS256');
    const rtdnJwk: JWK = { ...(await exportJWK(rtdn.publicKey)), kid: 'g1', alg: 'RS256' };
    signRtdn = (claims) =>
      new SignJWT(claims)
        .setProtectedHeader({ alg: 'RS256', kid: 'g1' })
        .setIssuer('https://accounts.google.com')
        .setAudience(RTDN_AUD)
        .setIssuedAt()
        .setExpirationTime('5m')
        .sign(rtdn.privateKey);

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(JWT_KEY_RESOLVER)
      .useValue(keys.jwks)
      .overrideProvider(WEB_PAYMENT_PROVIDER)
      .useValue(
        new DodoProvider(
          { apiKey: 'k', webhookSecret: DODO_SECRET, env: 'test' },
          new ProductCatalog(env),
          fakeDodoFetch,
        ),
      )
      .overrideProvider(PLAY_API)
      .useValue(play)
      .overrideProvider(RTDN_KEY_RESOLVER)
      .useValue(createLocalJWKSet({ keys: [rtdnJwk] }))
      .compile();
    app = moduleRef.createNestApplication<NestExpressApplication>({
      bodyParser: false,
      rawBody: true,
      logger: false,
    });
    configureApp(app);
    await app.init();
    flags = app.get(FeatureFlags);
    sql = postgres(DB_URL!, { onnotice: () => undefined });
    tokenA = await signEs256(keys.privateKey, { sub: USER_A, email: 'bill-a@test.dev' });
    tokenB = await signEs256(keys.privateKey, { sub: USER_B, email: 'bill-b@test.dev' });
  });

  beforeEach(async () => {
    await sql`delete from auth.users where id in (${USER_A}, ${USER_B})`;
    await sql`insert into auth.users (id, email) values (${USER_A}, 'bill-a@test.dev'), (${USER_B}, 'bill-b@test.dev')`;
    await sql`delete from public.webhook_events`;
    await sql`update public.feature_flags set enabled = true where key = 'billing'`;
    flags.clearCache();
    dodoCalls.length = 0;
    play.getProductPurchase.mockReset();
    play.acknowledge.mockReset();
  });

  afterAll(async () => {
    await sql?.end();
    await app?.close();
  });

  const server = () => app.getHttpServer();
  const asA = (r: request.Test) => r.set('Authorization', `Bearer ${tokenA}`);
  const plan = async (token = tokenA) =>
    (await request(server()).get('/v1/me').set('Authorization', `Bearer ${token}`).expect(200)).body
      .plan;
  const sendDodo = (body: string, headers = dodoHeaders(body)) =>
    request(server())
      .post('/v1/billing/webhooks/dodo')
      .set(headers)
      .set('content-type', 'application/json')
      .send(body);

  describe('config and checkout', () => {
    it('reports availability per channel', async () => {
      const on = (await request(server()).get('/v1/billing/config').expect(200)).body;
      expect(on).toEqual({
        enabled: true,
        web: { provider: 'dodo', available: true },
        googlePlay: {
          available: true,
          packageName: 'com.mirthmix.app',
          productId: 'mirthmix_premium_unlock',
        },
      });
      await sql`update public.feature_flags set enabled = false where key = 'billing'`;
      flags.clearCache();
      const off = (await request(server()).get('/v1/billing/config').expect(200)).body;
      expect(off.enabled).toBe(false);
      expect(off.web.available).toBe(false);
      expect(off.googlePlay.available).toBe(false);
    });

    it('creates a one-time checkout with our user id set server-side', async () => {
      const res = await asA(request(server()).post('/v1/billing/checkout')).send({}).expect(200);
      expect(res.body.url).toBe('https://checkout.dodo.test/cks_1');
      expect(dodoCalls[0]).toMatchObject({
        url: 'https://test.dodopayments.com/checkouts',
        body: {
          product_cart: [{ product_id: 'pdt_unlock', quantity: 1 }],
          customer: { email: 'bill-a@test.dev' },
          metadata: { user_id: USER_A },
        },
      });
    });

    it('refuses checkout when billing is off, signed out, tampered with, or already bought', async () => {
      await request(server()).post('/v1/billing/checkout').send({}).expect(401);
      await sendDodo(dodoPayment({ userId: USER_A })).expect(200);
      const dup = await asA(request(server()).post('/v1/billing/checkout')).send({}).expect(409);
      expect(dup.body).toMatchObject({ code: 'already_purchased', provider: 'dodo' });
      await sql`update public.feature_flags set enabled = false where key = 'billing'`;
      flags.clearCache();
      expect(
        (await asA(request(server()).post('/v1/billing/checkout')).send({}).expect(403)).body.code,
      ).toBe('billing_disabled');
    });

    it('has no subscription portal', async () => {
      await asA(request(server()).post('/v1/billing/portal')).expect(404);
    });
  });

  describe('web webhooks (Dodo)', () => {
    it('unlocks Premium for good from a verified payment', async () => {
      expect((await plan()).id).toBe('free');
      const body = dodoPayment({ userId: USER_A });
      const res = await sendDodo(body, dodoHeaders(body, { id: 'msg_act' })).expect(200);
      expect(res.body).toEqual({ status: 'processed' });
      expect(await plan()).toMatchObject({ id: 'premium', source: 'subscription' });
      const [row] = await sql`select status from public.webhook_events where event_id = 'msg_act'`;
      expect(row!.status).toBe('processed');
      const [sub] =
        await sql`select billing_interval, current_period_end from public.subscriptions where user_id = ${USER_A}`;
      expect(sub).toEqual({ billing_interval: 'one_time', current_period_end: null });
      expect((await plan(tokenB)).id).toBe('free');
    });

    it('matches the payer by email when the user id is missing', async () => {
      await sendDodo(dodoPayment({ userId: null, email: 'BILL-B@test.dev' })).expect(200);
      expect((await plan(tokenB)).id).toBe('premium');
      expect((await plan()).id).toBe('free');
    });

    it('rejects bad signatures and unknown providers without recording anything', async () => {
      const body = dodoPayment({ userId: USER_A });
      await sendDodo(
        body,
        dodoHeaders(body, { secret: DODO_SECRET.replace('whsec_', 'whsec_x') }),
      ).expect(401);
      await sendDodo(body.replace(USER_A, USER_B), dodoHeaders(body)).expect(401);
      await sendDodo(body, {} as ReturnType<typeof dodoHeaders>).expect(401);
      await request(server()).post('/v1/billing/webhooks/paddle').send(body).expect(404);
      expect((await sql`select count(*)::int as n from public.webhook_events`)[0]!.n).toBe(0);
      expect((await plan()).id).toBe('free');
    });

    it('processes each event once', async () => {
      const body = dodoPayment({ userId: USER_A });
      const headers = dodoHeaders(body, { id: 'msg_dup' });
      await sendDodo(body, headers).expect(200);
      expect((await sendDodo(body, headers).expect(200)).body).toEqual({ status: 'duplicate' });
    });

    it('takes Premium away on a refund or a lost dispute, and ignores late payment events', async () => {
      const t = Date.now();
      await sendDodo(
        dodoPayment({ userId: USER_A, timestamp: new Date(t - 3000).toISOString() }),
      ).expect(200);
      expect((await plan()).id).toBe('premium');
      await sendDodo(dodoRefund({ timestamp: new Date(t - 2000).toISOString() })).expect(200);
      expect((await plan()).id).toBe('free');
      // A retried payment.succeeded older than the refund can't bring it back.
      const late = await sendDodo(
        dodoPayment({ userId: USER_A, timestamp: new Date(t - 2500).toISOString() }),
      ).expect(200);
      expect(late.body).toEqual({ status: 'ignored' });
      expect((await plan()).id).toBe('free');

      await sendDodo(dodoPayment({ userId: USER_B, paymentId: 'pay_2' })).expect(200);
      expect((await plan(tokenB)).id).toBe('premium');
      await sendDodo(dodoRefund({ type: 'dispute.lost', paymentId: 'pay_2' })).expect(200);
      expect((await plan(tokenB)).id).toBe('free');
    });

    it('ignores unknown users, products, payments, subscription renewals and other events', async () => {
      const ignored = async (body: string) =>
        expect((await sendDodo(body).expect(200)).body).toEqual({ status: 'ignored' });
      await ignored(dodoPayment({ userId: '00000000-0000-4000-8000-00000000dead' }));
      await ignored(dodoPayment({ userId: USER_A, productId: 'pdt_other' }));
      await ignored(dodoPayment({ userId: USER_A, subscriptionId: 'sub_1' }));
      await ignored(dodoPayment({ userId: USER_A, type: 'payment.failed' }));
      await ignored(dodoRefund({ paymentId: 'pay_unknown' }));
      await ignored(dodoRefund({ type: 'dispute.opened' }));
      expect((await plan()).id).toBe('free');
    });
  });

  describe('account and entitlements', () => {
    it('reports a lifetime unlock and lists only purchases that matter', async () => {
      const free = (await asA(request(server()).get('/v1/me')).expect(200)).body;
      expect(free).toMatchObject({
        plan: { id: 'free', paid: false, source: 'default' },
        entitlements: { premiumContent: false },
        lifetime: false,
        validUntil: null,
        purchases: [],
      });
      await sendDodo(dodoPayment({ userId: USER_A, paymentId: 'pay_refunded' })).expect(200);
      await sendDodo(dodoRefund({ paymentId: 'pay_refunded' })).expect(200);
      await sendDodo(dodoPayment({ userId: USER_A, paymentId: 'pay_kept' })).expect(200);
      const paid = (await asA(request(server()).get('/v1/me')).expect(200)).body;
      expect(paid).toMatchObject({
        plan: { id: 'premium', paid: true, source: 'subscription' },
        entitlements: { premiumContent: true },
        lifetime: true,
        validUntil: null,
      });
      expect(paid.purchases).toHaveLength(1);
      expect(paid.purchases[0]).toMatchObject({ provider: 'dodo', status: 'active' });
      expect(Date.parse(paid.purchases[0].purchasedAt)).not.toBeNaN();
    });

    it('makes everyone free while the billing kill switch is off', async () => {
      await sendDodo(dodoPayment({ userId: USER_A })).expect(200);
      expect((await plan()).id).toBe('premium');
      await sql`update public.feature_flags set enabled = false where key = 'billing'`;
      flags.clearCache();
      expect((await plan()).id).toBe('free');
    });

    it('deletes an account only with confirmation, and then refuses it', async () => {
      await asA(request(server()).delete('/v1/me')).send({}).expect(400);
      await asA(request(server()).delete('/v1/me')).send({ confirm: 'delete' }).expect(400);
      // No SUPABASE_SECRET_KEY in tests: the account is disabled and the auth user removal waits.
      const res = await asA(request(server()).delete('/v1/me'))
        .send({ confirm: 'DELETE' })
        .expect(200);
      expect(res.body).toEqual({ status: 'pending' });
      expect((await asA(request(server()).get('/v1/me')).expect(403)).body.code).toBe(
        'account_deleted',
      );
      await sendDodo(dodoPayment({ userId: USER_A })).expect(200);
      const rows =
        await sql`select count(*)::int as n from public.subscriptions where user_id = ${USER_A}`;
      expect(rows[0]!.n).toBe(0);
      expect((await plan(tokenB)).id).toBe('free');
    });

    it('purges webhook payloads after 30 days', async () => {
      const send = (id: string, paymentId: string) => {
        const body = dodoPayment({ userId: USER_A, paymentId });
        return sendDodo(body, dodoHeaders(body, { id })).expect(200);
      };
      await send('msg_old', 'pay_old');
      await send('msg_new', 'pay_new');
      await sql`update public.webhook_events set received_at = now() - interval '31 days' where event_id = 'msg_old'`;
      const result = await app.get(MaintenanceService).run();
      expect(result.webhookPayloads).toBe(1);
      const rows =
        await sql`select event_id, payload is null as purged from public.webhook_events order by event_id`;
      expect(rows.map((r) => [r.event_id, r.purged])).toEqual([
        ['msg_new', false],
        ['msg_old', true],
      ]);
    });
  });

  describe('Google Play', () => {
    const purchase = (over: Partial<ProductPurchase> & { ref?: string } = {}): ProductPurchase => ({
      purchaseState: 0,
      acknowledgementState: 0,
      purchaseTimeMillis: String(Date.now() - 1000),
      orderId: 'GPA.1234',
      obfuscatedExternalAccountId: over.ref,
      ...over,
    });
    const refFor = async (token: string) =>
      (
        await request(server())
          .get('/v1/billing/google-play/account-ref')
          .set('Authorization', `Bearer ${token}`)
          .expect(200)
      ).body.accountRef as string;
    const verify = (token: string, purchaseToken = 'play-token-abcdef-1') =>
      request(server())
        .post('/v1/billing/google-play/verify')
        .set('Authorization', `Bearer ${token}`)
        .send({ purchaseToken });

    it('gives each user a stable opaque account reference', async () => {
      const a1 = await refFor(tokenA);
      expect(a1).toMatch(/^[0-9a-f]{64}$/);
      expect(await refFor(tokenA)).toBe(a1);
      expect(await refFor(tokenB)).not.toBe(a1);
      expect(a1).not.toContain(USER_A.replace(/-/g, ''));
    });

    it('verifies a purchase with Google, unlocks Premium for good and acknowledges it', async () => {
      const ref = await refFor(tokenA);
      play.getProductPurchase.mockResolvedValue(purchase({ ref }));
      const res = await verify(tokenA).expect(200);
      expect(res.body).toEqual({ planId: 'premium', status: 'active', duplicatePurchase: false });
      expect(play.getProductPurchase).toHaveBeenCalledWith(
        'mirthmix_premium_unlock',
        'play-token-abcdef-1',
      );
      expect(play.acknowledge).toHaveBeenCalledWith(
        'mirthmix_premium_unlock',
        'play-token-abcdef-1',
      );
      const me = (await asA(request(server()).get('/v1/me')).expect(200)).body;
      expect(me).toMatchObject({ plan: { id: 'premium' }, lifetime: true, validUntil: null });
    });

    it('does not acknowledge twice, or a pending payment', async () => {
      const ref = await refFor(tokenA);
      play.getProductPurchase.mockResolvedValue(purchase({ ref, acknowledgementState: 1 }));
      await verify(tokenA).expect(200);
      play.getProductPurchase.mockResolvedValue(purchase({ ref, purchaseState: 2 }));
      expect((await verify(tokenA, 'pending-token-1234').expect(200)).body.status).toBe('on_hold');
      expect(play.acknowledge).not.toHaveBeenCalled();
    });

    it('grants nothing while a payment is pending', async () => {
      const ref = await refFor(tokenA);
      play.getProductPurchase.mockResolvedValue(purchase({ ref, purchaseState: 2 }));
      await verify(tokenA).expect(200);
      expect((await plan()).id).toBe('free');
      const me = (await asA(request(server()).get('/v1/me')).expect(200)).body;
      expect(me.purchases[0]).toMatchObject({ provider: 'google_play', status: 'on_hold' });
    });

    it('refuses a purchase token bought under another account', async () => {
      const refB = await refFor(tokenB);
      await refFor(tokenA);
      play.getProductPurchase.mockResolvedValue(purchase({ ref: refB }));
      expect((await verify(tokenA).expect(403)).body.code).toBe('purchase_account_mismatch');
      play.getProductPurchase.mockResolvedValue(purchase({ ref: undefined }));
      expect((await verify(tokenA).expect(403)).body.code).toBe('purchase_account_mismatch');
      expect((await plan()).id).toBe('free');
      expect(play.acknowledge).not.toHaveBeenCalled();
    });

    it('rejects unknown tokens (including ones for other products)', async () => {
      await refFor(tokenA);
      play.getProductPurchase.mockRejectedValue(new ProviderError('nope', 404));
      expect((await verify(tokenA).expect(400)).body.code).toBe('invalid_purchase');
      play.getProductPurchase.mockRejectedValue(new ProviderError('down', 503));
      expect((await verify(tokenA).expect(502)).body.code).toBe('play_unreachable');
    });

    it('warns when Premium was already bought on the web', async () => {
      await sendDodo(dodoPayment({ userId: USER_A })).expect(200);
      const ref = await refFor(tokenA);
      play.getProductPurchase.mockResolvedValue(purchase({ ref }));
      expect((await verify(tokenA).expect(200)).body.duplicatePurchase).toBe(true);
    });

    describe('Real-time Developer Notifications', () => {
      let validToken: string;
      beforeAll(async () => {
        validToken = await signRtdn({ email: RTDN_SA, email_verified: true });
      });
      const push = (data: object, opts: { messageId?: string; token?: string | null } = {}) => {
        const bearer = opts.token === null ? undefined : (opts.token ?? validToken);
        const req = request(server()).post('/v1/billing/google-play/rtdn');
        if (bearer) req.set('Authorization', `Bearer ${bearer}`);
        return req.send({
          message: {
            data: Buffer.from(JSON.stringify(data)).toString('base64'),
            messageId: opts.messageId ?? `m-${Math.random()}`,
          },
          subscription: 'projects/p/subscriptions/s',
        });
      };
      const base = (at = Date.now()) => ({
        version: '1.0',
        packageName: 'com.mirthmix.app',
        eventTimeMillis: String(at),
      });
      const note = (type: number, token = 'play-token-abcdef-1', at = Date.now()) => ({
        ...base(at),
        oneTimeProductNotification: {
          version: '1.0',
          notificationType: type,
          purchaseToken: token,
          sku: 'mirthmix_premium_unlock',
        },
      });
      const voided = (productType: number, token = 'play-token-abcdef-1', at = Date.now()) => ({
        ...base(at),
        voidedPurchaseNotification: { purchaseToken: token, orderId: 'GPA.1234', productType },
      });

      it('rejects pushes without a valid Google token', async () => {
        await push(note(1), { token: null }).expect(401);
        await push(note(1), {
          token: await signRtdn({ email: 'attacker@x.com', email_verified: true }),
        }).expect(401);
        expect(play.getProductPurchase).not.toHaveBeenCalled();
      });

      it('handles a purchase the app never reported, using the stored account reference', async () => {
        const ref = await refFor(tokenA);
        play.getProductPurchase.mockResolvedValue(purchase({ ref }));
        expect((await push(note(1)).expect(200)).body).toEqual({ status: 'processed' });
        expect(await plan()).toMatchObject({ id: 'premium' });
        expect(play.acknowledge).toHaveBeenCalledTimes(1);
      });

      it('finishes a pending payment, then takes Premium away when the purchase is voided', async () => {
        const ref = await refFor(tokenA);
        play.getProductPurchase.mockResolvedValueOnce(purchase({ ref, purchaseState: 2 }));
        await verify(tokenA).expect(200);
        expect((await plan()).id).toBe('free');
        play.getProductPurchase.mockResolvedValueOnce(purchase({ ref }));
        await push(note(1, undefined, Date.now() + 1000)).expect(200); // paid
        expect((await plan()).id).toBe('premium');
        expect((await push(voided(1, undefined, Date.now() + 2000)).expect(200)).body).toEqual({
          status: 'ignored',
        }); // a subscription was voided: not ours
        expect((await plan()).id).toBe('premium');
        await push(voided(2, undefined, Date.now() + 3000)).expect(200); // refunded
        expect((await plan()).id).toBe('free');
        const [row] = await sql`select status from public.subscriptions where user_id = ${USER_A}`;
        expect(row!.status).toBe('refunded');
      });

      it('is idempotent per Pub/Sub message and ignores tests, other products and other apps', async () => {
        const ref = await refFor(tokenA);
        play.getProductPurchase.mockResolvedValue(purchase({ ref }));
        await push(note(1), { messageId: 'm-dup' }).expect(200);
        expect((await push(note(1), { messageId: 'm-dup' }).expect(200)).body).toEqual({
          status: 'duplicate',
        });
        const ignored = async (data: object) =>
          expect((await push(data).expect(200)).body).toEqual({ status: 'ignored' });
        await ignored({ ...base(), testNotification: { version: '1.0' } });
        await ignored({ ...note(1), packageName: 'com.other.app' });
        await ignored({
          ...base(),
          oneTimeProductNotification: { notificationType: 1, purchaseToken: 'x', sku: 'coins' },
        });
        await ignored({
          ...base(),
          subscriptionNotification: { notificationType: 4, purchaseToken: 'x' },
        });
        expect(play.getProductPurchase).toHaveBeenCalledTimes(1);
      });
    });
  });
});
