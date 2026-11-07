import type { Metadata } from 'next';
import { ModeCard } from '@/components/mode-card';
import { modes } from '@/lib/site';

export const metadata: Metadata = {
  title: 'Games',
  description: 'Every Gleefy party game: Would You Rather, This or That, Trivia Blitz and more.',
  alternates: { canonical: '/games' },
};

export default function GamesPage() {
  return (
    <div className="py-12">
      <h1 className="font-display text-5xl font-bold">Games</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">
        Every game is played together on one phone. Pick one, pass the phone, and play.
      </p>
      <ul className="mt-10 grid gap-4 md:grid-cols-2">
        {modes.map((m) => (
          <ModeCard key={m.id} mode={m} />
        ))}
      </ul>
    </div>
  );
}
