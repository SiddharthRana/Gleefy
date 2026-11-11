'use client';

import Link from 'next/link';
import { usePremium } from '@/lib/premium';

/** Header: the "★ Premium" upgrade pill for everyone without Premium (and while unknown). */
export function PremiumNavPill() {
  if (usePremium() === true) return null;
  return (
    <Link
      href="/pricing"
      className="press premium-pill ml-1 inline-flex min-h-12 items-center gap-1 whitespace-nowrap rounded-full px-3 sm:px-4"
    >
      <span aria-hidden="true">★</span> Premium
    </Link>
  );
}

/** Header: a small gold "Premium" tag beside the wordmark once the account has Premium. */
export function PremiumTag() {
  if (usePremium() !== true) return null;
  return (
    <span className="premium-tag" title="Gleefy Premium is unlocked">
      Premium
    </span>
  );
}

/** Home page Premium section: the call to action, or a thank-you when it's already unlocked. */
export function PremiumCta() {
  if (usePremium() === true) {
    return (
      <p className="mt-6 flex flex-wrap items-center gap-3 text-lg font-bold">
        <span className="premium-tag premium-tag-lg">★ Premium</span>
        You have Premium. Every category is open.
        <Link href="/play" className="underline">
          Play now
        </Link>
      </p>
    );
  }
  return (
    <Link
      href="/pricing"
      className="press premium-pill mt-6 inline-flex min-h-14 items-center gap-2 rounded-full px-7 text-lg font-bold"
    >
      <span aria-hidden="true">★</span> Unlock Premium
    </Link>
  );
}
