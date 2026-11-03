import type { Metadata } from 'next';
import { Suspense } from 'react';
import { Player, Setup } from './player';

export const metadata: Metadata = {
  title: 'Play',
  description: 'Play MirthMix party games in your browser on one shared screen. No sign-up.',
  alternates: { canonical: '/play' },
};

export default function PlayPage() {
  return (
    <div className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Play</h1>
      <p className="mt-3 mb-8 text-lg text-muted">
        One screen, everyone together. Share the link and friends get the same game.
      </p>
      {/* The setup form is in the static HTML, so the page doesn't jump when the player loads. */}
      <Suspense fallback={<Setup />}>
        <Player />
      </Suspense>
    </div>
  );
}
