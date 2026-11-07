'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from './api';

export interface BillingConfig {
  enabled: boolean;
  web: { provider: 'none' | 'dodo'; available: boolean };
  googlePlay: { available: boolean; packageName: string; productId: string };
}

/** A Premium unlock that gives access, or one whose payment is still pending (`on_hold`). */
export interface AccountPurchase {
  provider: 'google_play' | 'dodo';
  planId: string;
  status: string;
  purchasedAt: string | null;
}

export interface Account {
  id: string;
  email?: string;
  plan: { id: string; name: string; paid: boolean; source: 'default' | 'subscription' };
  entitlements: { premiumContent: boolean };
  /** Premium is a one-time unlock: it doesn't run out. */
  lifetime: boolean;
  validUntil: string | null;
  purchases: AccountPurchase[];
}

/**
 * Whether Premium can be bought on the web. `config` is null while loading and when the check
 * failed; `failed` is set when the API couldn't be reached or answered with an error, and the check
 * gives up after 10 seconds so the page never waits forever (same as Weblume).
 */
export function useBillingConfigStatus(): { config: BillingConfig | null; failed: boolean } {
  const [state, setState] = useState<{ config: BillingConfig | null; failed: boolean }>({
    config: null,
    failed: false,
  });
  useEffect(() => {
    let active = true;
    apiFetch<BillingConfig>('/v1/billing/config', { timeoutMs: 10_000 }).then(
      (config) => active && setState({ config, failed: false }),
      () => active && setState({ config: null, failed: true }),
    );
    return () => {
      active = false;
    };
  }, []);
  return state;
}

export const providerName: Record<AccountPurchase['provider'], string> = {
  google_play: 'Google Play',
  dodo: 'the website',
};
