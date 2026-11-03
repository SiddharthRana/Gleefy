'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apiFetch, ApiError, errorMessage } from '@/lib/api';
import {
  grantsAccess,
  playManageUrl,
  providerName,
  useBillingConfig,
  type Account,
  type AccountSubscription,
} from '@/lib/billing';
import { authConfigured, authErrorMessage, getSupabase, useSession } from '@/lib/supabase';
import { field, primary, secondary } from '@/lib/ui';

const day = (iso: string) =>
  new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

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

/** Email + one-time code, the same sign-in as the app. */
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
      setError(
        'Accounts and purchases are for people aged 18 or over. Everything free works without an account.',
      );
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
          <label className="flex min-h-12 items-center gap-3 font-bold">
            <input
              type="checkbox"
              className="size-5"
              checked={adult}
              onChange={(e) => setAdult(e.target.checked)}
            />
            I’m 18 or older
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

function SignedIn({ email }: { email?: string }) {
  const config = useBillingConfig();
  const [account, setAccount] = useState<Account | null>(null);
  const [error, setError] = useState<string | null>(null);
  // Only rendered in the browser (after the session loads), so reading the URL here is safe.
  const [checkedOut] = useState(
    () => new URLSearchParams(window.location.search).get('checkout') === 'success',
  );

  useEffect(() => {
    let live = true;
    const fetchAccount = () =>
      apiFetch<Account>('/v1/me').then(
        (a) => {
          if (!live) return;
          setAccount(a);
          setError(null);
        },
        (err: unknown) => {
          if (!live) return;
          // Session expired or account deleted: sign out, which shows the sign-in form.
          if (err instanceof ApiError && (err.status === 401 || err.status === 403))
            void getSupabase()?.auth.signOut();
          else setError(errorMessage(err));
        },
      );
    void fetchAccount();
    // Webhooks can land a moment after the provider redirects back; check once more.
    const timer = checkedOut ? setTimeout(fetchAccount, 4000) : undefined;
    return () => {
      live = false;
      clearTimeout(timer);
    };
  }, [checkedOut]);

  const active = account?.subscriptions.filter(grantsAccess) ?? [];

  return (
    <div className="mt-8 flex flex-col gap-6">
      {checkedOut && (
        <p role="status" className="rounded-card border-2 border-accent bg-surface p-4 font-bold">
          Thanks! Your payment went through. Premium can take a few seconds to appear.
        </p>
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
              {account.entitlements.premiumContent ? 'Premium is on' : 'Free'}
            </p>
            {active.length > 1 && (
              <p role="alert" className="mt-3 rounded-card bg-surface-muted p-4 font-bold">
                You have more than one active subscription. Cancel one so you aren’t charged twice.
              </p>
            )}
            <ul className="mt-4 flex flex-col gap-3">
              {account.subscriptions.map((s, i) => (
                <SubscriptionRow key={i} sub={s} config={config} />
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

function SubscriptionRow({
  sub,
  config,
}: {
  sub: AccountSubscription;
  config: ReturnType<typeof useBillingConfig>;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const live = grantsAccess(sub);

  async function portal() {
    setBusy(true);
    setError(null);
    try {
      const { url } = await apiFetch<{ url: string }>('/v1/billing/portal', { method: 'POST' });
      window.location.assign(url);
      return;
    } catch (err) {
      setError(errorMessage(err));
    }
    setBusy(false);
  }

  return (
    <li className="rounded-card bg-surface-muted p-4">
      <p className="font-bold">
        {sub.interval === 'annual' ? 'Yearly' : sub.interval === 'monthly' ? 'Monthly' : 'Premium'}{' '}
        via {providerName[sub.provider]}
      </p>
      <p className="text-muted">
        {!live
          ? 'Ended'
          : sub.cancelAtPeriodEnd && sub.currentPeriodEnd
            ? `Cancelled. Premium stays on until ${day(sub.currentPeriodEnd)}.`
            : sub.currentPeriodEnd
              ? `Renews on ${day(sub.currentPeriodEnd)}`
              : 'Active'}
      </p>
      {live && sub.provider === 'google_play' && config && (
        <a
          className="mt-2 inline-flex min-h-12 items-center font-bold underline"
          href={playManageUrl(config.googlePlay.packageName, config.googlePlay.subscriptionId)}
          rel="noopener"
        >
          Manage in Google Play
        </a>
      )}
      {live && sub.provider !== 'google_play' && (
        <button type="button" disabled={busy} onClick={portal} className={`${secondary} mt-2`}>
          {busy ? 'Opening…' : 'Manage subscription'}
        </button>
      )}
      {error && (
        <p role="alert" className="mt-2 font-bold">
          {error}
        </p>
      )}
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
        This permanently deletes your MirthMix account. It doesn’t cancel a subscription: cancel it
        first in Google Play or with “Manage subscription” above.
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
