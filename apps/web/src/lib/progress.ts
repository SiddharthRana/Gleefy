'use client';

import {
  currentStreak,
  EMPTY_PROGRESS,
  localDay,
  parseProgress,
  recordGame,
  type FinishedGame,
  type GameReward,
  type Progress,
} from '@gleefy/game-engine';
import { useEffect, useState } from 'react';

/**
 * XP, level, streak and trophies earned in the web player. Kept only in this browser's local
 * storage (never sent anywhere), and separate from the app's, which lives on the phone.
 */
const KEY = 'gleefy.progress.v1';
const EVENT = 'gleefy-progress';

export function readProgress(): Progress {
  try {
    const raw = window.localStorage.getItem(KEY);
    return raw ? parseProgress(JSON.parse(raw)) : EMPTY_PROGRESS;
  } catch {
    return EMPTY_PROGRESS;
  }
}

/** Records a finished game in this browser and tells every progress display to update. */
export function recordFinishedGame(game: Omit<FinishedGame, 'day'>): GameReward {
  const reward = recordGame(readProgress(), { ...game, day: localDay(new Date()) });
  try {
    window.localStorage.setItem(KEY, JSON.stringify(reward.progress));
  } catch {
    // Private windows or blocked storage: the reward still shows, it just isn't kept.
  }
  window.dispatchEvent(new Event(EVENT));
  return reward;
}

/** This browser's progress and today's streak; null until it has been read (after hydration). */
export function useProgress(): { progress: Progress; streak: number } | null {
  const [value, setValue] = useState<{ progress: Progress; streak: number } | null>(null);
  useEffect(() => {
    const load = () => {
      const progress = readProgress();
      setValue({ progress, streak: currentStreak(progress, localDay(new Date())) });
    };
    load();
    window.addEventListener(EVENT, load);
    window.addEventListener('storage', load);
    return () => {
      window.removeEventListener(EVENT, load);
      window.removeEventListener('storage', load);
    };
  }, []);
  return value;
}

export interface TrophyInfo {
  name: string;
  description: string;
  icon: string;
}

/** Names for the engine's trophy ids (the app has the same names in its copy). */
export const trophyInfo: Record<string, TrophyInfo> = {
  'first-game': { name: 'Ice Breaker', description: 'Finish your first game.', icon: '🎉' },
  regular: { name: 'Regular', description: 'Finish 5 games.', icon: '⭐' },
  'party-animal': { name: 'Party Animal', description: 'Finish 25 games.', icon: '🦄' },
  'all-modes': { name: 'Try Them All', description: 'Finish a game of every mode.', icon: '🧭' },
  'streak-3': { name: 'On a Roll', description: 'Play 3 days in a row.', icon: '🔥' },
  'streak-7': { name: 'Week of Fun', description: 'Play 7 days in a row.', icon: '📅' },
  marathon: { name: 'Marathon', description: 'Finish a game of 20 rounds or more.', icon: '🏃' },
  'know-it-all': {
    name: 'Know-It-All',
    description: 'Get every answer right in a Trivia Blitz game.',
    icon: '🧠',
  },
  'rising-star': { name: 'Rising Star', description: 'Reach level 5.', icon: '🚀' },
};
