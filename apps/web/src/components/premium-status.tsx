'use client';

import Link from 'next/link';
import { usePremium } from '@/lib/premium';

// While Premium is still unknown (the first paint, before the API answers), both versions are in
// the page and CSS shows one by the device's hint on <html data-premium> (see lib/premium.ts):
// `if-premium` shows only with the hint, `if-free` only without it.
const unknownFree = (premium: boolean | null) => (premium === null ? ' if-free' : '');
const unknownPremium = (premium: boolean | null) => (premium === null ? ' if-premium' : '');

/** Header: the "★ Premium" upgrade pill for everyone without Premium. */
export function PremiumNavPill() {
  const premium = usePremium();
  if (premium === true) return null;
  return (
    <Link
      href="/pricing"
      aria-label="Premium"
      className={`press${unknownFree(premium)} premium-pill ml-1 inline-flex min-h-12 min-w-12 items-center justify-center gap-1 whitespace-nowrap rounded-full px-3 sm:px-4`}
    >
      <span aria-hidden="true">★</span>
      {/* Very narrow phones show just the star, so the level chip and avatar still fit. */}
      <span aria-hidden="true" className="hidden min-[420px]:inline">
        Premium
      </span>
    </Link>
  );
}

/** Header: a small gold "Premium" tag beside the wordmark once the account has Premium. */
export function PremiumTag() {
  const premium = usePremium();
  if (premium === false) return null;
  return (
    <span className={`premium-tag${unknownPremium(premium)}`} title="Gleefy Premium is unlocked">
      Premium
    </span>
  );
}

/** Home page Premium section: the call to action, or a thank-you when it's already unlocked. */
export function PremiumCta() {
  const premium = usePremium();
  const owned = (
    <p
      className={`mt-6 flex flex-wrap items-center gap-3 text-lg font-bold${unknownPremium(premium)}`}
    >
      <span className="premium-tag premium-tag-lg">★ Premium</span>
      You have Premium. Every category is open.
      <Link href="/play" className="underline">
        Play now
      </Link>
    </p>
  );
  const offer = (
    <Link
      href="/pricing"
      className={`press premium-pill mt-6 inline-flex min-h-14 items-center gap-2 rounded-full px-7 text-lg font-bold${unknownFree(premium)}`}
    >
      <span aria-hidden="true">★</span> Unlock Premium
    </Link>
  );
  if (premium === true) return owned;
  if (premium === false) return offer;
  return (
    <>
      {owned}
      {offer}
    </>
  );
}

/**
 * Shows its children only to visitors without Premium (signed out or free). While Premium is
 * unknown they stay in the page and CSS follows the device's hint, so nothing flashes on reload.
 */
export function ForFree({ children }: { children: React.ReactNode }) {
  const premium = usePremium();
  if (premium === true) return null;
  return premium === null ? <span className="contents if-free">{children}</span> : <>{children}</>;
}

/** Shows its children only to accounts with Premium (the opposite of ForFree). */
export function ForPremium({ children }: { children: React.ReactNode }) {
  const premium = usePremium();
  if (premium === false) return null;
  return premium === null ? (
    <span className="contents if-premium">{children}</span>
  ) : (
    <>{children}</>
  );
}
