/** The Gleefy crew: four round party characters, one per brand colour. Decorative only. */
const members = [
  { fill: 'var(--mm-option-a)', mouth: 'grin', tilt: -8, hat: true },
  { fill: 'var(--mm-option-b)', mouth: 'oh', tilt: 6, hat: false },
  { fill: 'var(--mm-accent)', mouth: 'grin', tilt: -4, hat: false },
  { fill: 'var(--mm-primary)', mouth: 'smile', tilt: 8, hat: true },
] as const;

export function Crew({ className = '' }: { className?: string }) {
  return (
    <div aria-hidden="true" className={`flex items-end ${className}`}>
      {members.map((m, i) => (
        <svg
          key={i}
          viewBox="0 0 64 72"
          className="wiggle -mx-1 size-14 sm:size-16"
          style={{ transform: `rotate(${m.tilt}deg)` }}
        >
          {m.hat && (
            <path
              d="M24 16 32 0l8 16z"
              fill="var(--mm-accent)"
              stroke="#1d1530"
              strokeWidth="3"
              strokeLinejoin="round"
            />
          )}
          <circle cx="32" cy="42" r="26" fill={m.fill} stroke="#1d1530" strokeWidth="3" />
          <ellipse cx="23" cy="38" rx="5" ry="6" fill="#fff" />
          <ellipse cx="41" cy="38" rx="5" ry="6" fill="#fff" />
          <circle cx="24" cy="39" r="2.6" fill="#1d1530" />
          <circle cx="42" cy="39" r="2.6" fill="#1d1530" />
          {m.mouth === 'grin' && <path d="M21 50q11 10 22 0z" fill="#1d1530" />}
          {m.mouth === 'smile' && (
            <path
              d="M22 50q10 7 20 0"
              fill="none"
              stroke="#1d1530"
              strokeWidth="3"
              strokeLinecap="round"
            />
          )}
          {m.mouth === 'oh' && <ellipse cx="32" cy="53" rx="4" ry="5" fill="#1d1530" />}
        </svg>
      ))}
    </div>
  );
}
