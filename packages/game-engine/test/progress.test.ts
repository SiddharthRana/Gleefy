import { describe, expect, it } from 'vitest';
import {
  currentStreak,
  EMPTY_PROGRESS,
  levelFor,
  levelProgress,
  localDay,
  parseProgress,
  recordGame,
  xpForLevel,
  type FinishedGame,
} from '../src/progress.ts';

const game = (over: Partial<FinishedGame> = {}): FinishedGame => ({
  mode: 'would-you-rather',
  rounds: 10,
  day: '2026-11-01',
  ...over,
});

describe('levels', () => {
  it('need 50, then 100, 150… more XP each', () => {
    expect([1, 2, 3, 4, 5].map(xpForLevel)).toEqual([0, 50, 150, 300, 500]);
    expect([0, 49, 50, 149, 150, 500].map(levelFor)).toEqual([1, 1, 2, 2, 3, 5]);
    expect(levelProgress(175)).toEqual({ level: 3, into: 25, needed: 150 });
  });
});

describe('recordGame', () => {
  it('gives XP per game and round, plus a bonus for the first game of the day', () => {
    const first = recordGame(EMPTY_PROGRESS, game());
    expect(first.xpGained).toBe(10 + 20 + 5);
    expect(first.newTrophies).toEqual(['first-game']);
    const second = recordGame(first.progress, game({ rounds: 5 }));
    expect(second.xpGained).toBe(10 + 10);
  });

  it('rewards a perfect Trivia game with XP and a trophy', () => {
    const r = recordGame(EMPTY_PROGRESS, game({ mode: 'trivia', perfect: true }));
    expect(r.xpGained).toBe(10 + 20 + 5 + 15);
    expect(r.newTrophies).toContain('know-it-all');
  });

  it('reports a level-up and Rising star at level 5', () => {
    const near = { ...EMPTY_PROGRESS, xp: 490, gamesPlayed: 3, trophies: ['first-game'] };
    const r = recordGame(near, game({ day: '2026-11-02' }));
    expect([r.levelBefore, r.levelAfter]).toEqual([4, 5]);
    expect(r.newTrophies).toContain('rising-star');
  });

  it('never awards the same trophy twice', () => {
    let p = EMPTY_PROGRESS;
    const earned: string[] = [];
    for (let i = 0; i < 6; i++) {
      const r = recordGame(p, game());
      p = r.progress;
      earned.push(...r.newTrophies);
    }
    expect(earned).toEqual(['first-game', 'regular']);
    expect(p.trophies).toEqual(['first-game', 'regular']);
  });
});

describe('streaks', () => {
  it('lapse once a whole day passes without a game', () => {
    const p = { ...EMPTY_PROGRESS, streak: 4, lastPlayedDay: '2026-11-01' };
    expect(currentStreak(p, '2026-11-01')).toBe(4);
    expect(currentStreak(p, '2026-11-02')).toBe(4);
    expect(currentStreak(p, '2026-11-03')).toBe(0);
    expect(currentStreak(EMPTY_PROGRESS, '2026-11-03')).toBe(0);
  });

  it('use the local calendar day', () => {
    expect(localDay(new Date(2026, 0, 5, 23, 59))).toBe('2026-01-05');
  });
});

describe('parseProgress', () => {
  it('keeps valid data and drops anything malformed', () => {
    expect(parseProgress(null)).toEqual(EMPTY_PROGRESS);
    expect(
      parseProgress({
        xp: 120,
        gamesPlayed: -3,
        modesPlayed: ['trivia', 'chess'],
        lastPlayedDay: 'yesterday',
        trophies: ['first-game', 'made-up'],
      }),
    ).toEqual({
      ...EMPTY_PROGRESS,
      xp: 120,
      modesPlayed: ['trivia'],
      trophies: ['first-game'],
    });
  });
});
