'use client';

import { levelProgress, TROPHIES } from '@mirthmix/game-engine';
import Link from 'next/link';
import { LevelBadge } from '@/components/reward-panel';
import { trophyInfo, useProgress } from '@/lib/progress';
import { primary } from '@/lib/ui';

export function TrophyRoom() {
  const value = useProgress();
  if (!value) return <div className="min-h-96" />;
  const { progress, streak } = value;
  const lp = levelProgress(progress.xp);
  const stats = [
    { label: 'Total XP', value: progress.xp },
    { label: 'Games played', value: progress.gamesPlayed },
    { label: 'Day streak', value: streak },
    { label: 'Best streak', value: progress.bestStreak },
  ];
  return (
    <div className="mt-8 grid gap-8">
      <section
        aria-label="Level"
        className="game-card flex flex-wrap items-center gap-5 rounded-panel bg-surface p-6"
      >
        <LevelBadge level={lp.level} />
        <div className="min-w-0 flex-1">
          <p className="font-display text-3xl font-semibold">Level {lp.level}</p>
          <div
            className="mt-2 h-4 overflow-hidden rounded-full bg-surface-muted"
            role="progressbar"
            aria-label={`XP towards level ${lp.level + 1}`}
            aria-valuemin={0}
            aria-valuemax={lp.needed}
            aria-valuenow={lp.into}
          >
            <div
              className="xp-fill brand-gradient h-full rounded-full"
              style={{ width: `${Math.round((100 * lp.into) / lp.needed)}%` }}
            />
          </div>
          <p className="mt-1 text-sm font-bold text-muted">
            {lp.needed - lp.into} XP to level {lp.level + 1}
          </p>
        </div>
      </section>

      <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {stats.map((s) => (
          <div key={s.label} className="game-card rounded-card bg-surface p-4 text-center">
            <dt className="text-sm font-bold text-muted">{s.label}</dt>
            <dd className="font-display text-4xl font-bold">{s.value}</dd>
          </div>
        ))}
      </dl>

      <section aria-labelledby="trophy-list">
        <h2 id="trophy-list" className="font-display text-3xl font-semibold">
          {progress.trophies.length} of {TROPHIES.length} trophies
        </h2>
        <ul className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {TROPHIES.map(({ id }) => {
            const t = trophyInfo[id]!;
            const won = progress.trophies.includes(id);
            return (
              <li
                key={id}
                className={`flex items-center gap-4 rounded-card border-2 p-4 ${won ? 'game-card border-accent bg-surface' : 'border-dashed border-border bg-surface-muted'}`}
              >
                <span
                  aria-hidden="true"
                  className={`grid size-14 shrink-0 place-items-center rounded-full text-3xl ${won ? 'bg-surface-muted' : 'grayscale'}`}
                >
                  {won ? t.icon : '🔒'}
                </span>
                <span>
                  <span className="block font-display text-xl font-semibold">{t.name}</span>
                  <span className="block text-muted">{t.description}</span>
                  <span className="sr-only">{won ? 'Earned.' : 'Not earned yet.'}</span>
                </span>
              </li>
            );
          })}
        </ul>
      </section>

      <p>
        <Link href="/play" className={`${primary} inline-flex items-center gap-2`}>
          <span aria-hidden="true">▶</span> Play a game
        </Link>
      </p>
    </div>
  );
}
