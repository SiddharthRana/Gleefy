import Link from 'next/link';
import { ModeCard } from '@/components/mode-card';
import { TryOne } from '@/components/try-one';
import { wyrCount, wyrSamples } from '@/lib/content';
import { modes } from '@/lib/site';

const steps = [
  { title: 'Pick a game', body: 'Choose a mode and categories, or tap Quick play.' },
  { title: 'Read it out', body: 'One person holds the phone and reads the question to the room.' },
  {
    title: 'Everyone answers',
    body: 'Raise hands, tap the votes, reveal the split. Then argue about it.',
  },
];

const reasons = [
  { title: 'One phone is enough', body: 'Nobody else needs to install anything or join a room.' },
  { title: 'No sign-up', body: 'Open the app and play. No account, no email, no profile.' },
  {
    title: 'Private by design',
    body: 'Games, settings and player names stay on your phone. Usage stats only if you opt in.',
  },
  {
    title: 'Original questions',
    body: 'Every question is written for MirthMix and suitable for ages 13+.',
  },
];

export default function HomePage() {
  return (
    <>
      <section className="rise grid items-center gap-10 py-12 md:grid-cols-2 md:py-20">
        <div>
          <h1 className="font-display text-5xl font-bold leading-tight sm:text-6xl">
            Party games for <span className="text-primary">one phone</span>.
          </h1>
          <p className="mt-5 text-lg text-muted">
            Quick, silly and surprisingly deep games for friends, couples and families sitting
            together. Start in seconds, no sign-up needed.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/games"
              className="brand-gradient inline-flex min-h-14 items-center rounded-full px-7 text-lg font-bold"
            >
              See the games
            </Link>
            <p className="inline-flex min-h-14 items-center rounded-full border-2 border-border px-6 font-bold text-muted">
              Android app coming soon
            </p>
          </div>
        </div>
        <TryOne samples={wyrSamples} />
      </section>

      <section id="how-it-works" aria-labelledby="how-heading" className="scroll-mt-8 py-12">
        <h2 id="how-heading" className="font-display text-4xl font-semibold">
          How to play
        </h2>
        <ol className="mt-8 grid gap-4 md:grid-cols-3">
          {steps.map((s, i) => (
            <li key={s.title} className="rounded-card border border-border bg-surface p-5">
              <span
                aria-hidden="true"
                className="brand-gradient inline-flex size-10 items-center justify-center rounded-full font-display text-xl font-bold"
              >
                {i + 1}
              </span>
              <h3 className="mt-3 font-display text-2xl font-semibold">{s.title}</h3>
              <p className="mt-1 text-muted">{s.body}</p>
            </li>
          ))}
        </ol>
      </section>

      <section aria-labelledby="games-heading" className="py-12">
        <h2 id="games-heading" className="font-display text-4xl font-semibold">
          The games
        </h2>
        <p className="mt-2 text-muted">
          Five ways to play, all on one phone. Would You Rather alone has {wyrCount()} original
          questions.
        </p>
        <ul className="mt-8 grid gap-4 md:grid-cols-2">
          {modes.map((m) => (
            <ModeCard key={m.id} mode={m} />
          ))}
        </ul>
      </section>

      <section aria-labelledby="why-heading" className="py-12">
        <h2 id="why-heading" className="font-display text-4xl font-semibold">
          Why MirthMix
        </h2>
        <ul className="mt-8 grid gap-4 sm:grid-cols-2">
          {reasons.map((r) => (
            <li key={r.title} className="rounded-card border border-border bg-surface p-5">
              <h3 className="font-display text-2xl font-semibold">{r.title}</h3>
              <p className="mt-1 text-muted">{r.body}</p>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
