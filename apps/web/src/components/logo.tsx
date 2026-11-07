const INK = '#1D1530';

/** The Gleefy mark: a grinning party face in a gold hat (same drawing as scripts/brand-icons.mjs). */
export function Logo({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="150 30 700 870" aria-hidden="true" focusable="false">
      <g stroke={INK} strokeLinejoin="round" strokeLinecap="round">
        <circle cx="512" cy="580" r="300" fill="#FFF6E5" strokeWidth="30" />
        <circle cx="372" cy="650" r="40" fill="#FF8FAB" stroke="none" opacity="0.75" />
        <circle cx="652" cy="650" r="40" fill="#FF8FAB" stroke="none" opacity="0.75" />
        <path d="M370 548q50-62 100 0M554 548q50-62 100 0" fill="none" strokeWidth="34" />
        <path d="M384 628Q512 820 640 628Z" fill={INK} strokeWidth="22" />
        <path d="M458 684q54 30 108 0q-10 34-54 36q-44-2-54-36z" fill="#FF5C8A" stroke="none" />
        <path d="M548 292 742 72 790 350Z" fill="#FFB020" strokeWidth="26" />
        <path d="M622 232 754 196M650 290 770 262" fill="none" stroke="#C42654" strokeWidth="22" />
        <circle cx="742" cy="72" r="44" fill="#FFF6E5" strokeWidth="22" />
      </g>
    </svg>
  );
}
