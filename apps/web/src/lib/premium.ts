'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from './api';
import type { Account } from './billing';
import { useSession } from './supabase';

/**
 * Whether the signed-in visitor has Premium, as the API says (never a local flag).
 * `null` while unknown; `false` when signed out, offline or on the free plan.
 */
export function usePremium(): boolean | null {
  const session = useSession();
  const [premium, setPremium] = useState<boolean | null>(null);
  const userId = session?.user.id;
  useEffect(() => {
    if (!userId) return;
    let live = true;
    apiFetch<Account>('/v1/me').then(
      (a) => live && setPremium(a.entitlements.premiumContent),
      () => live && setPremium(false),
    );
    return () => {
      live = false;
    };
  }, [userId]);
  if (session === undefined) return null;
  if (!session) return false;
  return premium;
}
