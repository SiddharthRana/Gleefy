'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from './api';
import type { Account } from './billing';
import { useSession } from './supabase';

// One /v1/me request per signed-in user per page load, shared by every component that asks
// (header badge, unlock button, game player…). A failed check is not cached, so it retries.
const checks = new Map<string, Promise<boolean>>();

function checkPremium(userId: string): Promise<boolean> {
  let check = checks.get(userId);
  if (!check) {
    check = apiFetch<Account>('/v1/me').then(
      (a) => a.entitlements.premiumContent,
      (err: unknown) => {
        checks.delete(userId);
        throw err;
      },
    );
    checks.set(userId, check);
  }
  return check;
}

/**
 * Whether the signed-in visitor has Premium, as the API says (never a local flag).
 * `null` while unknown; `false` when signed out, offline or on the free plan.
 */
export function usePremium(): boolean | null {
  const session = useSession();
  const [premium, setPremium] = useState<{ userId: string; value: boolean } | null>(null);
  const userId = session?.user.id;
  useEffect(() => {
    if (!userId) return;
    let live = true;
    checkPremium(userId).then(
      (value) => live && setPremium({ userId, value }),
      () => live && setPremium({ userId, value: false }),
    );
    return () => {
      live = false;
    };
  }, [userId]);
  if (session === undefined) return null;
  if (!session) return false;
  return premium && premium.userId === userId ? premium.value : null;
}
