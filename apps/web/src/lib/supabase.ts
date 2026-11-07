import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { useEffect, useState } from 'react';

const URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
const KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? '';

/** True when purchaser accounts are configured for this deployment. Playing never needs one. */
export const authConfigured = Boolean(URL && KEY);

/** "Continue with Google" is offered when the Google provider is switched on in Supabase. */
export const googleSignInEnabled =
  authConfigured && process.env.NEXT_PUBLIC_AUTH_GOOGLE_ENABLED === 'true';

let client: SupabaseClient | null = null;

/** Browser Supabase client. Null when accounts aren't configured. */
export function getSupabase(): SupabaseClient | null {
  if (!authConfigured || typeof window === 'undefined') return null;
  client ??= createClient(URL, KEY, {
    // PKCE: Google sends people back to /auth/callback?code=…, which supabase-js exchanges.
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: 'pkce',
    },
  });
  return client;
}

export async function currentAccessToken(): Promise<string | null> {
  const sb = getSupabase();
  if (!sb) return null;
  const { data } = await sb.auth.getSession();
  return data.session?.access_token ?? null;
}

/** The signed-in purchaser's session; `undefined` while loading, `null` when signed out. */
export function useSession(): Session | null | undefined {
  const [session, setSession] = useState<Session | null | undefined>(
    authConfigured ? undefined : null,
  );
  useEffect(() => {
    const sb = getSupabase();
    if (!sb) return;
    sb.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = sb.auth.onAuthStateChange((_event, s) => setSession(s));
    return () => data.subscription.unsubscribe();
  }, []);
  return session;
}

/** Friendly messages that never reveal whether an account exists. Mirrors the app's sign-in. */
export function authErrorMessage(
  err: { code?: string; status?: number } | null | undefined,
): string {
  const code = err?.code ?? '';
  if (code === 'otp_expired' || code === 'invalid_credentials')
    return 'That code is wrong or has expired.';
  if (code.startsWith('over_') || err?.status === 429)
    return 'Too many attempts. Please wait a few minutes.';
  return 'Something went wrong. Please try again.';
}

/** Where to go after signing in: only our own pages, never another site. */
export function safeNext(next: string | null): '/pricing' | '/account' {
  return next === 'pricing' || next === '/pricing' ? '/pricing' : '/account';
}

/**
 * Starts "Continue with Google". Google returns to /auth/callback, which finishes signing in and
 * goes on to [next]. Resolves with an error message when it couldn't start.
 */
export async function signInWithGoogle(next: '/pricing' | '/account'): Promise<string | null> {
  const sb = getSupabase();
  if (!sb) return 'Accounts aren’t available on this website yet.';
  const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;
  const { error } = await sb.auth.signInWithOAuth({ provider: 'google', options: { redirectTo } });
  return error ? 'We couldn’t open Google sign-in. Please try again.' : null;
}

/** Messages for a Google sign-in that came back with an error (mirrors the app). */
export function googleErrorMessage(code: string | null, description: string | null): string {
  if (/signups? not allowed/i.test(description ?? ''))
    return 'New accounts can’t be created right now.';
  if (code === 'access_denied') return 'Google sign-in was cancelled.';
  return 'Google sign-in didn’t finish. Please try again.';
}
