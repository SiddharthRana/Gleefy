import Link from 'next/link';
import { statusLabel, type ModeInfo } from '@/lib/site';

export function ModeCard({ mode }: { mode: ModeInfo }) {
  const available = mode.status === 'available';
  const body = (
    <>
      <div className="flex items-start justify-between gap-3">
        <h3 className="font-display text-2xl font-semibold">{mode.name}</h3>
        <span
          className={
            available
              ? 'shrink-0 rounded-full bg-primary px-3 py-1 text-sm font-bold text-on-primary'
              : 'shrink-0 rounded-full bg-surface-muted px-3 py-1 text-sm font-bold text-muted'
          }
        >
          {statusLabel[mode.status]}
        </span>
      </div>
      <p className="mt-2 text-muted">{mode.blurb}</p>
    </>
  );
  return (
    <li className={`${mode.href ? 'lift' : ''} rounded-card border border-border bg-surface`}>
      {mode.href ? (
        <Link href={mode.href} className="block h-full rounded-card p-5 hover:bg-surface-muted">
          {body}
        </Link>
      ) : (
        <div className="p-5">{body}</div>
      )}
    </li>
  );
}
