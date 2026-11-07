import { describe, expect, it } from 'vitest';
import {
  formatPrice,
  getPlan,
  PLANS,
  planRank,
  subscriptionGrantsAccess,
  SUBSCRIPTION_STATUSES,
} from '../src/plans.js';

describe('plans', () => {
  it('only the paid plan unlocks premium content', () => {
    expect(getPlan('free').entitlements.premiumContent).toBe(false);
    expect(getPlan('premium')).toMatchObject({
      paid: true,
      entitlements: { premiumContent: true },
    });
    expect(planRank('premium')).toBeGreaterThan(planRank('free'));
  });

  it('shows the one-time unlock price in US dollars', () => {
    const price = PLANS.premium.displayPrice!;
    expect(formatPrice(price.amount, price.currency)).toBe('$2.99');
  });
});

describe('subscriptionGrantsAccess', () => {
  const now = new Date('2026-11-01T00:00:00Z');
  const future = new Date('2026-12-01T00:00:00Z');
  const past = new Date('2026-10-01T00:00:00Z');

  it.each([
    ['trialing', true],
    ['active', true],
    ['grace_period', true],
    ['on_hold', false],
    ['paused', false],
    ['expired', false],
    ['refunded', false],
  ] as const)('%s → %s', (status, expected) => {
    expect(subscriptionGrantsAccess(status, future, now)).toBe(expected);
  });

  it('keeps a canceled subscription until the paid period ends', () => {
    expect(subscriptionGrantsAccess('canceled', future, now)).toBe(true);
    expect(subscriptionGrantsAccess('canceled', past, now)).toBe(false);
    expect(subscriptionGrantsAccess('canceled', null, now)).toBe(false);
  });

  it('covers every status', () => {
    expect(SUBSCRIPTION_STATUSES).toHaveLength(8);
  });
});
