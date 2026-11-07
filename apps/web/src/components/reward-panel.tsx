'use client';

import { levelProgress, type GameReward } from '@gleefy/game-engine';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { trophyInfo } from '@/lib/progress';

/** What a finished game earned: XP counting up, the level bar filling, level-ups and trophies. */
export function RewardPanel({ reward }: { reward: GameReward }) {
  const after = levelProgress(reward.progress.xp);
  // Rendered only in the browser after a game, so reading the motion setting here is safe.
  const [still] = useState(() => window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  const [shown, setShown] = useState(still ? reward.xpGained : 0);

  // Counts the XP up once (shown at once under reduced motion).
  useEffect(() => {
    if (still) return;
    let frame = 0;
    const startAt = performance.now();
    const tick = (now: number) => {
      const t = Math.min(1, (now - startAt) / 700);
      setShown(Math.round(reward.xpGained * (1 - (1 - t) ** 3)));
      if (t < 1) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [reward.xpGained, still]);

  const leveledUp = reward.levelAfter > reward.levelBefore;
  return (
    <section
      aria-labelledby="reward-heading"
      className="pop-big rounded-panel border-2 border-accent bg-surface p-6"
    >
      <h2 id="reward-heading" className="sr-only">
        Your reward
      </h2>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <p className="font-display text-4xl font-bold text-primary" aria-live="polite">
          <span aria-hidden="true">+{shown}</span>
          <span className="sr-only">+{reward.xpGained}</span> XP
        </p>
        <LevelBadge level={after.level} />
      </div>
      <div
        className="mt-4 h-4 overflow-hidden rounded-full bg-surface-muted"
        role="progressbar"
        aria-label={`Level ${after.level}`}
        aria-valuemin={0}
        aria-valuemax={after.needed}
        aria-valuenow={after.into}
      >
        <div
          className="xp-fill brand-gradient h-full rounded-full"
          style={{ width: `${Math.round((100 * after.into) / after.needed)}%` }}
        />
      </div>
      <p className="mt-2 text-sm font-bold text-muted">
        {after.needed - after.into} XP to level {after.level + 1}
      </p>
      {leveledUp && (
        <p className="pop-big mt-4 rounded-card bg-primary p-3 text-center font-display text-2xl font-bold text-on-primary">
          Level up! You’re now level {reward.levelAfter}
        </p>
      )}
      {reward.newTrophies.length > 0 && (
        <div className="mt-4">
          <p className="font-bold">
            New {reward.newTrophies.length === 1 ? 'trophy' : 'trophies'}!
          </p>
          <ul className="mt-2 flex flex-wrap gap-3">
            {reward.newTrophies.map((id, i) => {
              const t = trophyInfo[id];
              return t ? (
                <li
                  key={id}
                  className="pop-big flex items-center gap-3 rounded-card border-2 border-border bg-surface-muted px-4 py-2"
                  style={{ animationDelay: `${0.2 + i * 0.15}s` }}
                >
                  <span aria-hidden="true" className="text-3xl">
                    {t.icon}
                  </span>
                  <span>
                    <span className="block font-bold">{t.name}</span>
                    <span className="block text-sm text-muted">{t.description}</span>
                  </span>
                </li>
              ) : null;
            })}
          </ul>
        </div>
      )}
      <Link
        href="/trophies"
        className="mt-4 inline-flex min-h-12 items-center font-bold text-primary underline"
      >
        See all your trophies
      </Link>
    </section>
  );
}

/** A round "LV n" badge, like a game's level counter. */
export function LevelBadge({ level, small = false }: { level: number; small?: boolean }) {
  return (
    <span
      className={`brand-gradient inline-flex flex-col items-center justify-center rounded-full font-display font-bold leading-none shadow-[0_3px_0_var(--press-edge)] ${small ? 'size-9 text-sm' : 'size-16 text-2xl'}`}
      role="img"
      aria-label={`Level ${level}`}
    >
      <span aria-hidden="true" className={small ? 'text-[0.55rem]' : 'text-xs'}>
        LV
      </span>
      <span aria-hidden="true">{level}</span>
    </span>
  );
}
