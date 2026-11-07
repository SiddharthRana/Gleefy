import type { Metadata } from 'next';
import { Suspense } from 'react';
import { AuthCallback } from './callback';

export const metadata: Metadata = { title: 'Signing in', robots: { index: false, follow: false } };

export default function CallbackPage() {
  return (
    <div className="max-w-2xl py-12">
      <Suspense>
        <AuthCallback />
      </Suspense>
    </div>
  );
}
