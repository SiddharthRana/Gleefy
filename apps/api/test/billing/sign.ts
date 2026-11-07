import { createHmac } from 'node:crypto';

export const DODO_SECRET = `whsec_${Buffer.from('dodo-test-signing-key-0123456789').toString('base64')}`;

export function dodoHeaders(
  body: string,
  opts: { id?: string; secret?: string; ts?: number } = {},
) {
  const id = opts.id ?? `msg_${Math.random().toString(36).slice(2)}`;
  const ts = opts.ts ?? Math.floor(Date.now() / 1000);
  const key = Buffer.from((opts.secret ?? DODO_SECRET).replace(/^whsec_/, ''), 'base64');
  const sig = createHmac('sha256', key).update(`${id}.${ts}.${body}`).digest('base64');
  return { 'webhook-id': id, 'webhook-timestamp': String(ts), 'webhook-signature': `v1,${sig}` };
}

/** A Dodo `payment.*` event for a one-time checkout. */
export function dodoPayment(over: {
  type?: string;
  paymentId?: string;
  userId?: string | null;
  email?: string;
  productId?: string;
  subscriptionId?: string | null;
  timestamp?: string;
}) {
  const timestamp = over.timestamp ?? new Date().toISOString();
  return JSON.stringify({
    business_id: 'bus_1',
    type: over.type ?? 'payment.succeeded',
    timestamp,
    data: {
      payload_type: 'Payment',
      payment_id: over.paymentId ?? 'pay_1',
      status: 'succeeded',
      subscription_id: over.subscriptionId ?? null,
      product_cart: [{ product_id: over.productId ?? 'pdt_unlock', quantity: 1 }],
      customer: { customer_id: 'cus_1', email: over.email ?? 'a@x.dev', name: 'A' },
      metadata: over.userId ? { user_id: over.userId } : {},
      total_amount: 299,
      currency: 'USD',
      created_at: timestamp,
    },
  });
}

/** A Dodo `refund.*` or `dispute.*` event naming the payment it belongs to. */
export function dodoRefund(over: { type?: string; paymentId?: string; timestamp?: string }) {
  return JSON.stringify({
    business_id: 'bus_1',
    type: over.type ?? 'refund.succeeded',
    timestamp: over.timestamp ?? new Date().toISOString(),
    data: {
      payload_type: over.type?.startsWith('dispute.') ? 'Dispute' : 'Refund',
      refund_id: 'ref_1',
      payment_id: over.paymentId ?? 'pay_1',
      status: 'succeeded',
      created_at: new Date().toISOString(),
    },
  });
}
