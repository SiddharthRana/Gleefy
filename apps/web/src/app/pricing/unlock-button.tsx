'use client';

import Link from 'next/link';
import { useState } from 'react';
import { apiFetch, ApiError, errorMessage } from '@/lib/api';
import { useBillingConfigStatus } from '@/lib/billing';
import { usePremium } from '@/lib/premium';
import { useSession } from '@/lib/supabase';
import { primary } from '@/lib/ui';

/** Web checkout for the one-time Premium unlock; honest about availability. */
export function UnlockButton({ price }: { price: string }) {
  const { config, failed } = useBillingConfigStatus();
  const session = useSession();
  const premium = usePremium();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<{ text: string; already?: boolean } | null>(null);

  // Already bought: no second checkout, just say so.
  if (premium === true) {
    return (
      <div className="mt-6 flex flex-col items-start gap-3">
        <p className="flex items-center gap-2 text-lg font-bold">
          <span className="premium-tag premium-tag-lg">★ Premium</span> Unlocked on this account
        </p>
        <p className="text-muted">
          Every premium category in every game is yours. Thanks for supporting Gleefy!
        </p>
        <Link href="/play" className={`${primary} inline-flex items-center`}>
          Play now
        </Link>
      </div>
    );
  }
  if (failed) {
    return (
      <p className="mt-6 rounded-card bg-surface-muted p-4">
        We can’t check whether checkout is open right now. Please try again in a little while.
      </p>
    );
  }
  if (!config || session === undefined || (session && premium === null))
    return (
      <p role="status" className="mt-6 text-muted">
        Checking availability…
      </p>
    );
  if (!config.enabled || !config.web.available) {
    return (
      <p className="mt-6 rounded-card bg-surface-muted p-4">
        Premium isn’t on sale on the website yet. Everything free works today.
      </p>
    );
  }
  if (!session) {
    return (
      <Link href="/account?next=pricing" className={`${primary} mt-6 inline-flex items-center`}>
        Sign in to unlock
      </Link>
    );
  }

  async function start() {
    setBusy(true);
    setError(null);
    try {
      const { url } = await apiFetch<{ url: string }>('/v1/billing/checkout', {
        method: 'POST',
        body: {},
      });
      window.location.assign(url);
      return;
    } catch (err) {
      setError({
        text: errorMessage(err),
        already: err instanceof ApiError && err.code === 'already_purchased',
      });
    }
    setBusy(false);
  }

  return (
    <div className="mt-6 flex flex-col gap-3">
      <button type="button" disabled={busy} onClick={start} className={primary}>
        {busy ? 'Opening checkout…' : `Unlock Premium for ${price}`}
      </button>
      {error && (
        <p role="alert" className="font-bold">
          {error.text}{' '}
          {error.already && (
            <Link href="/account" className="underline">
              See your account
            </Link>
          )}
        </p>
      )}
      <p className="text-sm text-muted">
        Secure checkout by our payment partner, who handles taxes and receipts. You can pay in your
        local currency.
      </p>
    </div>
  );
}
