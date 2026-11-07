import { createHmac, randomBytes } from 'node:crypto';
import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { subscriptionGrantsAccess } from '@gleefy/plans';
import type { JWTVerifyGetKey } from 'jose';
import type { AuthUser } from '../auth/auth.types';
import { FeatureFlags } from '../common/feature-flags.service';
import { ENV, type Env } from '../config/env';
import { Database } from '../database/database.module';
import { profiles, subscriptions, type PaymentProviderId } from '../database/schema';
import { EntitlementService } from '../entitlements/entitlement.service';
import { ApiError } from '../common/api-error';
import {
  ProviderError,
  WEB_PAYMENT_PROVIDER,
  WebhookSignatureError,
  type WebhookRequest,
  type WebPaymentProvider,
} from './billing.types';
import { PLAY_API, type PlayApi } from './google-play/play-client';
import { mapPlayProduct, PLAY_VOIDED_ONE_TIME } from './google-play/play-mapper';
import { decodeRtdn, RTDN_KEY_RESOLVER, verifyPubSubPush } from './google-play/rtdn-verifier';
import { ProductCatalog } from './product-catalog';
import { SubscriptionStore } from './subscription-store';
import { WebhookLedger } from './webhook-ledger';

export interface BillingConfigDto {
  enabled: boolean;
  web: { provider: 'none' | 'dodo'; available: boolean };
  googlePlay: { available: boolean; packageName: string; productId: string };
}

@Injectable()
export class BillingService {
  private readonly logger = new Logger(BillingService.name);
  private readonly accountSecret: string;

  constructor(
    private readonly database: Database,
    private readonly flags: FeatureFlags,
    private readonly catalog: ProductCatalog,
    private readonly store: SubscriptionStore,
    private readonly ledger: WebhookLedger,
    private readonly entitlements: EntitlementService,
    @Inject(WEB_PAYMENT_PROVIDER) private readonly web: WebPaymentProvider | null,
    @Inject(PLAY_API) private readonly play: PlayApi,
    @Inject(RTDN_KEY_RESOLVER) private readonly rtdnKeys: JWTVerifyGetKey,
    @Inject(ENV) private readonly env: Env,
  ) {
    // Development fallback only; production config requires BILLING_ACCOUNT_SECRET when Play is used.
    this.accountSecret = env.BILLING_ACCOUNT_SECRET ?? randomBytes(32).toString('hex');
  }

  async config(): Promise<BillingConfigDto> {
    const enabled = await this.flags.isEnabled('billing');
    const webProduct = this.web ? this.catalog.forPlan(this.web.id, 'premium') : undefined;
    return {
      enabled,
      web: {
        provider: this.web?.id ?? 'none',
        available: enabled && Boolean(this.web?.configured) && Boolean(webProduct),
      },
      googlePlay: {
        available: enabled && this.play.configured,
        packageName: this.env.GOOGLE_PLAY_PACKAGE_NAME,
        productId: this.env.GOOGLE_PLAY_PRODUCT_ID,
      },
    };
  }

  /** Purchases that currently grant access, across all channels. */
  private async activeSubscriptions(userId: string) {
    const rows = await this.database.db
      .select()
      .from(subscriptions)
      .where(eq(subscriptions.userId, userId));
    return rows.filter((s) => subscriptionGrantsAccess(s.status, s.currentPeriodEnd));
  }

  private async assertBillingEnabled(): Promise<void> {
    if (!(await this.flags.isEnabled('billing'))) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'billing_disabled', 'Premium isn’t available yet.');
    }
  }

  async checkout(user: AuthUser): Promise<{ url: string }> {
    await this.assertBillingEnabled();
    await this.entitlements.forUser(user.id); // rejects deleted accounts
    if (!this.web?.configured) {
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'checkout_unavailable',
        'Online checkout isn’t available right now.',
      );
    }
    const active = await this.activeSubscriptions(user.id);
    if (active.length) {
      throw new ApiError(HttpStatus.CONFLICT, 'already_purchased', 'You already have Premium.', {
        provider: active[0]!.provider,
      });
    }
    const entry = this.catalog.forPlan(this.web.id, 'premium');
    if (!entry)
      throw new ApiError(HttpStatus.BAD_REQUEST, 'plan_unavailable', 'That plan isn’t available.');
    try {
      return await this.web.createCheckout({
        userId: user.id,
        email: user.email,
        productId: entry.productId,
        returnUrl: this.env.BILLING_RETURN_URL,
      });
    } catch (err) {
      this.logger.error(
        `Checkout creation failed: ${err instanceof ProviderError ? `${err.message} (${err.status})` : 'unknown'}`,
      );
      throw new ApiError(
        HttpStatus.BAD_GATEWAY,
        'checkout_failed',
        'We couldn’t start checkout. Please try again.',
      );
    }
  }

  /** Verified web provider webhook → purchase state. Idempotent; out-of-order safe. */
  async handleWebhook(providerId: string, req: WebhookRequest): Promise<{ status: string }> {
    if (!this.web || this.web.id !== providerId || !this.web.configured) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'not_found', 'Not found.');
    }
    let parsed;
    try {
      parsed = this.web.parseWebhook(req);
    } catch (err) {
      if (err instanceof WebhookSignatureError || err instanceof SyntaxError) {
        throw new ApiError(HttpStatus.UNAUTHORIZED, 'invalid_signature', 'Invalid signature.');
      }
      throw err;
    }
    return this.process(this.web.id, parsed.eventId, parsed.eventType, req.rawBody, async () => {
      if (parsed.refund) {
        const r = await this.store.markRefunded(
          this.web!.id,
          parsed.refund.providerSubscriptionId,
          parsed.refund.eventAt,
        );
        return r.applied ? { status: 'processed' } : { status: 'ignored', reason: r.reason };
      }
      if (!parsed.subscription) return { status: 'ignored', reason: parsed.ignoredReason };
      const r = await this.store.apply(parsed.subscription);
      return r.applied ? { status: 'processed' } : { status: 'ignored', reason: r.reason };
    });
  }

  private async process(
    provider: PaymentProviderId,
    eventId: string,
    eventType: string,
    rawBody: Buffer,
    work: () => Promise<{ status: 'processed' | 'ignored'; reason?: string }>,
  ): Promise<{ status: string }> {
    let payload: unknown;
    try {
      payload = JSON.parse(rawBody.toString('utf8'));
    } catch {
      payload = null;
    }
    if (!(await this.ledger.begin(provider, eventId, eventType, payload)))
      return { status: 'duplicate' };
    try {
      const result = await work();
      await this.ledger.finish(provider, eventId, result.status, result.reason);
      return { status: result.status };
    } catch (err) {
      await this.ledger.finish(
        provider,
        eventId,
        'failed',
        err instanceof Error ? err.message : 'unknown',
      );
      throw err; // 5xx → provider retries
    }
  }

  /** Opaque id passed to Google Play as obfuscatedAccountId; stored so notifications map to the user. */
  async playAccountRef(user: AuthUser): Promise<string> {
    await this.entitlements.forUser(user.id);
    const ref = createHmac('sha256', this.accountSecret).update(user.id).digest('hex');
    await this.database.db
      .update(profiles)
      .set({ billingAccountRef: ref })
      .where(eq(profiles.id, user.id));
    return ref;
  }

  async verifyPlayPurchase(
    user: AuthUser,
    purchaseToken: string,
  ): Promise<{ planId: string; status: string; duplicatePurchase: boolean }> {
    await this.assertBillingEnabled();
    if (!this.play.configured) {
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'play_unavailable',
        'Google Play purchases can’t be verified right now.',
      );
    }
    const ref = await this.playAccountRef(user);
    const productId = this.env.GOOGLE_PLAY_PRODUCT_ID;
    let purchase;
    try {
      // Asking for our product id means a token for any other product is simply "not found".
      purchase = await this.play.getProductPurchase(productId, purchaseToken);
    } catch (err) {
      const status = err instanceof ProviderError ? err.status : undefined;
      if (status === 400 || status === 404 || status === 410) {
        throw new ApiError(
          HttpStatus.BAD_REQUEST,
          'invalid_purchase',
          'That purchase couldn’t be found.',
        );
      }
      throw new ApiError(
        HttpStatus.BAD_GATEWAY,
        'play_unreachable',
        'We couldn’t reach Google Play. Please try again.',
      );
    }
    const mapped = mapPlayProduct(productId, purchaseToken, purchase, { eventAt: new Date() });
    // A token bought under another account (or without our account id) can't be claimed.
    if (mapped.accountRef !== ref) {
      throw new ApiError(
        HttpStatus.FORBIDDEN,
        'purchase_account_mismatch',
        'This purchase belongs to a different account.',
      );
    }
    const otherActive = (await this.activeSubscriptions(user.id)).filter(
      (s) => s.provider !== 'google_play',
    );
    await this.store.apply({ ...mapped, userId: user.id });
    await this.acknowledgeIfNeeded(productId, purchaseToken, purchase);
    return {
      planId: mapped.planId,
      status: mapped.status,
      duplicatePurchase: otherActive.length > 0,
    };
  }

  /** Play refunds unacknowledged purchases after three days, so every paid one is acknowledged. */
  private async acknowledgeIfNeeded(
    productId: string,
    purchaseToken: string,
    purchase: { purchaseState?: number; acknowledgementState?: number },
  ): Promise<void> {
    if (purchase.purchaseState === 0 && purchase.acknowledgementState !== 1) {
      await this.play.acknowledge(productId, purchaseToken);
    }
  }

  /** Real-time Developer Notification via Pub/Sub push. The API read is the source of truth. */
  async handleRtdn(authorization: string | undefined, body: unknown): Promise<{ status: string }> {
    const audience = this.env.GOOGLE_PLAY_RTDN_AUDIENCE;
    const serviceAccount = this.env.GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT;
    if (!audience || !serviceAccount || !this.play.configured) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'not_found', 'Not found.');
    }
    if (
      !(await verifyPubSubPush(authorization, { keys: this.rtdnKeys, audience, serviceAccount }))
    ) {
      throw new ApiError(HttpStatus.UNAUTHORIZED, 'invalid_token', 'Invalid push token.');
    }
    const decoded = decodeRtdn(body as { message?: { data?: string; messageId?: string } });
    if (!decoded) throw new ApiError(HttpStatus.BAD_REQUEST, 'invalid_message', 'Invalid message.');
    const { messageId, data } = decoded;
    const oneTime = data.oneTimeProductNotification;
    const voided = data.voidedPurchaseNotification;
    const type = oneTime
      ? `one_time.${oneTime.notificationType}`
      : voided
        ? 'voided'
        : data.subscriptionNotification
          ? `subscription.${data.subscriptionNotification.notificationType}`
          : data.testNotification
            ? 'test'
            : 'other';
    return this.process(
      'google_play',
      messageId,
      type,
      Buffer.from(JSON.stringify(data)),
      async () => {
        if (data.packageName !== this.env.GOOGLE_PLAY_PACKAGE_NAME)
          return { status: 'ignored', reason: 'other_package' };
        const eventAt = data.eventTimeMillis ? new Date(Number(data.eventTimeMillis)) : new Date();
        if (voided?.purchaseToken) {
          if (voided.productType !== PLAY_VOIDED_ONE_TIME)
            return { status: 'ignored', reason: 'other_product' };
          const r = await this.store.markRefunded('google_play', voided.purchaseToken, eventAt);
          return r.applied ? { status: 'processed' } : { status: 'ignored', reason: r.reason };
        }
        if (!oneTime?.purchaseToken)
          return { status: 'ignored', reason: data.testNotification ? 'test' : 'unhandled' };
        const productId = this.env.GOOGLE_PLAY_PRODUCT_ID;
        if (oneTime.sku !== productId) return { status: 'ignored', reason: 'other_product' };
        const purchase = await this.play.getProductPurchase(productId, oneTime.purchaseToken);
        const mapped = mapPlayProduct(productId, oneTime.purchaseToken, purchase, { eventAt });
        const r = await this.store.apply(mapped);
        if (!r.applied) return { status: 'ignored', reason: r.reason };
        // Acknowledge here too, in case the app never reported the purchase (avoids Play's 3-day auto-refund).
        await this.acknowledgeIfNeeded(productId, oneTime.purchaseToken, purchase);
        return { status: 'processed' };
      },
    );
  }
}
