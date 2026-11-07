import type { Metadata } from 'next';
import Link from 'next/link';
import { LegalDraftNotice } from '@/components/legal-draft';
import { contactEmail } from '@/lib/contact';

export const metadata: Metadata = {
  title: 'Delete your account',
  description: 'How to delete your Gleefy account and what happens to your data.',
  alternates: { canonical: '/account-deletion' },
};

export default function AccountDeletionPage() {
  return (
    <article className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Delete your account</h1>
      <LegalDraftNotice />
      <p className="mt-6 text-lg">
        You only have a Gleefy account if you signed in to buy or restore Premium. Playing without
        an account stores nothing on our servers, so there is nothing to delete.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">How to delete it</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6 text-lg">
        <li>
          <strong>In the app:</strong> Settings → Account → Delete account, then type DELETE.
        </li>
        <li>
          <strong>On the website:</strong> sign in on the{' '}
          <Link href="/account" className="font-bold text-primary underline">
            Account
          </Link>{' '}
          page and use “Delete account”.
        </li>
        <li>
          <strong>No longer have access?</strong> Email{' '}
          <a href={`mailto:${contactEmail}`} className="font-bold text-primary underline">
            {contactEmail}
          </a>{' '}
          from the address you signed in with.
        </li>
      </ul>
      <h2 className="mt-10 font-display text-3xl font-semibold">What gets deleted</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6 text-lg">
        <li>
          Your account is disabled immediately, and your email and sign-in record are deleted.
        </li>
        <li>Your purchase records are deleted with the account.</li>
        <li>
          Messages from Google Play or our payment partner about your purchase are kept for up to 30
          days for troubleshooting, then their contents are erased.
        </li>
        <li>
          Google Play and our payment partner keep their own purchase records, as the law requires
          them to.
        </li>
      </ul>
      <h2 className="mt-10 font-display text-3xl font-semibold">Premium goes with it</h2>
      <p className="mt-3 text-lg">
        Premium belongs to your account, so deleting the account removes it, and it can’t be moved
        to a new account later. There is nothing to cancel: Premium is a one-time purchase.
      </p>
    </article>
  );
}
