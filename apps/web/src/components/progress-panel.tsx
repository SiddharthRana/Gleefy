'use client';

import { levelProgress, TROPHIES } from '@gleefy/game-engine';
import Link from 'next/link';
import { trophyInfo, useProgress } from '@/lib/progress';
import { LevelBadge } from './reward-panel';

/** "Your progress" on the homepage: level, XP bar, streak and trophies, or a teaser before any game. */
export function ProgressPanel() {
  const value = useProgress();
  if (!value) return <div className="min-h-40" />;
  const { progress, streak } = value;
  const lp = levelProgress(progress.xp);
  const fresh = progress.gamesPlayed === 0;
  return (
    <div className="game-card rounded-panel bg-surface p-6">
      <div className="flex flex-wrap items-center gap-4">
        <LevelBadge level={lp.level} />
        <div className="min-w-0 flex-1">
          <p className="font-display text-2xl font-semibold">
            {fresh ? 'Start your party level' : `Level ${lp.level}`}
          </p>
          <div
            className="mt-2 h-3 overflow-hidden rounded-full bg-surface-muted"
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
            {lp.into} / {lp.needed} XP
          </p>
        </div>
        <p className="flex flex-col items-center font-display text-3xl font-bold">
          <span aria-hidden="true">🔥</span>
          <span>{streak}</span>
          <span className="font-sans text-xs font-bold text-muted">day streak</span>
        </p>
      </div>
      <ul className="mt-5 flex flex-wrap gap-2" aria-label="Trophies">
        {TROPHIES.map(({ id }) => {
          const t = trophyInfo[id]!;
          const won = progress.trophies.includes(id);
          return (
            <li
              key={id}
              title={`${t.name}: ${t.description}`}
              className={`grid size-12 place-items-center rounded-full border-2 text-2xl ${won ? 'border-accent bg-surface-muted' : 'border-dashed border-border opacity-50 grayscale'}`}
            >
              <span aria-hidden="true">{won ? t.icon : '🔒'}</span>
              <span className="sr-only">
                {t.name}: {won ? 'earned' : 'locked'}
              </span>
            </li>
          );
        })}
      </ul>
      <p className="mt-4 text-muted">
        {fresh
          ? 'Finish a game to earn XP and your first trophy. Kept on this device only, no account needed.'
          : `${progress.trophies.length} of ${TROPHIES.length} trophies · ${progress.gamesPlayed} ${progress.gamesPlayed === 1 ? 'game' : 'games'} played`}
      </p>
      <Link
        href="/trophies"
        className="mt-2 inline-flex min-h-12 items-center font-bold text-primary underline"
      >
        See all trophies
      </Link>
    </div>
  );
}

/** A small level chip for the header, shown once this browser has played a game. */
export function LevelChip() {
  const value = useProgress();
  if (!value || value.progress.gamesPlayed === 0) return null;
  return (
    <Link
      href="/trophies"
      className="press inline-flex min-h-12 items-center gap-1 rounded-full px-2 font-bold"
      aria-label={`Level ${levelProgress(value.progress.xp).level}, ${value.streak} day streak. Your trophies`}
    >
      <LevelBadge level={levelProgress(value.progress.xp).level} small />
      {value.streak > 0 && (
        <span aria-hidden="true" className="hidden text-sm sm:inline">
          🔥{value.streak}
        </span>
      )}
    </Link>
  );
}
