import { describe, expect, it } from 'vitest';
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT, type JWK } from 'jose';
import type { Env } from '../../src/config/env';
import { WebhookSignatureError } from '../../src/billing/billing.types';
import { GooglePlayClient } from '../../src/billing/google-play/play-client';
import { mapPlayProduct } from '../../src/billing/google-play/play-mapper';
import { decodeRtdn, verifyPubSubPush } from '../../src/billing/google-play/rtdn-verifier';
import { ProductCatalog } from '../../src/billing/product-catalog';
import { DodoProvider } from '../../src/billing/providers/dodo.provider';
import { verifyStandardWebhook } from '../../src/billing/providers/signatures';
import { DODO_SECRET, dodoHeaders, dodoPayment, dodoRefund } from './sign';

const catalog = new ProductCatalog({
  DODO_PRODUCT_PREMIUM: 'pdt_unlock',
  GOOGLE_PLAY_PRODUCT_ID: 'mirthmix_premium_unlock',
} as Env);
const dodo = new DodoProvider({ apiKey: 'k', webhookSecret: DODO_SECRET, env: 'test' }, catalog);
const buf = (s: string) => Buffer.from(s);

describe('Standard Webhooks signature (Dodo)', () => {
  const body = dodoPayment({ userId: 'u1' });
  const h = dodoHeaders(body);
  const verify = (headers: Record<string, string>, b = body, secret = DODO_SECRET) =>
    verifyStandardWebhook(
      {
        id: headers['webhook-id'],
        timestamp: headers['webhook-timestamp'],
        signature: headers['webhook-signature'],
      },
      buf(b),
      secret,
    );
  it('accepts a valid signature, including among several', () => {
    expect(() => verify(h)).not.toThrow();
    expect(() =>
      verify({ ...h, 'webhook-signature': `v1,AAAA ${h['webhook-signature']}` }),
    ).not.toThrow();
  });
  it.each([
    ['tampered body', () => verify(h, body + ' ')],
    ['wrong secret', () => verify(h, body, `whsec_${Buffer.from('nope').toString('base64')}`)],
    ['changed id', () => verify({ ...h, 'webhook-id': 'msg_other' })],
    [
      'stale timestamp',
      () => verify(dodoHeaders(body, { ts: Math.floor(Date.now() / 1000) - 3600 })),
    ],
    ['missing headers', () => verify({})],
  ])('rejects %s', (_l, fn) => expect(fn).toThrow(WebhookSignatureError));
});

describe('Dodo event mapping', () => {
  const parse = (body: string) =>
    dodo.parseWebhook({ rawBody: buf(body), headers: dodoHeaders(body, { id: 'msg_1' }) });
  it('maps a succeeded one-time payment to a lifetime unlock', () => {
    const p = parse(dodoPayment({ userId: 'u1', paymentId: 'pay_9' }));
    expect(p.eventId).toBe('msg_1');
    expect(p.subscription).toMatchObject({
      provider: 'dodo',
      providerSubscriptionId: 'pay_9',
      productId: 'pdt_unlock',
      userId: 'u1',
      customerEmail: 'a@x.dev',
      status: 'active',
      interval: 'one_time',
      currentPeriodEnd: null,
      providerCustomerId: 'cus_1',
    });
  });
  it('maps refunds and lost disputes to the payment they undo', () => {
    for (const type of ['refund.succeeded', 'dispute.lost']) {
      const p = parse(dodoRefund({ type, paymentId: 'pay_9' }));
      expect(p.subscription).toBeNull();
      expect(p.refund!.providerSubscriptionId).toBe('pay_9');
    }
  });
  it.each([
    ['a failed payment', dodoPayment({ type: 'payment.failed' }), 'unhandled_event'],
    ['a pending refund', dodoRefund({ type: 'refund.failed' }), 'unhandled_event'],
    ['an opened dispute', dodoRefund({ type: 'dispute.opened' }), 'unhandled_event'],
    ['a subscription renewal', dodoPayment({ subscriptionId: 'sub_1' }), 'subscription_payment'],
    ['an unknown product', dodoPayment({ productId: 'pdt_x' }), 'unknown_product'],
  ])('ignores %s', (_l, body, reason) => {
    const p = parse(body);
    expect(p.subscription).toBeNull();
    expect(p.refund ?? null).toBeNull();
    expect(p.ignoredReason).toBe(reason);
  });
});

describe('Google Play mapping', () => {
  const base = {
    purchaseState: 0,
    purchaseTimeMillis: '1793491200000',
    obfuscatedExternalAccountId: 'ref1',
  };
  const now = { eventAt: new Date() };
  it('maps a purchase to a lifetime unlock with the account ref', () => {
    const m = mapPlayProduct('mirthmix_premium_unlock', 'tok', base, now);
    expect(m).toMatchObject({
      status: 'active',
      interval: 'one_time',
      accountRef: 'ref1',
      productId: 'mirthmix_premium_unlock',
      providerSubscriptionId: 'tok',
      currentPeriodEnd: null,
    });
    expect(m.currentPeriodStart!.getTime()).toBe(1793491200000);
  });
  it.each([
    ['canceled (refunded or voided)', 1, 'refunded'],
    ['pending', 2, 'on_hold'],
  ])('%s → %s', (_l, purchaseState, expected) => {
    expect(mapPlayProduct('p', 'tok', { ...base, purchaseState }, now).status).toBe(expected);
  });
});

describe('GooglePlayClient', () => {
  it('gets an OAuth token with a signed JWT, caches it, reads and acknowledges', async () => {
    const { privateKey } = await generateKeyPair('RS256', { extractable: true });
    const { exportPKCS8 } = await import('jose');
    const pem = await exportPKCS8(privateKey);
    const calls: { url: string; init?: RequestInit }[] = [];
    const fake = (async (url: string, init?: RequestInit) => {
      calls.push({ url: String(url), init });
      if (String(url).includes('oauth2'))
        return new Response(JSON.stringify({ access_token: 'at', expires_in: 3600 }));
      if (String(url).includes(':acknowledge')) return new Response('{}');
      return new Response(JSON.stringify({ purchaseState: 0 }));
    }) as unknown as typeof fetch;
    const client = new GooglePlayClient(
      'com.mirthmix.app',
      { client_email: 'svc@x.iam.gserviceaccount.com', private_key: pem },
      fake,
    );
    expect(
      (await client.getProductPurchase('mirthmix_premium_unlock', 'tok/1')).purchaseState,
    ).toBe(0);
    await client.acknowledge('mirthmix_premium_unlock', 'tok/1');
    expect(calls.filter((c) => c.url.includes('oauth2'))).toHaveLength(1); // cached
    const tokenBody = new URLSearchParams(String(calls[0]!.init!.body));
    expect(tokenBody.get('grant_type')).toBe('urn:ietf:params:oauth:grant-type:jwt-bearer');
    expect(calls[1]!.url).toBe(
      'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.mirthmix.app/purchases/products/mirthmix_premium_unlock/tokens/tok%2F1',
    );
    expect(calls[2]!.url).toBe(`${calls[1]!.url}:acknowledge`);
    expect((calls[1]!.init!.headers as Record<string, string>).Authorization).toBe('Bearer at');
  });
});

describe('RTDN push verification', () => {
  async function setup() {
    const { privateKey, publicKey } = await generateKeyPair('RS256');
    const jwk: JWK = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'RS256' };
    const sign = (claims: Record<string, unknown>, aud = 'https://api.test/rtdn') =>
      new SignJWT(claims)
        .setProtectedHeader({ alg: 'RS256', kid: 'k1' })
        .setIssuer('https://accounts.google.com')
        .setAudience(aud)
        .setIssuedAt()
        .setExpirationTime('5m')
        .sign(privateKey);
    return { keys: createLocalJWKSet({ keys: [jwk] }), sign };
  }
  const opts = {
    audience: 'https://api.test/rtdn',
    serviceAccount: 'push@proj.iam.gserviceaccount.com',
  };

  it('accepts a Google-signed token for our service account', async () => {
    const { keys, sign } = await setup();
    const token = await sign({ email: opts.serviceAccount, email_verified: true });
    expect(await verifyPubSubPush(`Bearer ${token}`, { ...opts, keys })).toBe(true);
  });
  it.each([
    ['other service account', { email: 'evil@x.com', email_verified: true }, undefined],
    [
      'unverified email',
      { email: 'push@proj.iam.gserviceaccount.com', email_verified: false },
      undefined,
    ],
    [
      'wrong audience',
      { email: 'push@proj.iam.gserviceaccount.com', email_verified: true },
      'https://other',
    ],
  ])('rejects %s', async (_l, claims, aud) => {
    const { keys, sign } = await setup();
    expect(await verifyPubSubPush(`Bearer ${await sign(claims, aud)}`, { ...opts, keys })).toBe(
      false,
    );
  });
  it('rejects missing tokens', async () => {
    const { keys } = await setup();
    expect(await verifyPubSubPush(undefined, { ...opts, keys })).toBe(false);
  });
  it('decodes Pub/Sub messages', () => {
    const data = Buffer.from(
      JSON.stringify({
        packageName: 'p',
        subscriptionNotification: { notificationType: 2, purchaseToken: 't' },
      }),
    ).toString('base64');
    expect(decodeRtdn({ message: { data, messageId: 'm1' } })).toMatchObject({
      messageId: 'm1',
      data: { packageName: 'p' },
    });
    expect(decodeRtdn({})).toBeNull();
    expect(decodeRtdn({ message: { data: '!!!', messageId: 'm' } })).toBeNull();
  });
});
