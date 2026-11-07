'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { CheckoutStatus, checkoutFailed, type CheckoutState } from '@/components/checkout-status';
import { apiFetch, ApiError, errorMessage } from '@/lib/api';
import { providerName, type Account, type AccountPurchase } from '@/lib/billing';
import {
  authConfigured,
  authErrorMessage,
  getSupabase,
  googleSignInEnabled,
  safeNext,
  signInWithGoogle,
  useSession,
} from '@/lib/supabase';
import { field, primary, secondary } from '@/lib/ui';

const day = (iso: string) =>
  new Date(iso).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });

export function AccountView() {
  const session = useSession();
  if (!authConfigured) {
    return (
      <p className="mt-8 rounded-card bg-surface-muted p-4">
        Accounts aren’t available on this website yet.
      </p>
    );
  }
  if (session === undefined) return <p className="mt-8 text-muted">Loading…</p>;
  return session ? <SignedIn email={session.user.email} /> : <SignInForm />;
}

const ADULT_ONLY =
  'Accounts and purchases are for people aged 18 or over. Everything free works without an account.';

/** "Continue with Google" or email + one-time code, the same sign-in as the app. */
function SignInForm() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  // Accounts and purchases are 18+ (BUILD_PROMPT §0, India's DPDP Act); self-declared here.
  const [adult, setAdult] = useState(false);
  const [code, setCode] = useState('');
  const [sentTo, setSentTo] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) {
      setError('Enter a valid email address.');
      return;
    }
    if (!adult) {
      setError(ADULT_ONLY);
      return;
    }
    setBusy(true);
    setError(null);
    const { error: err } = await getSupabase()!.auth.signInWithOtp({ email: email.trim() });
    setBusy(false);
    if (err) setError(authErrorMessage(err));
    else setSentTo(email.trim());
  }

  async function verify(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const { error: err } = await getSupabase()!.auth.verifyOtp({
      email: sentTo!,
      token: code.trim(),
      type: 'email',
    });
    setBusy(false);
    if (err) {
      setError(authErrorMessage(err));
      return;
    }
    if (new URLSearchParams(window.location.search).get('next') === 'pricing')
      router.push('/pricing');
  }

  async function google() {
    if (!adult) {
      setError(ADULT_ONLY);
      return;
    }
    setBusy(true);
    setError(null);
    const failed = await signInWithGoogle(
      safeNext(new URLSearchParams(window.location.search).get('next')),
    );
    // On success the browser is already on its way to Google.
    if (failed) {
      setError(failed);
      setBusy(false);
    }
  }

  return (
    <form onSubmit={sentTo ? verify : send} className="mt-8 flex flex-col gap-4" noValidate>
      <h2 className="font-display text-3xl font-semibold">Sign in</h2>
      {sentTo ? (
        <>
          <p>We sent a 6-digit code to {sentTo}.</p>
          <label className="flex flex-col gap-2 font-bold">
            Code from the email
            <input
              className={field}
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              value={code}
              onChange={(e) => setCode(e.target.value)}
            />
          </label>
        </>
      ) : (
        <>
          <label className="flex min-h-12 items-center gap-3 font-bold">
            <input
              type="checkbox"
              className="size-5"
              checked={adult}
              onChange={(e) => setAdult(e.target.checked)}
            />
            I’m 18 or older
          </label>
          {googleSignInEnabled && (
            <>
              <button
                type="button"
                disabled={busy}
                onClick={google}
                className={`${secondary} inline-flex items-center justify-center gap-3`}
              >
                <GoogleMark />
                Continue with Google
              </button>
              <p className="text-center text-sm font-bold uppercase tracking-wide text-muted">
                or use your email
              </p>
            </>
          )}
          <p>We’ll email you a 6-digit code. No password needed.</p>
          <label className="flex flex-col gap-2 font-bold">
            Email
            <input
              className={field}
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </label>
        </>
      )}
      {error && (
        <p role="alert" className="font-bold">
          {error}
        </p>
      )}
      <div className="flex flex-wrap gap-3">
        <button type="submit" disabled={busy} className={primary}>
          {sentTo ? 'Sign in' : 'Send code'}
        </button>
        {sentTo && (
          <button
            type="button"
            disabled={busy}
            className={secondary}
            onClick={() => {
              setSentTo(null);
              setCode('');
              setError(null);
            }}
          >
            Use a different email
          </button>
        )}
      </div>
    </form>
  );
}

/** Google's "G" mark, as Google's sign-in branding asks for. */
function GoogleMark() {
  return (
    <svg aria-hidden="true" viewBox="0 0 48 48" className="size-5">
      <path
        fill="#FFC107"
        d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"
      />
      <path
        fill="#FF3D00"
        d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"
      />
      <path
        fill="#4CAF50"
        d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"
      />
      <path
        fill="#1976D2"
        d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"
      />
    </svg>
  );
}

/** Reads (once) and removes the checkout parameters Dodo adds to the return URL. */
function readCheckoutReturn(): CheckoutState | null {
  const params = new URLSearchParams(window.location.search);
  const back = params.get('checkout') === 'success' || params.has('payment_id');
  if (!back) return null;
  const failed = checkoutFailed(params.get('status'));
  for (const key of ['checkout', 'payment_id', 'status', 'email']) params.delete(key);
  const rest = params.toString();
  window.history.replaceState(null, '', `${window.location.pathname}${rest ? `?${rest}` : ''}`);
  return failed ? 'failed' : 'confirming';
}

/** How often, and for how long, to re-check after checkout before saying it's still pending. */
const POLL_MS = 2000;
const POLL_FOR_MS = 20_000;

function SignedIn({ email }: { email?: string }) {
  const [account, setAccount] = useState<Account | null>(null);
  const [error, setError] = useState<string | null>(null);
  // Only rendered in the browser (after the session loads), so reading the URL here is safe.
  const [checkout, setCheckout] = useState<CheckoutState | null>(readCheckoutReturn);
  const [pollUntil, setPollUntil] = useState(() => Date.now() + POLL_FOR_MS);

  const fetchAccount = useCallback(
    () =>
      apiFetch<Account>('/v1/me').then(
        (a) => {
          setAccount(a);
          setError(null);
          return a;
        },
        (err: unknown) => {
          // Session expired or account deleted: sign out, which shows the sign-in form.
          if (err instanceof ApiError && (err.status === 401 || err.status === 403))
            void getSupabase()?.auth.signOut();
          else setError(errorMessage(err));
          return null;
        },
      ),
    [],
  );

  useEffect(() => {
    void fetchAccount();
  }, [fetchAccount]);

  // After checkout, the webhook can land a moment after Dodo sends people back: keep checking.
  useEffect(() => {
    if (checkout !== 'confirming') return;
    let live = true;
    const timer = setInterval(async () => {
      const a = await fetchAccount();
      if (!live) return;
      if (a?.entitlements.premiumContent) setCheckout('active');
      else if (Date.now() > pollUntil) setCheckout('pending');
    }, POLL_MS);
    return () => {
      live = false;
      clearInterval(timer);
    };
  }, [checkout, fetchAccount, pollUntil]);

  const shownCheckout =
    checkout === 'confirming' && account?.entitlements.premiumContent ? 'active' : checkout;

  return (
    <div className="mt-8 flex flex-col gap-6">
      {shownCheckout && (
        <CheckoutStatus
          state={shownCheckout}
          onCheckAgain={() => {
            setPollUntil(Date.now() + POLL_FOR_MS);
            setCheckout('confirming');
          }}
          onDismiss={() => setCheckout(null)}
        />
      )}
      <section aria-labelledby="plan" className="rounded-card border border-border bg-surface p-5">
        <h2 id="plan" className="font-display text-3xl font-semibold">
          Your plan
        </h2>
        <p className="mt-1 text-muted">Signed in as {email}</p>
        {error && (
          <p role="alert" className="mt-3 font-bold">
            {error}
          </p>
        )}
        {!account && !error && <p className="mt-3 text-muted">Loading…</p>}
        {account && (
          <>
            <p className="mt-3 text-2xl font-bold">
              {account.entitlements.premiumContent ? 'Premium is unlocked' : 'Free'}
            </p>
            {account.purchases.filter((p) => p.status === 'active').length > 1 && (
              <p role="alert" className="mt-3 rounded-card bg-surface-muted p-4 font-bold">
                You bought Premium more than once. Contact us and we’ll refund the extra purchase.
              </p>
            )}
            <ul className="mt-4 flex flex-col gap-3">
              {account.purchases.map((p, i) => (
                <PurchaseRow key={i} purchase={p} />
              ))}
            </ul>
            {!account.entitlements.premiumContent && (
              <Link href="/pricing" className={`${primary} mt-4 inline-flex items-center`}>
                See Premium
              </Link>
            )}
          </>
        )}
      </section>
      <button
        type="button"
        className={`${secondary} self-start`}
        onClick={() => getSupabase()?.auth.signOut()}
      >
        Sign out
      </button>
      <DeleteAccount />
    </div>
  );
}

function PurchaseRow({ purchase }: { purchase: AccountPurchase }) {
  return (
    <li className="rounded-card bg-surface-muted p-4">
      <p className="font-bold">Premium unlock via {providerName[purchase.provider]}</p>
      <p className="text-muted">
        {purchase.status === 'on_hold'
          ? 'Waiting for the payment to finish'
          : purchase.purchasedAt
            ? `Bought on ${day(purchase.purchasedAt)}. Yours to keep.`
            : 'Yours to keep.'}
      </p>
    </li>
  );
}

function DeleteAccount() {
  const [confirm, setConfirm] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function remove(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await apiFetch('/v1/me', { method: 'DELETE', body: { confirm: confirm.trim() } });
      await getSupabase()?.auth.signOut();
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <form
      onSubmit={remove}
      aria-labelledby="delete-account"
      className="rounded-card border border-border bg-surface p-5"
    >
      <h2 id="delete-account" className="font-display text-3xl font-semibold">
        Delete account
      </h2>
      <p className="mt-3">
        This permanently deletes your Gleefy account, including the Premium you bought: it can’t be
        restored to a new account later.
      </p>
      <label className="mt-4 flex flex-col gap-2 font-bold">
        Type DELETE to confirm
        <input className={field} value={confirm} onChange={(e) => setConfirm(e.target.value)} />
      </label>
      {error && (
        <p role="alert" className="mt-3 font-bold">
          {error}
        </p>
      )}
      <button
        type="submit"
        disabled={busy || confirm.trim() !== 'DELETE'}
        className={`${secondary} mt-4`}
      >
        Delete my account
      </button>
    </form>
  );
}
