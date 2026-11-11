'use client';

import Link from 'next/link';
import { usePremium } from '@/lib/premium';
import { useSession } from '@/lib/supabase';

/** First letter of the account's name (Google) or email, for the avatar. */
export function initialOf(user: { email?: string; user_metadata?: Record<string, unknown> }) {
  const name = user.user_metadata?.full_name ?? user.user_metadata?.name;
  const source = (typeof name === 'string' && name.trim()) || user.email || '?';
  return Array.from(source.trim())[0]!.toUpperCase();
}

/**
 * Header: a round avatar with the account's initial, linking to Account. Only when signed in, so
 * free players are never nudged to make an account. A gold ring marks Premium.
 */
export function AccountButton() {
  const session = useSession();
  const premium = usePremium() === true;
  if (!session) return null;
  return (
    <Link
      href="/account"
      aria-label={premium ? 'Your account (Premium)' : 'Your account'}
      title="Your account"
      className={`press avatar-button ${premium ? 'avatar-premium' : ''}`}
    >
      <span aria-hidden="true">{initialOf(session.user)}</span>
    </Link>
  );
}
