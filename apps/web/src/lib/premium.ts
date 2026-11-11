'use client';

import { useEffect, useSyncExternalStore } from 'react';
import { apiFetch } from './api';
import type { Account } from './billing';
import { useSession } from './supabase';

// What the API last said about each signed-in user's Premium, shared by every component that asks
// (header badge and avatar, unlock button, game player…). One /v1/me request per user per page
// load; the Account page reports fresher answers (for example right after checkout) through
// notePremium, so the header updates without a reload.
const known = new Map<string, boolean>();
const pending = new Map<string, Promise<void>>();
const listeners = new Set<() => void>();

function emit() {
  for (const l of listeners) l();
}

/** Records what the API just said about this user's Premium. */
export function notePremium(userId: string, premium: boolean) {
  if (known.get(userId) === premium) return;
  known.set(userId, premium);
  emit();
}

function load(userId: string) {
  if (known.has(userId) || pending.has(userId)) return;
  pending.set(
    userId,
    apiFetch<Account>('/v1/me')
      .then(
        (a) => notePremium(userId, a.entitlements.premiumContent),
        // Offline or failed: treat as free for now; a later page load asks again.
        () => notePremium(userId, false),
      )
      .finally(() => pending.delete(userId)),
  );
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

/**
 * Whether the signed-in visitor has Premium, as the API says (never a local flag).
 * `null` while unknown; `false` when signed out, offline or on the free plan.
 */
export function usePremium(): boolean | null {
  const session = useSession();
  const userId = session?.user.id;
  const value = useSyncExternalStore(
    subscribe,
    () => (userId ? (known.get(userId) ?? null) : null),
    () => null,
  );
  useEffect(() => {
    if (userId) load(userId);
  }, [userId]);
  if (session === undefined) return null;
  if (!session) return false;
  return value;
}
