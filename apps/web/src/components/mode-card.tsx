import Link from 'next/link';
import { statusLabel, type ModeInfo } from '@/lib/site';

/** A game in the library, styled like a game cartridge: colour band, icon and quick stats. */
export function ModeCard({ mode, index = 0 }: { mode: ModeInfo; index?: number }) {
  const body = (
    <>
      <div
        className="relative flex h-24 items-center justify-between overflow-hidden rounded-t-[calc(var(--radius-card)-2px)] px-5"
        style={{ background: mode.color }}
      >
        <span aria-hidden="true" className="text-5xl drop-shadow-[0_3px_0_rgb(0_0_0/0.25)]">
          {mode.icon}
        </span>
        <span className="rounded-full border-2 border-text bg-surface px-3 py-1 text-sm font-bold text-text">
          {statusLabel[mode.status]}
        </span>
      </div>
      <div className="p-5">
        <h3 className="font-display text-2xl font-semibold">{mode.name}</h3>
        <p className="mt-1 text-muted">{mode.blurb}</p>
        <p className="mt-3 flex flex-wrap gap-2 text-sm font-bold">
          <span className="rounded-full bg-surface-muted px-3 py-1">
            <span aria-hidden="true">👥 </span>
            {mode.players} players
          </span>
          <span className="rounded-full bg-surface-muted px-3 py-1">
            <span aria-hidden="true">⏱ </span>~{mode.minutes} min
          </span>
        </p>
      </div>
    </>
  );
  return (
    <li
      className="game-card rounded-card bg-surface"
      style={{ '--tilt': `${index % 2 ? 0.6 : -0.6}deg` } as React.CSSProperties}
    >
      {mode.href ? (
        <Link href={mode.href} className="block h-full rounded-card">
          {body}
        </Link>
      ) : (
        body
      )}
    </li>
  );
}
