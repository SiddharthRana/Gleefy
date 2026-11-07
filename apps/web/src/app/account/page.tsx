import type { Metadata } from 'next';
import { AccountView } from './account-view';

export const metadata: Metadata = {
  title: 'Account',
  description: 'Sign in to buy or manage Gleefy Premium.',
  alternates: { canonical: '/account' },
  robots: { index: false, follow: true },
};

export default function AccountPage() {
  return (
    <div className="max-w-2xl py-12">
      <h1 className="font-display text-5xl font-bold">Account</h1>
      <p className="mt-3 text-lg text-muted">
        You only need an account to buy or restore Premium. Playing never needs one.
      </p>
      <AccountView />
    </div>
  );
}
