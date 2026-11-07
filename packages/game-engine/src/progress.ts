// Player progress: XP, levels, a daily streak and trophies, earned by finishing games. It lives only
// on the device (localStorage on the website, shared preferences in the app) and never leaves it.
// The Dart copy (apps/mobile/lib/game/progress.dart) replays test-vectors/progress.json.

export type ProgressMode = 'would-you-rather' | 'this-or-that' | 'trivia' | 'guess';

export const PROGRESS_MODES: readonly ProgressMode[] = [
  'would-you-rather',
  'this-or-that',
  'trivia',
  'guess',
];

export interface Progress {
  xp: number;
  gamesPlayed: number;
  /** Modes finished at least once, in the order they were first finished. */
  modesPlayed: ProgressMode[];
  /** Days in a row (up to lastPlayedDay) with at least one finished game. */
  streak: number;
  bestStreak: number;
  /** Local calendar day of the last finished game, YYYY-MM-DD. */
  lastPlayedDay: string | null;
  /** Trophy ids, in the order they were earned. */
  trophies: string[];
}

export const EMPTY_PROGRESS: Progress = {
  xp: 0,
  gamesPlayed: 0,
  modesPlayed: [],
  streak: 0,
  bestStreak: 0,
  lastPlayedDay: null,
  trophies: [],
};

export interface FinishedGame {
  mode: ProgressMode;
  /** Rounds actually played (questions, cards or votes). */
  rounds: number;
  /** Local calendar day the game finished, YYYY-MM-DD. */
  day: string;
  /** Trivia only: every question was answered correctly. */
  perfect?: boolean;
}

export const XP = {
  perGame: 10,
  perRound: 2,
  /** Rounds beyond this earn no extra XP, so a 100-round marathon can't farm levels. */
  maxRounds: 30,
  firstGameOfDay: 5,
  perfectTrivia: 15,
} as const;

/** Total XP needed to reach a level: 0, 50, 150, 300, 500, … (25 × L × (L − 1)). */
export function xpForLevel(level: number): number {
  return 25 * level * (level - 1);
}

export function levelFor(xp: number): number {
  let level = 1;
  while (xpForLevel(level + 1) <= xp) level++;
  return level;
}

/** Progress through the current level, for the XP bar. */
export function levelProgress(xp: number): {
  level: number;
  into: number;
  needed: number;
} {
  const level = levelFor(xp);
  const start = xpForLevel(level);
  return { level, into: xp - start, needed: xpForLevel(level + 1) - start };
}

export interface Trophy {
  id: string;
  /** Met once the progress after a game passes this test. */
  earned: (p: Progress, game: FinishedGame) => boolean;
}

/** Trophy ids and rules. Names and descriptions live in each app's copy. */
export const TROPHIES: readonly Trophy[] = [
  { id: 'first-game', earned: (p) => p.gamesPlayed >= 1 },
  { id: 'regular', earned: (p) => p.gamesPlayed >= 5 },
  { id: 'party-animal', earned: (p) => p.gamesPlayed >= 25 },
  { id: 'all-modes', earned: (p) => PROGRESS_MODES.every((m) => p.modesPlayed.includes(m)) },
  { id: 'streak-3', earned: (p) => p.streak >= 3 },
  { id: 'streak-7', earned: (p) => p.streak >= 7 },
  { id: 'marathon', earned: (_, g) => g.rounds >= 20 },
  { id: 'know-it-all', earned: (_, g) => g.mode === 'trivia' && g.perfect === true },
  { id: 'rising-star', earned: (p) => levelFor(p.xp) >= 5 },
];

/** Whole days from one YYYY-MM-DD to another. */
export function daysBetween(from: string, to: string): number {
  return Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86_400_000);
}

/** A Date's local calendar day as YYYY-MM-DD. */
export function localDay(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** The streak to show today: it lapses once a whole day passes without a game. */
export function currentStreak(p: Progress, today: string): number {
  if (!p.lastPlayedDay) return 0;
  return daysBetween(p.lastPlayedDay, today) <= 1 ? p.streak : 0;
}

export interface GameReward {
  progress: Progress;
  xpGained: number;
  levelBefore: number;
  levelAfter: number;
  /** Trophy ids earned by this game. */
  newTrophies: string[];
}

/** Records a finished game: XP, streak, modes and any trophies it earns. */
export function recordGame(before: Progress, game: FinishedGame): GameReward {
  const gap = before.lastPlayedDay === null ? null : daysBetween(before.lastPlayedDay, game.day);
  const firstToday = gap === null || gap > 0;
  // A clock moved backwards (gap < 0) keeps the streak as it was.
  const streak = gap === null || gap > 1 ? 1 : gap === 1 ? before.streak + 1 : before.streak;
  const rounds = Math.max(0, Math.min(game.rounds, XP.maxRounds));
  const xpGained =
    XP.perGame +
    XP.perRound * rounds +
    (firstToday ? XP.firstGameOfDay : 0) +
    (game.mode === 'trivia' && game.perfect ? XP.perfectTrivia : 0);
  const after: Progress = {
    xp: before.xp + xpGained,
    gamesPlayed: before.gamesPlayed + 1,
    modesPlayed: before.modesPlayed.includes(game.mode)
      ? before.modesPlayed
      : [...before.modesPlayed, game.mode],
    streak,
    bestStreak: Math.max(before.bestStreak, streak),
    lastPlayedDay: gap !== null && gap < 0 ? before.lastPlayedDay : game.day,
    trophies: before.trophies,
  };
  const newTrophies = TROPHIES.filter(
    (t) => !before.trophies.includes(t.id) && t.earned(after, game),
  ).map((t) => t.id);
  after.trophies = [...before.trophies, ...newTrophies];
  return {
    progress: after,
    xpGained,
    levelBefore: levelFor(before.xp),
    levelAfter: levelFor(after.xp),
    newTrophies,
  };
}

/** Reads stored progress defensively: anything missing or malformed falls back to empty. */
export function parseProgress(value: unknown): Progress {
  if (!value || typeof value !== 'object') return EMPTY_PROGRESS;
  const v = value as Record<string, unknown>;
  const num = (x: unknown) => (typeof x === 'number' && Number.isFinite(x) && x >= 0 ? x : 0);
  const strings = (x: unknown) =>
    Array.isArray(x) ? x.filter((s): s is string => typeof s === 'string') : [];
  return {
    xp: num(v.xp),
    gamesPlayed: num(v.gamesPlayed),
    modesPlayed: strings(v.modesPlayed).filter((m): m is ProgressMode =>
      PROGRESS_MODES.includes(m as ProgressMode),
    ),
    streak: num(v.streak),
    bestStreak: num(v.bestStreak),
    lastPlayedDay:
      typeof v.lastPlayedDay === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v.lastPlayedDay)
        ? v.lastPlayedDay
        : null,
    trophies: strings(v.trophies).filter((t) => TROPHIES.some((x) => x.id === t)),
  };
}
