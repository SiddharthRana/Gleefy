'use client';

import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useState } from 'react';
import { getSupabase, googleErrorMessage, safeNext } from '@/lib/supabase';
import { primary } from '@/lib/ui';

/** Where Google sends people back. supabase-js exchanges the ?code= for a session by itself. */
export function AuthCallback() {
  const router = useRouter();
  const params = useSearchParams();
  const next = safeNext(params.get('next'));
  const [noSession, setNoSession] = useState(false);
  // Failures known up front: no accounts configured, or Google reported an error in the URL.
  const reported = params.get('error') || params.get('error_description');
  const failed = !getSupabase() || Boolean(reported);

  useEffect(() => {
    const sb = getSupabase();
    if (!sb || failed) return;
    void sb.auth.getSession().then(({ data }) => {
      if (data.session) router.replace(next);
      else setNoSession(true);
    });
  }, [failed, next, router]);

  if (failed || noSession) {
    return (
      <div role="alert" className="pop rounded-card border-2 border-border bg-surface p-5">
        <h1 className="font-display text-3xl font-semibold">Couldn’t sign you in</h1>
        <p className="mt-2">
          {reported
            ? googleErrorMessage(params.get('error'), params.get('error_description'))
            : 'The sign-in link may have expired or been used already.'}
        </p>
        <Link
          href={`/account${next === '/pricing' ? '?next=pricing' : ''}`}
          className={`${primary} mt-4 inline-flex items-center`}
        >
          Try again
        </Link>
      </div>
    );
  }
  return (
    <p role="status" className="text-lg text-muted">
      Signing you in…
    </p>
  );
}
