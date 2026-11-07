import type { ProductCatalog } from '../product-catalog';
import {
  header,
  ProviderError,
  type NormalizedSubscription,
  type ParsedWebhook,
  type WebhookRequest,
  type WebPaymentProvider,
} from '../billing.types';
import { verifyStandardWebhook } from './signatures';

/** The parts of Dodo's Payment object we use. */
interface DodoPayment {
  payment_id: string;
  status?: string | null;
  subscription_id?: string | null;
  product_cart?: { product_id: string; quantity?: number }[] | null;
  customer?: { customer_id?: string; email?: string } | null;
  metadata?: { user_id?: string } | null;
  created_at?: string;
}

/** Refund and Dispute objects both name the payment they belong to. */
interface DodoPaymentRef {
  payment_id: string;
  status?: string;
}

/** Events that take a bought unlock away again. */
const REVOKING = new Set(['refund.succeeded', 'dispute.lost']);

/**
 * Dodo Payments (India-based Merchant of Record). Premium is a one-time product: a hosted checkout
 * session, then `payment.succeeded` grants it and `refund.succeeded` or `dispute.lost` takes it
 * away. Webhooks follow the Standard Webhooks spec. Paths and fields were checked against Dodo's API
 * reference on 2026-11-07; still confirm one test-mode purchase end to end before launch
 * (docs/payments-setup.md).
 */
export class DodoProvider implements WebPaymentProvider {
  readonly id = 'dodo' as const;
  private readonly baseUrl: string;

  constructor(
    private readonly cfg: { apiKey?: string; webhookSecret?: string; env: 'test' | 'live' },
    private readonly catalog: ProductCatalog,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {
    this.baseUrl =
      cfg.env === 'live' ? 'https://live.dodopayments.com' : 'https://test.dodopayments.com';
  }

  get configured(): boolean {
    return Boolean(
      this.cfg.apiKey &&
      this.cfg.webhookSecret &&
      this.catalog.entries.some((e) => e.provider === 'dodo'),
    );
  }

  private async call<T>(path: string, body: unknown): Promise<T> {
    const res = await this.fetchImpl(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${this.cfg.apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) throw new ProviderError(`Dodo API ${path} failed`, res.status);
    return (await res.json()) as T;
  }

  async createCheckout(input: {
    userId: string;
    email?: string;
    productId: string;
    returnUrl: string;
  }): Promise<{ url: string }> {
    const res = await this.call<{ checkout_url?: string | null }>('/checkouts', {
      product_cart: [{ product_id: input.productId, quantity: 1 }],
      ...(input.email ? { customer: { email: input.email } } : {}),
      metadata: { user_id: input.userId },
      return_url: input.returnUrl,
    });
    if (!res.checkout_url) throw new ProviderError('Dodo returned no checkout URL');
    return { url: res.checkout_url };
  }

  parseWebhook(req: WebhookRequest, now = new Date()): ParsedWebhook {
    const id = header(req.headers, 'webhook-id');
    verifyStandardWebhook(
      {
        id,
        timestamp: header(req.headers, 'webhook-timestamp'),
        signature: header(req.headers, 'webhook-signature'),
      },
      req.rawBody,
      this.cfg.webhookSecret ?? '',
      now,
    );
    const event = JSON.parse(req.rawBody.toString('utf8')) as {
      type: string;
      timestamp: string;
      data: unknown;
    };
    const ignore = (reason: string): ParsedWebhook => ({
      eventId: id!,
      eventType: event.type,
      subscription: null,
      ignoredReason: reason,
    });
    const eventAt = new Date(event.timestamp);

    if (REVOKING.has(event.type)) {
      const ref = event.data as DodoPaymentRef;
      if (!ref.payment_id) return ignore('no_payment');
      return {
        eventId: id!,
        eventType: event.type,
        subscription: null,
        refund: { providerSubscriptionId: ref.payment_id, eventAt },
      };
    }
    if (event.type !== 'payment.succeeded') return ignore('unhandled_event');

    const d = event.data as DodoPayment;
    // Renewals of a subscription also send payment.succeeded; Premium has no subscription.
    if (d.subscription_id) return ignore('subscription_payment');
    const entry = (d.product_cart ?? [])
      .map((item) => this.catalog.find('dodo', item.product_id))
      .find((e) => e !== undefined);
    if (!entry) return ignore('unknown_product');
    const sub: NormalizedSubscription = {
      provider: 'dodo',
      providerSubscriptionId: d.payment_id,
      providerCustomerId: d.customer?.customer_id ?? null,
      productId: entry.productId,
      planId: entry.planId,
      interval: 'one_time',
      status: 'active',
      currentPeriodStart: d.created_at ? new Date(d.created_at) : eventAt,
      currentPeriodEnd: null,
      cancelAtPeriodEnd: false,
      userId: d.metadata?.user_id ?? null,
      customerEmail: d.customer?.email ?? null,
      eventAt,
    };
    return { eventId: id!, eventType: event.type, subscription: sub };
  }
}
