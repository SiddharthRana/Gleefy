import type { Metadata } from 'next';
import Link from 'next/link';
import { articles } from '@/lib/guide-articles';

export const metadata: Metadata = {
  title: 'Guides',
  description: 'Practical guides to hosting party games with MirthMix.',
  alternates: { canonical: '/guides' },
};

export default function GuidesPage() {
  return (
    <div className="py-12">
      <h1 className="font-display text-5xl font-bold">Guides</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">
        Practical advice for getting a room playing, from the people who make MirthMix.
      </p>
      <ul className="mt-10 grid gap-4 md:grid-cols-2">
        {articles.map((a) => (
          <li key={a.href} className="lift rounded-card border border-border bg-surface">
            <Link href={a.href} className="block h-full rounded-card p-5 hover:bg-surface-muted">
              <h2 className="font-display text-2xl font-semibold">{a.title}</h2>
              <p className="mt-2 text-muted">{a.summary}</p>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
