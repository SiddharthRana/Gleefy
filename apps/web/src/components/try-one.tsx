'use client';

import { useState } from 'react';
import { Confetti } from './confetti';
import { secondary } from '@/lib/ui';

type Sample = { id: string; a: string; b: string };

/** A taste of Would You Rather on the landing page, using real starter questions. */
export function TryOne({ samples }: { samples: Sample[] }) {
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState<'a' | 'b' | null>(null);
  const q = samples[index % samples.length]!;

  return (
    <section
      aria-labelledby="try-heading"
      className="rounded-panel border border-border bg-surface p-5 sm:p-6"
    >
      <h2 id="try-heading" className="font-display text-xl font-semibold text-muted">
        Try one: Would you rather…
      </h2>
      <div key={q.id} className="pop relative mt-4 grid gap-3">
        {picked && <Confetti key={picked} pieces={18} seed={index + (picked === 'a' ? 1 : 2)} />}
        {(['a', 'b'] as const).map((side) => (
          <button
            key={side}
            type="button"
            onClick={() => setPicked(side)}
            aria-pressed={picked === side}
            style={{ '--tilt': side === 'a' ? '-0.6deg' : '0.6deg' } as React.CSSProperties}
            className={`choice min-h-20 rounded-panel px-5 py-4 text-left font-display text-xl font-semibold text-on-option ${
              side === 'a' ? 'bg-option-a' : 'bg-option-b'
            } ${picked === side ? 'choice-picked ring-4 ring-accent' : ''}`}
          >
            {q[side]}
            {picked === side && (
              <span className="ml-2" aria-hidden="true">
                ✓
              </span>
            )}
          </button>
        ))}
      </div>
      <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
        <p aria-live="polite" className="min-h-6 font-bold">
          {picked ? 'Nice. Now ask the room who agrees!' : 'Tap your pick.'}
        </p>
        <button
          type="button"
          onClick={() => {
            setIndex((i) => i + 1);
            setPicked(null);
          }}
          className={secondary}
        >
          Another one
        </button>
      </div>
    </section>
  );
}
