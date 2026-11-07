import type { SubscriptionStatus } from '@gleefy/plans';
import type { NormalizedSubscription } from '../billing.types';
import type { ProductPurchase } from './play-client';

/** RTDN OneTimeProductNotification types. */
export const PLAY_ONE_TIME_NOTIFICATION = { PURCHASED: 1, CANCELED: 2 } as const;

/** VoidedPurchaseNotification productType for one-time products. */
export const PLAY_VOIDED_ONE_TIME = 2;

/**
 * Maps a Play ProductPurchase (one-time product) to our model. The API is the source of truth; RTDN
 * only says "something changed". A purchased unlock is active with no end; a canceled one
 * (refunded or voided) is refunded; a pending one (cash or bank payment not finished) grants
 * nothing yet.
 */
export function mapPlayProduct(
  productId: string,
  purchaseToken: string,
  p: ProductPurchase,
  opts: { eventAt: Date },
): NormalizedSubscription & { planId: 'premium' } {
  let status: SubscriptionStatus;
  switch (p.purchaseState) {
    case 0:
      status = 'active';
      break;
    case 1:
      status = 'refunded';
      break;
    default:
      status = 'on_hold'; // 2 = pending: no access until Play says it's paid
  }
  return {
    provider: 'google_play',
    providerSubscriptionId: purchaseToken,
    productId,
    planId: 'premium',
    interval: 'one_time',
    status,
    currentPeriodStart: p.purchaseTimeMillis ? new Date(Number(p.purchaseTimeMillis)) : null,
    currentPeriodEnd: null,
    cancelAtPeriodEnd: false,
    accountRef: p.obfuscatedExternalAccountId ?? null,
    eventAt: opts.eventAt,
  };
}
