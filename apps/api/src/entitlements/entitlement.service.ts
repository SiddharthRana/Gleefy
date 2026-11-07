import { HttpStatus, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import {
  getPlan,
  planRank,
  subscriptionGrantsAccess,
  type Entitlements,
  type PlanConfig,
} from '@gleefy/plans';
import { ApiError } from '../common/api-error';
import { FeatureFlags } from '../common/feature-flags.service';
import { Database } from '../database/database.module';
import { profiles, subscriptions } from '../database/schema';

export interface ResolvedPlan {
  plan: PlanConfig;
  entitlements: Entitlements;
  /** Where the plan came from: a verified purchase, or the free default. */
  source: 'default' | 'subscription';
  /** True when the plan comes from a one-time unlock: it never runs out, only a refund ends it. */
  lifetime: boolean;
  /**
   * End of the paid period of a granting subscription, or null for a one-time unlock and for free.
   * The app caches a timed entitlement until this moment (plus a short offline grace window).
   */
  validUntil: Date | null;
}

/**
 * The single place that decides what a user may do. Plans come only from server-side subscription
 * records written by verified store/provider events, never from clients.
 */
@Injectable()
export class EntitlementService {
  constructor(
    private readonly database: Database,
    private readonly flags: FeatureFlags,
  ) {}

  /** Resolves the user's plan. Throws 403 account_deleted for accounts being deleted. */
  async forUser(userId: string, now = new Date()): Promise<ResolvedPlan> {
    const db = this.database.db;
    const [profile] = await db
      .select({ deletionRequestedAt: profiles.deletionRequestedAt })
      .from(profiles)
      .where(eq(profiles.id, userId))
      .limit(1);
    if (!profile || profile.deletionRequestedAt) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'account_deleted', 'This account has been deleted.');
    }

    const free = getPlan('free');
    const fallback: ResolvedPlan = {
      plan: free,
      entitlements: free.entitlements,
      source: 'default',
      lifetime: false,
      validUntil: null,
    };
    // With billing switched off, everyone gets free-plan entitlements.
    if (!(await this.flags.isEnabled('billing'))) return fallback;

    const subs = await db.select().from(subscriptions).where(eq(subscriptions.userId, userId));
    let best: ResolvedPlan = fallback;
    for (const s of subs) {
      if (!subscriptionGrantsAccess(s.status, s.currentPeriodEnd, now)) continue;
      const plan = getPlan(s.planId);
      const lifetime = s.billingInterval === 'one_time';
      const end = (r: { lifetime: boolean; validUntil: Date | null }) =>
        r.lifetime ? Infinity : (r.validUntil?.getTime() ?? 0);
      const outranks = planRank(plan.id) > planRank(best.plan.id);
      const lastsLonger =
        plan.id === best.plan.id && end({ lifetime, validUntil: s.currentPeriodEnd }) > end(best);
      if (!plan.paid || !(outranks || lastsLonger)) continue;
      best = {
        plan,
        entitlements: plan.entitlements,
        source: 'subscription',
        lifetime,
        validUntil: lifetime ? null : s.currentPeriodEnd,
      };
    }
    return best;
  }
}
