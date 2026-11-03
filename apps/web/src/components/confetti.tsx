'use client';

import { useMemo } from 'react';

const COLORS = [
  'var(--mm-option-a)',
  'var(--mm-option-b)',
  'var(--mm-accent)',
  'var(--mm-primary)',
  'var(--mm-success)',
];

/**
 * A one-off burst of confetti from the middle of its parent (which must be `position: relative`).
 * Decorative only; under reduced motion the pieces never move and stay invisible.
 */
/** Deterministic pieces for a burst, so it looks the same on every render. */
function burst(pieces: number, seed: number) {
  let x = seed * 9301 + 49297;
  const rand = () => {
    x = (x * 9301 + 49297) % 233280;
    return x / 233280;
  };
  return Array.from({ length: pieces }, (_, i) => {
    const angle = rand() * Math.PI * 2;
    const distance = 90 + rand() * 170;
    return {
      id: i,
      color: COLORS[i % COLORS.length]!,
      round: rand() > 0.6,
      style: {
        '--x': `${Math.cos(angle) * distance}px`,
        '--y': `${Math.sin(angle) * distance * 0.7 + 60}px`,
        '--r': `${rand() * 720 - 360}deg`,
        '--dur': `${1.1 + rand() * 0.7}s`,
        '--delay': `${rand() * 0.12}s`,
      } as React.CSSProperties,
    };
  });
}

export function Confetti({ pieces = 36, seed = 1 }: { pieces?: number; seed?: number }) {
  const bits = useMemo(() => burst(pieces, seed), [pieces, seed]);

  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0 overflow-visible">
      {bits.map((b) => (
        <span
          key={b.id}
          className={`confetti-piece absolute top-1/2 left-1/2 h-2.5 w-2 opacity-0 ${b.round ? 'rounded-full' : 'rounded-[2px]'}`}
          style={{ ...b.style, background: b.color }}
        />
      ))}
    </div>
  );
}
