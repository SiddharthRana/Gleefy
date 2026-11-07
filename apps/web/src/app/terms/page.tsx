import type { Metadata } from 'next';
import { LegalDraftNotice } from '@/components/legal-draft';

export const metadata: Metadata = {
  title: 'Terms',
  description: 'Terms of use for Gleefy.',
  alternates: { canonical: '/terms' },
};

export default function TermsPage() {
  return (
    <article className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Terms</h1>
      <LegalDraftNotice />
      <h2 className="mt-10 font-display text-3xl font-semibold">Using Gleefy</h2>
      <p className="mt-3">
        Gleefy is a party game for people playing together in person. Play kindly: skip any question
        that doesn&rsquo;t suit your group, and never pressure anyone to answer.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Content</h2>
      <p className="mt-3">
        Questions are original to Gleefy and provided for entertainment. They are not advice.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Accounts</h2>
      <p className="mt-3">
        Playing never needs an account. An account is only for buying or restoring Premium, and is
        for people aged 18 or over. You can delete it at any time (see{' '}
        <a href="/account-deletion" className="font-bold text-primary underline">
          Delete your account
        </a>
        ).
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Premium</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6">
        <li>
          Premium is a one-time purchase, not a subscription: you pay once and nothing renews. In
          the apps it is sold and billed by Google Play (Android) or the App Store (iOS); on the
          website by our payment partner, who is the seller of record and handles tax and receipts.
        </li>
        <li>
          Premium belongs to the account you bought it with, on every device where you sign in to
          that account. A refunded purchase no longer unlocks Premium.
        </li>
        <li>
          Refunds follow Google Play’s policy for app purchases, and our payment partner’s policy
          for website purchases. Prices are shown before you pay and may vary by country.
        </li>
        <li>Free play stays free: Premium only adds extra categories.</li>
      </ul>
    </article>
  );
}
