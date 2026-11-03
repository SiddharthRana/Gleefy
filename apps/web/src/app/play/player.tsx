'use client';

import {
  buildPool,
  createGuessSession,
  createTriviaSession,
  createWyrSession,
  decodeShare,
  encodeShare,
  guessResults,
  newSeed,
  pointsFor,
  reduceGuess,
  reduceTrivia,
  reduceWyr,
  triviaResults,
  wyrResults,
  type GuessState,
  type SharedGame,
  type ShareMode,
  type TriviaState,
  type WyrState,
} from '@mirthmix/game-engine';
import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { freeCategories, modeNames, packs, playableCategories } from '@/lib/packs';
import { usePremium } from '@/lib/premium';
import { Confetti } from '@/components/confetti';
import { primary, secondary } from '@/lib/ui';

/** Setup when there's no `?c=`, otherwise the game the link describes. */
export function Player() {
  const code = useSearchParams().get('c');
  const game = useMemo(() => (code ? decodeShare(code) : null), [code]);
  const premium = usePremium();
  if (code && !game) {
    return (
      <p role="alert" className="py-8 text-lg">
        This game link is broken or out of date. Pick a game below to start a new one.
      </p>
    );
  }
  if (!game) return <Setup />;
  const needsPremium = game.categoryIds.some(
    (id) => packs[game.mode].categories.find((c) => c.id === id)?.tier === 'premium',
  );
  // Deal only once we know whether premium categories can be played, so the game never re-deals.
  if (needsPremium && premium === null) return <p className="py-8 text-lg">Checking Premium…</p>;
  return <Game key={code} game={game} code={code!} premium={premium === true} />;
}

/** The new-game form. Also the static fallback while the URL is read, so nothing shifts on load. */
export function Setup() {
  const router = useRouter();
  const premium = usePremium() === true;
  const [mode, setMode] = useState<ShareMode>('would-you-rather');
  const [rounds, setRounds] = useState(10);
  const [selected, setSelected] = useState<string[]>(() => freeCategories(mode).map((c) => c.id));

  const pick = (m: ShareMode) => {
    setMode(m);
    setSelected(freeCategories(m).map((c) => c.id));
  };

  return (
    <form
      className="grid gap-8"
      onSubmit={(e) => {
        e.preventDefault();
        const code = encodeShare({
          mode,
          categoryIds: selected,
          rounds,
          seed: newSeed(),
          timeLimitMs: 0,
        });
        router.push(`/play?c=${code}`);
      }}
    >
      <fieldset>
        <legend className="font-display text-2xl font-semibold">Game</legend>
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          {(Object.keys(modeNames) as ShareMode[]).map((m) => (
            <label
              key={m}
              className="tile flex min-h-12 items-center gap-3 rounded-card border-2 border-border bg-surface px-4"
            >
              <input
                type="radio"
                name="mode"
                checked={mode === m}
                onChange={() => pick(m)}
                className="size-5"
              />
              <span className="font-bold">{modeNames[m]}</span>
            </label>
          ))}
        </div>
      </fieldset>
      <fieldset>
        <legend className="font-display text-2xl font-semibold">Categories</legend>
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          {packs[mode].categories.map((c) => (
            <label
              key={c.id}
              className="tile flex min-h-12 items-center gap-3 rounded-card border-2 border-border bg-surface px-4"
            >
              <input
                type="checkbox"
                className="size-5"
                disabled={c.tier === 'premium' && !premium}
                checked={selected.includes(c.id)}
                onChange={(e) =>
                  setSelected((s) =>
                    e.target.checked ? [...s, c.id] : s.filter((x) => x !== c.id),
                  )
                }
              />
              <span>
                <span className="font-bold">{c.name}</span>
                {c.region === 'in' && <span className="text-muted"> · India</span>}
                {c.tier === 'premium' && <span className="text-muted"> · Premium</span>}
              </span>
            </label>
          ))}
        </div>
        {!premium && (
          <p className="mt-3 text-muted">
            Premium categories unlock with{' '}
            <Link href="/pricing" className="font-bold text-primary underline">
              MirthMix Premium
            </Link>
            .
          </p>
        )}
      </fieldset>
      <fieldset>
        <legend className="font-display text-2xl font-semibold">Rounds</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {[5, 10, 15, 20].map((r) => (
            <label
              key={r}
              className="tile flex min-h-12 items-center gap-2 rounded-full border-2 border-border bg-surface px-5"
            >
              <input
                type="radio"
                name="rounds"
                checked={rounds === r}
                onChange={() => setRounds(r)}
              />
              {r}
            </label>
          ))}
        </div>
      </fieldset>
      <button
        type="submit"
        className={`${primary} brand-gradient justify-self-start text-lg`}
        disabled={!selected.length}
      >
        Start game
      </button>
    </form>
  );
}

type AnyState =
  | { mode: 'would-you-rather' | 'this-or-that'; s: WyrState }
  | { mode: 'trivia'; s: TriviaState }
  | { mode: 'guess'; s: GuessState };

function start(game: SharedGame, premium: boolean): AnyState | null {
  const pack = packs[game.mode];
  const playable = new Set(playableCategories(game.mode, premium).map((c) => c.id));
  const ids = game.categoryIds.filter((id) => playable.has(id));
  const pool = buildPool(pack.items as { id: string; category: string }[], ids);
  if (!pool.length) return null;
  const cfg = { categoryIds: ids, rounds: game.rounds, seed: game.seed };
  switch (game.mode) {
    case 'would-you-rather':
    case 'this-or-that':
      return { mode: game.mode, s: createWyrSession(pool, cfg) };
    case 'trivia':
      return {
        mode: 'trivia',
        s: createTriviaSession(buildPool(packs.trivia.items, ids), {
          ...cfg,
          teams: 1,
          timeLimitMs: game.timeLimitMs ?? 0,
        }),
      };
    case 'guess':
      return { mode: 'guess', s: createGuessSession(pool, { ...cfg, teams: 1 }) };
  }
}

function Game({ game, code, premium }: { game: SharedGame; code: string; premium: boolean }) {
  const [state, setState] = useState<AnyState | null>(() => start(game, premium));
  const [copied, setCopied] = useState(false);
  const skipped = premium
    ? []
    : packs[game.mode].categories.filter(
        (c) => c.tier === 'premium' && game.categoryIds.includes(c.id),
      );
  if (!state) {
    return (
      <p role="alert" className="py-8 text-lg">
        {skipped.length ? (
          <>
            This game only uses Premium categories.{' '}
            <Link href="/pricing" className="font-bold text-primary underline">
              See Premium
            </Link>{' '}
            or pick a game below.
          </>
        ) : (
          'No questions are available for this game.'
        )}
      </p>
    );
  }

  const share = async () => {
    const url = `${window.location.origin}/play?c=${code}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
    } catch {
      window.prompt('Copy this link', url);
    }
  };

  const s = state.s;
  const done = s.status === 'finished';
  const round = done ? s.rounds.length : s.rounds.length + 1;

  return (
    <div className="grid gap-6">
      {skipped.length > 0 && (
        <p role="note" className="rounded-card bg-surface-muted p-4">
          This link includes Premium categories ({skipped.map((c) => c.name).join(', ')}), so
          they’re left out.{' '}
          <Link href="/pricing" className="font-bold text-primary underline">
            See Premium
          </Link>
        </p>
      )}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="font-bold text-muted" aria-live="polite">
          {modeNames[game.mode]} · {done ? 'Finished' : `Round ${round} of ${s.totalRounds}`}
        </p>
        <button type="button" onClick={share} className={secondary}>
          {copied ? 'Link copied' : 'Share this game'}
        </button>
      </div>
      <progress
        className="h-2 w-full accent-[var(--mm-primary)]"
        max={s.totalRounds}
        value={s.rounds.length}
        aria-label="Progress"
      />
      {state.mode === 'trivia' ? (
        <TriviaView s={state.s} set={(n) => setState({ mode: 'trivia', s: n })} />
      ) : state.mode === 'guess' ? (
        <GuessView s={state.s} set={(n) => setState({ mode: 'guess', s: n })} />
      ) : (
        <ChoiceView
          mode={state.mode}
          s={state.s}
          set={(n) => setState({ mode: state.mode, s: n })}
        />
      )}
      {done && (
        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            className={primary}
            onClick={() => setState(start({ ...game, seed: newSeed() }, premium))}
          >
            Play again
          </button>
          <a href="/play" className={`${secondary} inline-flex items-center`}>
            New game
          </a>
        </div>
      )}
    </div>
  );
}

function ChoiceView({
  mode,
  s,
  set,
}: {
  mode: 'would-you-rather' | 'this-or-that';
  s: WyrState;
  set: (s: WyrState) => void;
}) {
  const pack = packs[mode];
  const act = (a: Parameters<typeof reduceWyr>[1]) => set(reduceWyr(s, a));
  if (s.status === 'finished') {
    const r = wyrResults(s);
    const text = (id: string | null) => {
      const q = id ? pack.items.find((i) => i.id === id) : null;
      return q ? `${q.a} / ${q.b}` : null;
    };
    return (
      <section
        aria-labelledby="results"
        className="pop-big relative rounded-panel border border-border bg-surface p-6"
      >
        <Confetti />
        <h2 id="results" className="font-display text-3xl font-semibold">
          Results
        </h2>
        <p className="mt-2">
          {r.roundsPlayed} rounds · {r.totalVotes} votes
        </p>
        {text(r.mostDivisive) && <p className="mt-3">Most divisive: {text(r.mostDivisive)}</p>}
        {text(r.mostUnanimous) && <p className="mt-1">Most unanimous: {text(r.mostUnanimous)}</p>}
      </section>
    );
  }
  const cur = s.current!;
  const q = pack.items.find((i) => i.id === cur.questionId)!;
  const a = cur.votes.filter((v) => v === 'a').length;
  const b = cur.votes.length - a;
  const pct = (n: number) => (cur.votes.length ? Math.round((100 * n) / cur.votes.length) : 0);
  const rapid = mode === 'this-or-that';
  return (
    <section key={cur.questionId} aria-label="Question" className="pop grid gap-4">
      <h2 className="text-center font-display text-3xl font-semibold">
        {rapid ? 'This or that?' : 'Would you rather…'}
      </h2>
      <p className="text-center text-muted">
        {rapid ? "Tap the room's pick." : 'Raise hands, then tap a side once for each vote.'}
      </p>
      {(['a', 'b'] as const).map((side) => (
        <button
          key={side}
          type="button"
          disabled={cur.revealed}
          onClick={() => {
            const voted = reduceWyr(s, { type: 'vote', side });
            set(rapid ? reduceWyr(voted, { type: 'reveal' }) : voted);
          }}
          style={{ '--tilt': side === 'a' ? '-0.5deg' : '0.5deg' } as React.CSSProperties}
          className={`choice flex min-h-24 items-center justify-between gap-4 rounded-panel px-6 py-4 text-left font-display text-2xl font-semibold text-on-option ${side === 'a' ? 'bg-option-a' : 'bg-option-b'}`}
        >
          {/* After the reveal, a bar fills to each side's share of the votes. */}
          <span
            className="fill"
            style={{ width: cur.revealed ? `${pct(side === 'a' ? a : b)}%` : '0%' }}
          />
          <span className="relative">{q[side]}</span>
          {/* Keyed by the number, so it bumps every time a vote lands or the split appears. */}
          <span
            key={cur.revealed ? `pct-${side}` : `${side}-${side === 'a' ? a : b}`}
            className="bump relative rounded-full bg-surface px-3 py-1 text-lg text-text"
          >
            {cur.revealed ? `${pct(side === 'a' ? a : b)}%` : side === 'a' ? a : b}
          </span>
        </button>
      ))}
      <div className="flex flex-wrap gap-3">
        {!cur.revealed && (
          <>
            {!rapid && (
              <button
                type="button"
                className={secondary}
                disabled={!cur.votes.length}
                onClick={() => act({ type: 'undo' })}
              >
                Undo
              </button>
            )}
            <button type="button" className={secondary} onClick={() => act({ type: 'skip' })}>
              Skip
            </button>
            {!rapid && (
              <button type="button" className={primary} onClick={() => act({ type: 'reveal' })}>
                Reveal
              </button>
            )}
          </>
        )}
        {cur.revealed && (
          <button type="button" className={primary} onClick={() => act({ type: 'next' })}>
            {s.rounds.length + 1 >= s.totalRounds ? 'See results' : 'Next round'}
          </button>
        )}
      </div>
    </section>
  );
}

function TriviaView({ s, set }: { s: TriviaState; set: (s: TriviaState) => void }) {
  const startedAt = useRef(0);
  const cur = s.current;
  useEffect(() => {
    startedAt.current = performance.now();
  }, [cur?.questionId]);
  if (s.status === 'finished') {
    const r = triviaResults(s);
    return (
      <section
        aria-labelledby="results"
        className="pop-big relative rounded-panel border border-border bg-surface p-6"
      >
        <Confetti />
        <h2 id="results" className="font-display text-3xl font-semibold">
          Results
        </h2>
        <p className="mt-2 text-xl font-bold">
          {r.correct} of {r.played} correct · {s.scores[0]} points
        </p>
      </section>
    );
  }
  const q = packs.trivia.items.find((i) => i.id === cur!.questionId)!;
  const answered = cur!.picked !== null || cur!.timedOut;
  return (
    <section key={cur!.questionId} aria-label="Question" className="pop grid gap-3">
      <h2 className="text-center font-display text-3xl font-semibold">{q.question}</h2>
      {cur!.choiceOrder.map((index, pos) => {
        const mark = !answered
          ? ''
          : index === cur!.answer
            ? ' ✓'
            : index === cur!.picked
              ? ' ✗'
              : '';
        return (
          <button
            key={index}
            type="button"
            disabled={answered}
            onClick={() =>
              set(
                reduceTrivia(s, {
                  type: 'answer',
                  choice: pos,
                  elapsedMs: performance.now() - startedAt.current,
                }),
              )
            }
            className={`press min-h-14 rounded-card border-2 bg-surface px-5 text-left text-lg font-bold ${
              answered && index === cur!.answer
                ? 'correct border-[var(--mm-success)]'
                : 'border-border'
            } ${answered && index === cur!.picked && index !== cur!.answer ? 'wrong' : ''}`}
          >
            {'ABCD'[pos]}. {q.choices[index]}
            {mark}
          </button>
        );
      })}
      {answered && (
        <div aria-live="polite" className="grid gap-2">
          <p className="pop-big text-xl font-bold">
            {cur!.picked === cur!.answer
              ? `Correct! +${cur!.points}`
              : `Not quite. Answer: ${q.choices[cur!.answer]}`}
          </p>
          <p className="text-muted">{q.explanation}</p>
        </div>
      )}
      <div className="flex gap-3">
        {!answered && (
          <button
            type="button"
            className={secondary}
            onClick={() => set(reduceTrivia(s, { type: 'skip' }))}
          >
            Skip
          </button>
        )}
        {answered && (
          <button
            type="button"
            className={primary}
            onClick={() => set(reduceTrivia(s, { type: 'next' }))}
          >
            {s.rounds.length + 1 >= s.totalRounds ? 'See results' : 'Next round'}
          </button>
        )}
      </div>
    </section>
  );
}

function GuessView({ s, set }: { s: GuessState; set: (s: GuessState) => void }) {
  if (s.status === 'finished') {
    const r = guessResults(s);
    return (
      <section
        aria-labelledby="results"
        className="pop-big relative rounded-panel border border-border bg-surface p-6"
      >
        <Confetti />
        <h2 id="results" className="font-display text-3xl font-semibold">
          Results
        </h2>
        <p className="mt-2 text-xl font-bold">
          {r.solved} of {r.played} guessed · {s.scores[0]} points
        </p>
      </section>
    );
  }
  const cur = s.current!;
  const q = packs.guess.items.find((i) => i.id === cur.questionId)!;
  const act = (type: 'clue' | 'got' | 'reveal' | 'next' | 'skip') => set(reduceGuess(s, { type }));
  return (
    <section key={cur.questionId} aria-label="Card" className="pop relative grid gap-3">
      {cur.outcome === 'got' && <Confetti pieces={24} seed={cur.cluesShown} />}
      <div className="rounded-card bg-surface-muted p-4 text-center">
        <p className="text-sm">Reader only — the answer is</p>
        <p className="font-display text-3xl font-semibold">{q.answer}</p>
      </div>
      {q.clues.slice(0, cur.cluesShown).map((clue, i) => (
        <div key={clue} className="flip-in rounded-card border border-border bg-surface p-4">
          <p className="text-sm font-bold text-muted">Clue {i + 1}</p>
          <p className="text-xl">{clue}</p>
        </div>
      ))}
      <p
        key={`${cur.questionId}-${cur.outcome ?? cur.cluesShown}`}
        aria-live="polite"
        className={`font-bold ${cur.outcome === 'got' ? 'pop-big text-2xl' : 'pop'}`}
      >
        {cur.outcome === 'got'
          ? `+${pointsFor(cur.cluesShown)} points`
          : cur.outcome === 'revealed'
            ? 'No points this time.'
            : `Worth ${pointsFor(cur.cluesShown)} points`}
      </p>
      <div className="flex flex-wrap gap-3">
        {!cur.outcome ? (
          <>
            <button type="button" className={primary} onClick={() => act('got')}>
              Got it!
            </button>
            <button
              type="button"
              className={secondary}
              disabled={cur.cluesShown >= 3}
              onClick={() => act('clue')}
            >
              Next clue
            </button>
            <button type="button" className={secondary} onClick={() => act('reveal')}>
              Give up
            </button>
            <button type="button" className={secondary} onClick={() => act('skip')}>
              Skip
            </button>
          </>
        ) : (
          <button type="button" className={primary} onClick={() => act('next')}>
            {s.rounds.length + 1 >= s.totalRounds ? 'See results' : 'Next round'}
          </button>
        )}
      </div>
    </section>
  );
}
