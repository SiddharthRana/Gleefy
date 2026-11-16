// Dream Team: a blind draft for two sides. Each turn a side flips a random card and must lock it
// into one of its empty role slots (Captain, Tank, …), with one skip per side. When both teams are
// full the room votes role by role, and the cards' hidden stats give a second, "stats" verdict.
// The Dart copy (apps/mobile/lib/game/dream_team_engine.dart) replays test-vectors/dream-team.json.
import { seededShuffle } from './random.ts';

export const DREAM_TEAM_STATS = ['lead', 'power', 'smarts', 'heart', 'chaos'] as const;
export type DreamTeamStat = (typeof DREAM_TEAM_STATS)[number];

export interface DreamTeamCard {
  id: string;
  name: string;
  /** 1–10 per stat. Custom decks have none, so they're judged by the room only. */
  stats?: Record<DreamTeamStat, number>;
}

export interface DreamTeamRole {
  id: string;
  /** The stat the stats verdict compares for this slot. */
  stat: DreamTeamStat;
}

export interface DreamTeamConfig {
  roles: readonly DreamTeamRole[];
  seed: number;
  /** Skips per side. */
  skips: number;
}

export type DreamTeamSide = 0 | 1;

export interface DreamTeamState {
  config: DreamTeamConfig;
  /** The deck, shuffled by the seed. */
  order: string[];
  /** Next card to draw from `order`. */
  cursor: number;
  turn: DreamTeamSide;
  /** The card the side on turn must place (null once drafting ends). */
  drawn: string | null;
  /** Card id per role slot, for each side. */
  teams: [(string | null)[], (string | null)[]];
  skipsLeft: [number, number];
  /** The room's pick per role slot. */
  votes: (DreamTeamSide | null)[];
  status: 'drafting' | 'voting' | 'finished';
}

export type DreamTeamAction =
  | { type: 'place'; slot: number }
  | { type: 'skip' }
  | { type: 'vote'; slot: number; side: DreamTeamSide }
  | { type: 'finish' };

export class DeckTooSmallError extends Error {
  readonly needed: number;
  constructor(needed: number) {
    super(`A Dream Team deck needs at least ${needed} cards`);
    this.needed = needed;
  }
}

/** Cards a deck needs for this setup: every slot on both sides, plus every skip. */
export const cardsNeeded = (roles: number, skips: number) => 2 * roles + 2 * skips;

export function createDreamTeam(
  cardIds: readonly string[],
  config: DreamTeamConfig,
): DreamTeamState {
  const roles = config.roles.length;
  if (roles < 1) throw new RangeError('at least one role is needed');
  if (!Number.isInteger(config.skips) || config.skips < 0) {
    throw new RangeError('skips must be a whole number');
  }
  const needed = cardsNeeded(roles, config.skips);
  if (new Set(cardIds).size < needed) throw new DeckTooSmallError(needed);
  const order = seededShuffle([...new Set(cardIds)], config.seed);
  return {
    config,
    order,
    cursor: 1,
    turn: 0,
    drawn: order[0]!,
    teams: [Array<string | null>(roles).fill(null), Array<string | null>(roles).fill(null)],
    skipsLeft: [config.skips, config.skips],
    votes: Array<DreamTeamSide | null>(roles).fill(null),
    status: 'drafting',
  };
}

export function reduceDreamTeam(state: DreamTeamState, action: DreamTeamAction): DreamTeamState {
  switch (action.type) {
    case 'place': {
      const team = state.teams[state.turn];
      if (state.status !== 'drafting' || !state.drawn || team[action.slot] !== null) return state;
      if (action.slot < 0 || action.slot >= team.length) return state;
      const placed = team.map((c, i) => (i === action.slot ? state.drawn : c));
      const teams: DreamTeamState['teams'] =
        state.turn === 0 ? [placed, state.teams[1]] : [state.teams[0], placed];
      if (teams.every((t) => t.every((c) => c !== null))) {
        return { ...state, teams, drawn: null, status: 'voting' };
      }
      // Turns alternate; a side that's already full is passed over.
      const other: DreamTeamSide = state.turn === 0 ? 1 : 0;
      const turn = teams[other].some((c) => c === null) ? other : state.turn;
      return { ...state, teams, turn, drawn: state.order[state.cursor]!, cursor: state.cursor + 1 };
    }
    case 'skip': {
      if (state.status !== 'drafting' || state.skipsLeft[state.turn] < 1) return state;
      if (state.cursor >= state.order.length) return state;
      const skipsLeft: [number, number] = [...state.skipsLeft];
      skipsLeft[state.turn] -= 1;
      return {
        ...state,
        skipsLeft,
        drawn: state.order[state.cursor]!,
        cursor: state.cursor + 1,
      };
    }
    case 'vote': {
      if (state.status !== 'voting') return state;
      if (action.slot < 0 || action.slot >= state.votes.length) return state;
      return { ...state, votes: state.votes.map((v, i) => (i === action.slot ? action.side : v)) };
    }
    case 'finish':
      if (state.status !== 'voting' || state.votes.some((v) => v === null)) return state;
      return { ...state, status: 'finished' };
  }
}

export interface DreamTeamVerdict {
  /** Points per side. */
  scores: [number, number];
  /** The winning side, or null for a tie. */
  winner: DreamTeamSide | null;
}

const verdict = (scores: [number, number]): DreamTeamVerdict => ({
  scores,
  winner: scores[0] === scores[1] ? null : scores[0] > scores[1] ? 0 : 1,
});

export interface DreamTeamResults {
  /** Role slots each side won in the room's vote. */
  room: DreamTeamVerdict;
  /** Sum of each card's stat for its role; null when any card has no stats (custom decks). */
  stats: DreamTeamVerdict | null;
  /** Per slot: each side's stat for that role (null without stats). */
  slotStats: ([number, number] | null)[];
}

export function dreamTeamResults(
  state: DreamTeamState,
  cards: ReadonlyMap<string, DreamTeamCard>,
): DreamTeamResults {
  const room: [number, number] = [0, 0];
  for (const v of state.votes) if (v !== null) room[v] += 1;
  const slotStats = state.config.roles.map((role, i) => {
    const a = cards.get(state.teams[0][i] ?? '')?.stats;
    const b = cards.get(state.teams[1][i] ?? '')?.stats;
    return a && b ? ([a[role.stat], b[role.stat]] as [number, number]) : null;
  });
  const stats = slotStats.every((s) => s !== null)
    ? verdict([slotStats.reduce((t, s) => t + s![0], 0), slotStats.reduce((t, s) => t + s![1], 0)])
    : null;
  return { room: verdict(room), stats, slotStats };
}
