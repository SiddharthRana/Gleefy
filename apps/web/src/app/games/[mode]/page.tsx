import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import type { ShareMode } from '@mirthmix/game-engine';
import { categoryCount, guide, guideHref, guides } from '@/lib/guides';
import { packs } from '@/lib/packs';
import { primary } from '@/lib/ui';

export const dynamicParams = false;

export function generateStaticParams() {
  return guides.map((g) => ({ mode: g.id }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ mode: string }>;
}): Promise<Metadata> {
  const g = guide((await params).mode);
  if (!g) return {};
  return { title: g.name, description: g.description, alternates: { canonical: guideHref(g.id) } };
}

/** A real item from the pack, shown the way the game shows it. */
function Sample({ mode }: { mode: ShareMode }) {
  if (mode === 'would-you-rather' || mode === 'this-or-that') {
    const pack = packs[mode];
    const free = pack.categories.find((c) => c.tier === 'free' && c.region === 'global');
    const item = pack.items.find((i) => i.category === free?.id) ?? pack.items[0]!;
    return (
      <figure className="mt-8 grid gap-3 sm:grid-cols-2" aria-label="Example question">
        <div className="rounded-panel bg-option-a p-6 font-display text-2xl font-semibold text-on-option">
          {item.a}
        </div>
        <div className="rounded-panel bg-option-b p-6 font-display text-2xl font-semibold text-on-option">
          {item.b}
        </div>
      </figure>
    );
  }
  if (mode === 'trivia') {
    const item = packs.trivia.items.find((i) => i.difficulty === 'easy') ?? packs.trivia.items[0]!;
    return (
      <figure
        className="mt-8 rounded-card border border-border bg-surface p-6"
        aria-label="Example question"
      >
        <p className="font-display text-2xl font-semibold">{item.question}</p>
        <ul className="mt-4 grid gap-2 sm:grid-cols-2">
          {/* Packs list the right answer first; sort so the sample doesn’t give it away. */}
          {[...item.choices].sort().map((c) => (
            <li key={c} className="rounded-card bg-surface-muted p-3 font-bold">
              {c}
            </li>
          ))}
        </ul>
      </figure>
    );
  }
  const item = packs.guess.items[0]!;
  return (
    <figure
      className="mt-8 rounded-card border border-border bg-surface p-6"
      aria-label="Example card"
    >
      <p className="font-bold text-muted">Clues, one at a time</p>
      <ol className="mt-2 list-decimal space-y-1 pl-6 text-lg">
        {item.clues.map((c) => (
          <li key={c}>{c}</li>
        ))}
      </ol>
      <details className="mt-4">
        <summary className="min-h-12 cursor-pointer font-bold">Show the answer</summary>
        <p className="font-display text-2xl font-semibold">{item.answer}</p>
      </details>
    </figure>
  );
}

export default async function ModeGuidePage({ params }: { params: Promise<{ mode: string }> }) {
  const g = guide((await params).mode);
  if (!g) notFound();
  const pack = g.pack ? packs[g.pack] : null;
  return (
    <div className="py-12">
      <p className="font-bold text-primary">Game guide</p>
      <h1 className="mt-1 font-display text-5xl font-bold">{g.name}</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">{g.intro}</p>
      {g.pack && <Sample mode={g.pack} />}
      {g.webPlayer && (
        <Link href="/play" className={`${primary} mt-8 inline-flex items-center`}>
          Play {g.name} in your browser
        </Link>
      )}

      <section aria-labelledby="rules" className="mt-12">
        <h2 id="rules" className="font-display text-3xl font-semibold">
          How to play
        </h2>
        <ol className="mt-4 list-decimal space-y-2 pl-6 text-lg">
          {g.rules.map((r) => (
            <li key={r}>{r}</li>
          ))}
        </ol>
      </section>

      {g.pack && pack && (
        <section aria-labelledby="categories" className="mt-12">
          <h2 id="categories" className="font-display text-3xl font-semibold">
            Categories
          </h2>
          <p className="mt-2 text-muted">
            {categoryCount(g.pack)} original {g.pack === 'guess' ? 'cards' : 'questions'} in{' '}
            {pack.categories.length} categories.
          </p>
          <ul className="mt-6 grid gap-4 sm:grid-cols-2">
            {pack.categories.map((c) => (
              <li key={c.id} className="rounded-card border border-border bg-surface p-5">
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="font-display text-2xl font-semibold">{c.name}</h3>
                  {c.tier === 'premium' && (
                    <span className="rounded-full bg-accent px-3 py-1 text-sm font-bold text-on-accent">
                      Premium
                    </span>
                  )}
                  {c.ageRating === '13+' && (
                    <span className="rounded-full bg-surface-muted px-3 py-1 text-sm font-bold">
                      13+
                    </span>
                  )}
                </div>
                <p className="mt-1 text-muted">{c.description}</p>
                {c.contentNote && <p className="mt-2 text-sm">Note: {c.contentNote}</p>}
                <p className="mt-2 text-sm font-bold">
                  {categoryCount(g.pack!, c.id)} {g.pack === 'guess' ? 'cards' : 'questions'}
                </p>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section aria-labelledby="tips" className="mt-12">
        <h2 id="tips" className="font-display text-3xl font-semibold">
          Tips for a great round
        </h2>
        <ul className="mt-4 list-disc space-y-2 pl-6 text-lg">
          {g.tips.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}
