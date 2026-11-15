import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  cardsNeeded,
  createDreamTeam,
  DeckTooSmallError,
  dreamTeamResults,
  reduceDreamTeam,
  type DreamTeamAction,
  type DreamTeamCard,
  type DreamTeamConfig,
} from '../src/dream-team.ts';

const roles: DreamTeamConfig['roles'] = [
  { id: 'captain', stat: 'lead' },
  { id: 'tank', stat: 'power' },
  { id: 'healer', stat: 'heart' },
];
const ids = Array.from({ length: 10 }, (_, i) => `c${i}`);

describe('Dream Team', () => {
  it('needs enough cards for every slot and skip', () => {
    expect(cardsNeeded(5, 1)).toBe(12);
    expect(() => createDreamTeam(ids.slice(0, 7), { roles, seed: 1, skips: 1 })).toThrow(
      DeckTooSmallError,
    );
    expect(() => createDreamTeam(ids.slice(0, 8), { roles, seed: 1, skips: 1 })).not.toThrow();
  });

  it('alternates sides, locks placed cards and ends in voting', () => {
    let s = createDreamTeam(ids, { roles, seed: 9, skips: 1 });
    const first = s.drawn;
    s = reduceDreamTeam(s, { type: 'place', slot: 1 });
    expect(s.teams[0][1]).toBe(first);
    expect(s.turn).toBe(1);
    // Side 1 can't place into side 0's slot, only its own; a filled slot is refused.
    s = reduceDreamTeam(s, { type: 'place', slot: 1 });
    const again = reduceDreamTeam(s, { type: 'place', slot: 1 });
    expect(again).toBe(s);
    for (const slot of [0, 0, 2, 2]) s = reduceDreamTeam(s, { type: 'place', slot });
    expect(s.status).toBe('voting');
    expect(s.drawn).toBeNull();
    expect(new Set([...s.teams[0], ...s.teams[1]]).size).toBe(6);
  });

  it('allows only the skips each side has', () => {
    let s = createDreamTeam(ids, { roles, seed: 3, skips: 1 });
    const first = s.drawn;
    s = reduceDreamTeam(s, { type: 'skip' });
    expect(s.drawn).not.toBe(first);
    expect(s.skipsLeft).toEqual([0, 1]);
    expect(reduceDreamTeam(s, { type: 'skip' })).toBe(s);
  });

  it('judges by the room and, with stats, by the numbers', () => {
    const cards: DreamTeamCard[] = ids.map((id, i) => ({
      id,
      name: id,
      stats: { lead: i + 1, power: 10 - i, smarts: 5, heart: 5, chaos: 5 },
    }));
    let s = createDreamTeam(ids, { roles, seed: 5, skips: 0 });
    for (const slot of [0, 0, 1, 1, 2, 2]) s = reduceDreamTeam(s, { type: 'place', slot });
    for (const slot of [0, 1, 2]) s = reduceDreamTeam(s, { type: 'vote', slot, side: 1 });
    s = reduceDreamTeam(s, { type: 'finish' });
    const r = dreamTeamResults(s, new Map(cards.map((c) => [c.id, c])));
    expect(r.room).toEqual({ scores: [0, 3], winner: 1 });
    expect(r.stats).not.toBeNull();
    const noStats = dreamTeamResults(s, new Map(ids.map((id) => [id, { id, name: id }])));
    expect(noStats.stats).toBeNull();
  });

  const vectors = JSON.parse(
    readFileSync(join(import.meta.dirname, '../test-vectors/dream-team.json'), 'utf8'),
  ) as {
    cards: DreamTeamCard[];
    scenarios: {
      name: string;
      custom: boolean;
      config: DreamTeamConfig;
      actions: DreamTeamAction[];
      expected: unknown;
    }[];
  };
  it.each(vectors.scenarios)('vector: $name', ({ custom, config, actions, expected }) => {
    const cards = custom ? vectors.cards.map(({ id, name }) => ({ id, name })) : vectors.cards;
    let s = createDreamTeam(
      cards.map((c) => c.id),
      config,
    );
    for (const a of actions) s = reduceDreamTeam(s, a);
    const { config: _c, ...state } = s;
    const results = dreamTeamResults(s, new Map(cards.map((c) => [c.id, c])));
    expect({ ...state, results }).toEqual(expected);
  });
});
