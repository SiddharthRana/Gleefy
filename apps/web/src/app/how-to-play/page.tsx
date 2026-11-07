import type { Metadata } from 'next';
import Link from 'next/link';
import { guideHref, guides } from '@/lib/guides';

export const metadata: Metadata = {
  title: 'How to play',
  description:
    'How Gleefy works: one phone, a host who reads, and a room that answers. Players, teams, timers and sharing explained.',
  alternates: { canonical: '/how-to-play' },
};

const basics = [
  {
    title: 'One phone, one host',
    body: 'One person holds the phone and reads each question aloud. Everyone else answers out loud or by raising a hand. Pass the phone around to share hosting.',
  },
  {
    title: 'Players and teams',
    body: 'Add up to 12 names. Trivia and Guess the Answer use them as teams taking turns; This or That uses them for pass-the-phone. Names stay on your phone.',
  },
  {
    title: 'Rounds and skipping',
    body: 'Choose 5, 10, 15 or 20 rounds. Skip any question that doesn’t suit your group; when spare questions are available, it doesn’t use up a round.',
  },
  {
    title: 'Timers',
    body: 'This or That has an optional 5-second timer; Trivia has a pausable per-question timer. Timers stop if you leave the app, so a phone call never costs a turn.',
  },
  {
    title: 'Saved automatically',
    body: 'A game in progress survives the app closing. Open Gleefy again and tap Resume.',
  },
  {
    title: 'Share a game',
    body: 'On the website, “Share this game” copies a link. Anyone who opens it gets the same questions in the same order, in the app or the browser.',
  },
];

export default function HowToPlayPage() {
  return (
    <div className="py-12">
      <h1 className="font-display text-5xl font-bold">How to play</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">
        Gleefy is made for people in the same room. Nobody needs to install anything except the
        host, and you never need an account to play.
      </p>
      <ul className="mt-10 grid gap-4 md:grid-cols-2">
        {basics.map((b) => (
          <li key={b.title} className="lift rounded-card border border-border bg-surface p-5">
            <h2 className="font-display text-2xl font-semibold">{b.title}</h2>
            <p className="mt-2">{b.body}</p>
          </li>
        ))}
      </ul>
      <section aria-labelledby="each-game" className="mt-12">
        <h2 id="each-game" className="font-display text-3xl font-semibold">
          Rules for each game
        </h2>
        <ul className="mt-4 grid gap-3 sm:grid-cols-2">
          {guides.map((g) => (
            <li key={g.id}>
              <Link
                href={guideHref(g.id)}
                className="lift flex min-h-12 items-center rounded-card border border-border bg-surface px-4 font-bold hover:bg-surface-muted"
              >
                {g.name}
              </Link>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
