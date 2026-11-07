'use client';

import Link from 'next/link';
import { authConfigured, useSession } from '@/lib/supabase';

/** "Sign in" (or "Account" once signed in) in the header; an icon on narrow screens. */
export function AccountLink({ className }: { className: string }) {
  const session = useSession();
  if (!authConfigured) return null;
  const label = session ? 'Account' : 'Sign in';
  return (
    <Link href="/account" className={className} aria-label={label}>
      <svg
        aria-hidden="true"
        viewBox="0 0 24 24"
        className="size-6 sm:hidden"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.25"
        strokeLinecap="round"
      >
        <circle cx="12" cy="8" r="4" />
        <path d="M4.5 20a7.5 7.5 0 0 1 15 0" />
      </svg>
      <span className="hidden sm:inline">{label}</span>
    </Link>
  );
}
