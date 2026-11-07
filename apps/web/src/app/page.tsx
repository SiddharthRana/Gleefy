import Link from 'next/link';
import { Crew } from '@/components/crew';
import { ModeCard } from '@/components/mode-card';
import { ProgressPanel } from '@/components/progress-panel';
import { TryOne } from '@/components/try-one';
import { wyrCount, wyrSamples } from '@/lib/content';
import { premiumCategories, premiumQuestionCount } from '@/lib/packs';
import { formatPrice, PLANS } from '@mirthmix/plans';
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
  {
    icon: '🎉',
    title: 'Free to play, no sign-up',
    body: 'Every game and every free category works straight away. No account, no email, no ads.',
  },
  {
    icon: '📱',
    title: 'One phone is enough',
    body: 'Nobody else needs to install anything or join a room. Just pass the phone.',
  },
  {
    icon: '🏆',
    title: 'Level up as you play',
    body: 'Earn XP, keep a daily streak going and collect trophies. Kept on your device.',
  },
  {
    icon: '🌍',
    title: 'Made for friends anywhere',
    body: 'Original questions about the whole world, written for MirthMix and fine for ages 13+.',
  },
];

const premiumPerks = [
  'Every premium category in every game',
  'Pay once and keep it: no subscription',
  'Works in the Android and iOS apps and on this website',
];

export default function HomePage() {
  return (
    <>
      <section className="doodle-bg relative -mx-4 grid items-center gap-10 px-4 py-12 md:grid-cols-2 md:py-20">
        {/* Drifting party bits behind the hero. Decorative; still under reduced motion. */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 -z-10 overflow-hidden"
        >
          <span className="float absolute top-10 left-[45%] size-4 rounded-full bg-option-a opacity-60" />
          <span
            className="float absolute top-[70%] left-[8%] size-3 rotate-12 rounded-[3px] bg-accent opacity-70"
            style={{ animationDelay: '-2s' }}
          />
          <span
            className="float absolute top-[20%] right-[4%] size-5 rounded-full bg-option-b opacity-50"
            style={{ animationDelay: '-4s' }}
          />
          <span
            className="float absolute bottom-6 left-[52%] size-3 rounded-[3px] bg-primary opacity-60"
            style={{ animationDelay: '-1s' }}
          />
        </div>
        <div>
          <Crew className="mb-4" />
          <p className="flex flex-wrap gap-3">
            <span
              className="sticker bg-accent text-on-accent"
              style={{ '--tilt': '-4deg' } as React.CSSProperties}
            >
              Free to play
            </span>
            <span
              className="sticker bg-surface"
              style={{ '--tilt': '3deg' } as React.CSSProperties}
            >
              No sign-up
            </span>
            <span
              className="sticker bg-option-b text-on-option"
              style={{ '--tilt': '-2deg' } as React.CSSProperties}
            >
              One phone
            </span>
          </p>
          <h1 className="mt-6 font-display text-5xl font-bold leading-tight sm:text-6xl">
            Party games for <span className="text-primary">one phone</span>.
          </h1>
          <p className="mt-5 text-lg text-muted">
            Would You Rather, Trivia Blitz and more. Pass one phone around the room and play
            together in seconds, free and with nothing to sign up for.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <span className="pulse inline-flex rounded-full">
              <Link
                href="/play"
                className="press btn-3d brand-gradient inline-flex min-h-16 items-center gap-2 rounded-full px-8 font-display text-2xl font-bold"
              >
                <span aria-hidden="true">▶</span> Play now
              </Link>
            </span>
            <Link
              href="/games"
              className="press btn-3d-soft inline-flex min-h-14 items-center rounded-full border-2 border-border bg-surface px-6 text-lg font-bold"
            >
              See the games
            </Link>
          </div>
          <p className="mt-4 font-bold text-muted">Android and iOS apps coming soon.</p>
        </div>
        <TryOne samples={wyrSamples} />
      </section>

      <section aria-labelledby="progress-heading" className="py-12">
        <h2 id="progress-heading" className="font-display text-4xl font-semibold">
          Your progress
        </h2>
        <div className="mt-6">
          <ProgressPanel />
        </div>
      </section>

      <section id="how-it-works" aria-labelledby="how-heading" className="scroll-mt-8 py-12">
        <h2 id="how-heading" className="font-display text-4xl font-semibold">
          How to play
        </h2>
        <ol className="mt-8 grid gap-4 md:grid-cols-3">
          {steps.map((s, i) => (
            <li key={s.title} className="lift rounded-card border border-border bg-surface p-5">
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
          {modes.map((m, i) => (
            <ModeCard key={m.id} mode={m} index={i} />
          ))}
        </ul>
      </section>

      <section aria-labelledby="why-heading" className="py-12">
        <h2 id="why-heading" className="font-display text-4xl font-semibold">
          Why MirthMix
        </h2>
        <ul className="mt-8 grid gap-4 sm:grid-cols-2">
          {reasons.map((r, i) => (
            <li
              key={r.title}
              className="game-card rounded-card bg-surface p-5"
              style={{ '--tilt': `${i % 2 ? 0.6 : -0.6}deg` } as React.CSSProperties}
            >
              <span aria-hidden="true" className="text-4xl">
                {r.icon}
              </span>
              <h3 className="mt-2 font-display text-2xl font-semibold">{r.title}</h3>
              <p className="mt-1 text-muted">{r.body}</p>
            </li>
          ))}
        </ul>
      </section>

      <section
        aria-labelledby="premium-heading"
        className="my-12 rounded-panel border-2 border-accent bg-surface p-6 sm:p-8"
      >
        <p
          className="sticker premium-pill border-0"
          style={{ '--tilt': '-2deg' } as React.CSSProperties}
        >
          <span aria-hidden="true">★</span> Premium
        </p>
        <h2 id="premium-heading" className="mt-4 font-display text-4xl font-semibold">
          Want more? Unlock {premiumCategories.length} extra categories.
        </h2>
        <p className="mt-2 text-lg text-muted">
          {premiumQuestionCount} more questions across every game, for{' '}
          <strong className="text-text">
            {formatPrice(PLANS.premium.displayPrice!.amount, 'USD')} once
          </strong>
          .
        </p>
        <ul className="mt-6 flex flex-wrap gap-2" aria-label="Premium categories">
          {premiumCategories.map((c) => (
            <li
              key={c.id}
              className="rounded-full border-2 border-border bg-surface-muted px-3 py-1 font-bold"
            >
              {c.name} <span className="font-normal text-muted">· {c.mode}</span>
            </li>
          ))}
        </ul>
        <ul className="mt-6 grid gap-2 sm:grid-cols-3">
          {premiumPerks.map((p) => (
            <li key={p} className="flex items-start gap-2 font-bold">
              <span aria-hidden="true" className="text-success">
                ✔
              </span>
              {p}
            </li>
          ))}
        </ul>
        <Link
          href="/pricing"
          className="press premium-pill mt-6 inline-flex min-h-14 items-center gap-2 rounded-full px-7 text-lg font-bold"
        >
          <span aria-hidden="true">★</span> Unlock Premium
        </Link>
      </section>
    </>
  );
}
