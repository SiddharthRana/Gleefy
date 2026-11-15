'use client';

import Link from 'next/link';
import { useState } from 'react';
import {
  createDreamTeam,
  DeckTooSmallError,
  dreamTeamResults,
  newSeed,
  reduceDreamTeam,
  type DreamTeamAction,
  type DreamTeamCard,
  type DreamTeamState,
  type DreamTeamVerdict,
} from '@gleefy/game-engine';
import { Confetti } from '@/components/confetti';
import { RewardPanel } from '@/components/reward-panel';
import {
  blurbs,
  customCards,
  customDeckMax,
  deckCards,
  deckProblem,
  dreamTeam,
  dreamTeamSkips,
  minCustomCards,
  parseDeckNames,
  readCustomDecks,
  writeCustomDecks,
  type CustomDeck,
} from '@/lib/dream-team';
import { usePremium } from '@/lib/premium';
import { recordFinishedGame } from '@/lib/progress';
import { field, primary, secondary } from '@/lib/ui';
import type { GameReward } from '@gleefy/game-engine';

interface Game {
  sides: [string, string];
  roleNames: string[];
  cards: Map<string, DreamTeamCard>;
  state: DreamTeamState;
  /** For "Draft again": the same deck and roles, a fresh shuffle. */
  setup: { cards: DreamTeamCard[]; roleSetId: string };
}

const roleSet = (id: string) => dreamTeam.roleSets.find((r) => r.id === id)!;

function newGame(cards: DreamTeamCard[], roleSetId: string, sides: [string, string]): Game {
  const set = roleSet(roleSetId);
  return {
    sides,
    roleNames: set.roles.map((r) => r.name),
    cards: new Map(cards.map((c) => [c.id, c])),
    state: createDreamTeam(
      cards.map((c) => c.id),
      {
        roles: set.roles.map(({ id, stat }) => ({ id, stat })),
        seed: newSeed(),
        skips: dreamTeamSkips,
      },
    ),
    setup: { cards, roleSetId },
  };
}

/** Dream Team in the browser: setup, the blind draft, the room's vote and the verdict. */
export function DreamTeamPlayer() {
  const [game, setGame] = useState<Game | null>(null);
  const [reward, setReward] = useState<GameReward | null>(null);

  if (!game) return <DreamTeamSetup onStart={setGame} />;

  const act = (action: DreamTeamAction) => {
    const next = reduceDreamTeam(game.state, action);
    if (next === game.state) return;
    if (next.status === 'finished') {
      setReward(recordFinishedGame({ mode: 'dream-team', rounds: game.roleNames.length * 2 }));
    }
    setGame({ ...game, state: next });
  };

  if (game.state.status === 'drafting')
    return <Draft key={game.state.order[0]} game={game} act={act} />;
  if (game.state.status === 'voting') return <Vote game={game} act={act} />;
  return (
    <Verdict
      game={game}
      reward={reward}
      onAgain={() => {
        setReward(null);
        setGame(newGame(game.setup.cards, game.setup.roleSetId, game.sides));
      }}
    />
  );
}

function DreamTeamSetup({ onStart }: { onStart: (g: Game) => void }) {
  const premium = usePremium() === true;
  const [deckId, setDeckId] = useState(dreamTeam.categories.find((c) => c.tier === 'free')!.id);
  const [roleSetId, setRoleSetId] = useState(dreamTeam.roleSets[0]!.id);
  const [names, setNames] = useState(['', '']);
  const [decks, setDecks] = useState<CustomDeck[]>(() =>
    typeof window === 'undefined' ? [] : readCustomDecks(),
  );
  const [editing, setEditing] = useState<CustomDeck | 'new' | null>(null);
  const [error, setError] = useState<string | null>(null);

  const start = () => {
    const custom = decks.find((d) => d.id === deckId);
    const bundled = dreamTeam.categories.find((c) => c.id === deckId);
    if ((custom || bundled?.tier === 'premium') && !premium) {
      setError('That deck is part of Premium.');
      return;
    }
    const sides: [string, string] = [
      names[0]!.trim() || 'Player 1',
      names[1]!.trim() || 'Player 2',
    ];
    try {
      onStart(newGame(custom ? customCards(custom) : deckCards(deckId), roleSetId, sides));
    } catch (e) {
      setError(
        e instanceof DeckTooSmallError
          ? `Add at least ${e.needed} cards, so both teams can fill every role.`
          : 'Something went wrong. Please try again.',
      );
    }
  };

  if (editing) {
    return (
      <DeckEditor
        deck={editing === 'new' ? null : editing}
        onDone={(next) => {
          if (next) {
            setDecks(next);
            writeCustomDecks(next);
          }
          setEditing(null);
        }}
        decks={decks}
      />
    );
  }

  const deckOption = (id: string, title: string, detail: string, locked: boolean) => (
    <label
      key={id}
      className={`tile flex min-h-12 cursor-pointer items-center gap-3 rounded-card border-2 bg-surface px-4 py-3 ${
        deckId === id ? 'border-primary' : 'border-border'
      } ${locked ? 'opacity-70' : ''}`}
    >
      <input
        type="radio"
        name="deck"
        className="size-5"
        checked={deckId === id}
        disabled={locked}
        onChange={() => setDeckId(id)}
      />
      <span>
        <span className="font-bold">{title}</span>
        <span className="block text-sm text-muted">
          {detail}
          {locked && ' · Premium'}
        </span>
      </span>
    </label>
  );

  return (
    <div className="grid gap-8">
      <fieldset>
        <legend className="font-display text-2xl font-semibold">Deck</legend>
        <div className="mt-3 grid gap-2">
          {dreamTeam.categories.map((c) =>
            deckOption(
              c.id,
              c.name,
              `${c.description} · ${dreamTeam.items.filter((i) => i.category === c.id).length} cards`,
              c.tier === 'premium' && !premium,
            ),
          )}
          {decks.map((d) =>
            deckOption(d.id, d.name, `${d.cards.length} cards · room vote only`, !premium),
          )}
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          {premium ? (
            <>
              <button type="button" className={secondary} onClick={() => setEditing('new')}>
                + Make your own deck
              </button>
              {decks.some((d) => d.id === deckId) && (
                <button
                  type="button"
                  className="font-bold text-primary underline"
                  onClick={() => setEditing(decks.find((d) => d.id === deckId)!)}
                >
                  Edit this deck
                </button>
              )}
            </>
          ) : (
            <p className="text-muted">
              Make your own decks with any characters you like, with{' '}
              <Link href="/pricing" className="font-bold text-primary underline">
                Gleefy Premium
              </Link>
              .
            </p>
          )}
        </div>
      </fieldset>

      <fieldset>
        <legend className="font-display text-2xl font-semibold">Roles</legend>
        <div className="mt-3 flex flex-wrap gap-2">
          {dreamTeam.roleSets.map((r) => (
            <label
              key={r.id}
              className={`cursor-pointer rounded-full border-2 px-4 py-2 font-bold ${
                roleSetId === r.id ? 'border-primary bg-primary text-on-primary' : 'border-border'
              }`}
            >
              <input
                type="radio"
                name="roles"
                className="sr-only"
                checked={roleSetId === r.id}
                onChange={() => setRoleSetId(r.id)}
              />
              {r.name}
            </label>
          ))}
        </div>
        <p className="mt-2 text-muted">
          {roleSet(roleSetId)
            .roles.map((r) => r.name)
            .join(' · ')}
        </p>
      </fieldset>

      <fieldset>
        <legend className="font-display text-2xl font-semibold">Who’s playing</legend>
        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          {[0, 1].map((i) => (
            <label key={i} className="flex flex-col gap-1 font-bold">
              Side {i + 1}
              <input
                className={field}
                maxLength={20}
                placeholder={`Player ${i + 1}`}
                value={names[i]}
                onChange={(e) => setNames((n) => n.map((x, j) => (j === i ? e.target.value : x)))}
              />
            </label>
          ))}
        </div>
      </fieldset>

      {error && (
        <p role="alert" className="font-bold">
          {error}
        </p>
      )}
      <button type="button" className={primary} onClick={start}>
        Start the draft
      </button>
    </div>
  );
}

function DeckEditor({
  deck,
  decks,
  onDone,
}: {
  deck: CustomDeck | null;
  decks: CustomDeck[];
  onDone: (next: CustomDeck[] | null) => void;
}) {
  const [title, setTitle] = useState(deck?.name ?? '');
  const [text, setText] = useState(deck?.cards.join('\n') ?? '');
  const [error, setError] = useState<string | null>(null);
  const names = parseDeckNames(text);

  const save = () => {
    const problem = deckProblem(title, names);
    if (problem) {
      setError(problem);
      return;
    }
    const saved: CustomDeck = {
      id: deck?.id ?? `mine-${Math.random().toString(36).slice(2, 10)}`,
      name: title.trim().replace(/\s+/g, ' '),
      cards: names,
    };
    onDone(deck ? decks.map((d) => (d.id === deck.id ? saved : d)) : [...decks, saved]);
  };

  return (
    <div className="grid gap-4">
      <h2 className="font-display text-3xl font-semibold">{deck ? 'Edit deck' : 'New deck'}</h2>
      <label className="flex flex-col gap-1 font-bold">
        Deck name
        <input
          className={field}
          maxLength={30}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
      </label>
      <label className="flex flex-col gap-1 font-bold">
        Cards, one per line
        <textarea
          className={`${field} min-h-64`}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={'Each line is one card, e.g. a character’s name.'}
        />
      </label>
      <p
        className={
          names.length < minCustomCards || names.length > customDeckMax ? 'font-bold' : 'text-muted'
        }
      >
        {names.length} cards (at least {minCustomCards}, up to {customDeckMax})
      </p>
      {error && (
        <p role="alert" className="font-bold">
          {error}
        </p>
      )}
      <p className="text-sm text-muted">Your decks stay in this browser.</p>
      <div className="flex flex-wrap gap-3">
        <button type="button" className={primary} onClick={save}>
          Save deck
        </button>
        <button type="button" className={secondary} onClick={() => onDone(null)}>
          Cancel
        </button>
        {deck && (
          <button
            type="button"
            className="font-bold underline"
            onClick={() => {
              if (window.confirm(`Delete “${deck.name}”? This can’t be undone.`)) {
                onDone(decks.filter((d) => d.id !== deck.id));
              }
            }}
          >
            Delete deck
          </button>
        )}
      </div>
    </div>
  );
}

function Draft({ game, act }: { game: Game; act: (a: DreamTeamAction) => void }) {
  const [flipped, setFlipped] = useState(false);
  const [handover, setHandover] = useState(false);
  const s = game.state;
  const side = s.turn;
  const name = game.sides[side];
  const card = s.drawn ? game.cards.get(s.drawn) : undefined;
  const placed = s.teams.flat().filter((c) => c !== null).length;
  const total = game.roleNames.length * 2;

  const place = (slot: number) => {
    const before = s.turn;
    act({ type: 'place', slot });
    setFlipped(false);
    // Hand the phone over only when the turn moves; the reducer decides that.
    const next = reduceDreamTeam(s, { type: 'place', slot });
    setHandover(next.status === 'drafting' && next.turn !== before);
  };

  if (handover) {
    return (
      <div className="grid justify-items-center gap-4 rounded-panel bg-surface p-8 text-center">
        <p className="text-muted">
          {placed} of {total} picked
        </p>
        <h2 className="font-display text-3xl font-semibold">Pass the phone to {name}</h2>
        <p className="text-muted">Don’t peek at the next card!</p>
        <button type="button" className={primary} onClick={() => setHandover(false)}>
          I’m {name}
        </button>
      </div>
    );
  }

  return (
    <div className="grid gap-5">
      <p className="text-center text-muted" role="status">
        {placed} of {total} picked
      </p>
      <h2 className="text-center font-display text-3xl font-semibold">{name}’s pick</h2>
      {card &&
        (flipped ? (
          <div
            key={card.id}
            className="flip-in grid min-h-44 place-items-center rounded-panel border-4 border-primary bg-surface p-5 text-center"
          >
            <div>
              <p className="font-display text-3xl font-semibold">{card.name}</p>
              {blurbs.get(card.id) && <p className="mt-2 text-muted">{blurbs.get(card.id)}</p>}
            </div>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => setFlipped(true)}
            className="brand-gradient grid min-h-44 place-items-center rounded-panel p-5 text-white"
          >
            <span>
              <span aria-hidden="true" className="block text-6xl font-extrabold">
                ?
              </span>
              <span className="font-bold">Tap to flip</span>
            </span>
          </button>
        ))}
      <p className="text-center text-muted">
        {flipped ? 'Tap an empty role to lock it in.' : 'Flip the card first.'}
      </p>
      <Slots game={game} side={side} onPlace={flipped ? place : undefined} title="Your team" />
      <details>
        <summary className="cursor-pointer font-bold">
          {game.sides[side === 0 ? 1 : 0]}’s team
        </summary>
        <div className="mt-3">
          <Slots game={game} side={side === 0 ? 1 : 0} />
        </div>
      </details>
      <button
        type="button"
        className={secondary}
        disabled={!flipped || s.skipsLeft[side] < 1}
        onClick={() => {
          act({ type: 'skip' });
          setFlipped(false);
        }}
      >
        {s.skipsLeft[side] > 0 ? `Skip (${s.skipsLeft[side]} left)` : 'No skips left'}
      </button>
    </div>
  );
}

function Slots({
  game,
  side,
  onPlace,
  title,
}: {
  game: Game;
  side: 0 | 1;
  onPlace?: (slot: number) => void;
  title?: string;
}) {
  const team = game.state.teams[side];
  return (
    <div className="grid gap-2">
      {title && <h3 className="font-display text-xl font-semibold">{title}</h3>}
      {game.roleNames.map((role, i) => {
        const id = team[i];
        const open = id === null && onPlace;
        const content = (
          <>
            <span className="w-32 shrink-0 font-bold">{role}</span>
            <span className={id ? 'font-bold' : 'text-muted'}>
              {id ? game.cards.get(id)?.name : 'Empty'}
            </span>
            {open && (
              <span aria-hidden="true" className="ml-auto text-xl text-primary">
                ⊕
              </span>
            )}
          </>
        );
        return open ? (
          <button
            key={role}
            type="button"
            onClick={() => onPlace(i)}
            className="flex min-h-12 items-center gap-3 rounded-card border-2 border-primary bg-surface px-4 text-left"
          >
            {content}
          </button>
        ) : (
          <div
            key={role}
            className="flex min-h-12 items-center gap-3 rounded-card bg-surface-muted px-4"
          >
            {content}
          </div>
        );
      })}
    </div>
  );
}

function Vote({ game, act }: { game: Game; act: (a: DreamTeamAction) => void }) {
  const s = game.state;
  const next = s.votes.findIndex((v) => v === null);
  const done = next === -1;
  const slot = done ? s.votes.length - 1 : next;
  const role = game.roleNames[slot]!;
  return (
    <div className="grid gap-5">
      <p className="text-center text-muted" role="status">
        Role {slot + 1} of {game.roleNames.length}
      </p>
      <h2 className="text-center font-display text-3xl font-semibold">Who wins {role}?</h2>
      <p className="text-center text-muted">The room decides. Tap the winner.</p>
      {([0, 1] as const).map((side) => {
        const card = game.cards.get(s.teams[side][slot]!)!;
        return (
          <button
            key={`${slot}-${side}`}
            type="button"
            aria-pressed={s.votes[slot] === side}
            onClick={() => act({ type: 'vote', slot, side })}
            className={`press grid min-h-32 place-items-center rounded-panel p-5 text-center text-white ${
              side === 0 ? 'bg-option-a' : 'bg-option-b'
            }`}
          >
            <span>
              <span className="block font-bold">{game.sides[side]}</span>
              <span className="block font-display text-2xl font-semibold">{card.name}</span>
              {blurbs.get(card.id) && <span className="block">{blurbs.get(card.id)}</span>}
              {s.votes[slot] === side && <span className="block font-bold">✓ Picked</span>}
            </span>
          </button>
        );
      })}
      <button
        type="button"
        className={primary}
        disabled={!done}
        onClick={() => act({ type: 'finish' })}
      >
        See the verdict
      </button>
    </div>
  );
}

function Verdict({
  game,
  reward,
  onAgain,
}: {
  game: Game;
  reward: GameReward | null;
  onAgain: () => void;
}) {
  const r = dreamTeamResults(game.state, game.cards);
  const say = (v: DreamTeamVerdict, who: string) =>
    v.winner === null
      ? `${who}: it’s a tie, ${v.scores[0]}–${v.scores[1]}`
      : `${who}: ${game.sides[v.winner]} wins ${v.scores[v.winner]}–${v.scores[v.winner === 0 ? 1 : 0]}`;
  return (
    <div className="relative grid gap-5">
      <Confetti />
      <h2 className="text-center font-display text-3xl font-semibold">
        {say(r.room, 'The room says')}
      </h2>
      <div className="rounded-card border border-border bg-surface p-5 text-center">
        {r.stats ? (
          <>
            <p className="text-lg font-bold">{say(r.stats, 'The stats say')}</p>
            <p className="mt-1 text-muted">
              {r.stats.winner === r.room.winner
                ? 'The room and the stats agree!'
                : 'The room and the stats disagree. Argue it out.'}
            </p>
          </>
        ) : (
          <p>Custom decks have no stats, so the room’s word is final.</p>
        )}
      </div>
      <ul className="grid gap-3">
        {game.roleNames.map((role, i) => (
          <li key={role} className="rounded-card border border-border bg-surface p-4">
            <p className="font-bold text-muted">{role}</p>
            {([0, 1] as const).map((side) => (
              <p key={side} className="flex items-center gap-2">
                <span aria-hidden="true">{game.state.votes[i] === side ? '🏆' : '○'}</span>
                <span className={game.state.votes[i] === side ? 'font-bold' : ''}>
                  {game.sides[side]}: {game.cards.get(game.state.teams[side][i]!)?.name}
                </span>
                {r.slotStats[i] && (
                  <span className="ml-auto font-bold">{r.slotStats[i]![side]}</span>
                )}
              </p>
            ))}
          </li>
        ))}
      </ul>
      {reward && <RewardPanel reward={reward} />}
      <div className="flex flex-wrap gap-3">
        <button type="button" className={primary} onClick={onAgain}>
          Draft again
        </button>
        <Link href="/games/dream-team" className={`${secondary} inline-flex items-center`}>
          How to play
        </Link>
      </div>
    </div>
  );
}
