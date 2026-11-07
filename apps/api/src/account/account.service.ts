import { Inject, Injectable, Logger } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { subscriptionGrantsAccess, type Entitlements } from '@mirthmix/plans';
import type { AuthUser } from '../auth/auth.types';
import { Database } from '../database/database.module';
import { profiles, subscriptions } from '../database/schema';
import { EntitlementService } from '../entitlements/entitlement.service';
import { AUTH_ADMIN, type AuthAdmin } from './auth-admin';

export interface AccountDto {
  id: string;
  email?: string;
  createdAt: string;
  plan: { id: string; name: string; paid: boolean; source: 'default' | 'subscription' };
  entitlements: Entitlements;
  /** True when Premium is a one-time unlock: keep it until the server says otherwise. */
  lifetime: boolean;
  /** When a timed entitlement must be re-checked, or null for a one-time unlock and for free. */
  validUntil: string | null;
  /** Purchases that give access, or are still waiting for payment; refunded and failed ones are left out. */
  purchases: {
    provider: string;
    planId: string;
    status: string;
    purchasedAt: string | null;
  }[];
}

export type DeletionResult = { status: 'deleted' } | { status: 'pending' };

/** Accounts exist only for purchasers (BUILD_PROMPT §11); guests never need one. */
@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(
    private readonly database: Database,
    private readonly entitlements: EntitlementService,
    @Inject(AUTH_ADMIN) private readonly authAdmin: AuthAdmin,
  ) {}

  async get(user: AuthUser): Promise<AccountDto> {
    const resolved = await this.entitlements.forUser(user.id);
    const db = this.database.db;
    const [[profile], subs] = await Promise.all([
      db.select().from(profiles).where(eq(profiles.id, user.id)).limit(1),
      db.select().from(subscriptions).where(eq(subscriptions.userId, user.id)),
    ]);
    return {
      id: user.id,
      email: user.email,
      createdAt: (profile?.createdAt ?? new Date()).toISOString(),
      plan: {
        id: resolved.plan.id,
        name: resolved.plan.name,
        paid: resolved.plan.paid,
        source: resolved.source,
      },
      entitlements: resolved.entitlements,
      lifetime: resolved.lifetime,
      validUntil: resolved.validUntil?.toISOString() ?? null,
      purchases: subs
        .filter(
          (s) => subscriptionGrantsAccess(s.status, s.currentPeriodEnd) || s.status === 'on_hold',
        )
        .map((s) => ({
          provider: s.provider,
          planId: s.planId,
          status: s.status,
          purchasedAt: (s.currentPeriodStart ?? s.createdAt).toISOString(),
        })),
    };
  }

  /**
   * Deletes the account (required by Google Play for apps that let people create one). The profile
   * is marked immediately, so the account stops working; the Supabase Auth user (and, by cascade,
   * profile and subscription records) is then deleted. If that can't run now, maintenance retries.
   * A bought unlock is not refunded by this; the person asks Google Play or us for a refund.
   */
  async delete(user: AuthUser): Promise<DeletionResult> {
    await this.entitlements.forUser(user.id); // 403 if already deleted
    await this.database.db
      .update(profiles)
      .set({ deletionRequestedAt: new Date(), billingAccountRef: null })
      .where(eq(profiles.id, user.id));
    return (await this.deleteAuthUser(user.id)) ? { status: 'deleted' } : { status: 'pending' };
  }

  /** Returns true when the auth user is gone. */
  async deleteAuthUser(userId: string): Promise<boolean> {
    if (!this.authAdmin.configured) return false;
    try {
      await this.authAdmin.deleteUser(userId);
      return true;
    } catch (err) {
      this.logger.warn(
        `Auth user deletion deferred: ${err instanceof Error ? err.message : 'unknown error'}`,
      );
      return false;
    }
  }
}
