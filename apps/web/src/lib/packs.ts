import type { GuessPack, TotPack, TriviaPack, WyrPack } from '@mirthmix/content';
import guessJson from '@mirthmix/content/packs/guess.json';
import totJson from '@mirthmix/content/packs/this-or-that.json';
import triviaJson from '@mirthmix/content/packs/trivia.json';
import wyrJson from '@mirthmix/content/packs/would-you-rather.json';
import type { ShareMode } from '@mirthmix/game-engine';

export const packs = {
  'would-you-rather': wyrJson as WyrPack,
  'this-or-that': totJson as TotPack,
  trivia: {
    ...(triviaJson as TriviaPack),
    items: (triviaJson as TriviaPack).items.filter((i) => i.reviewStatus !== 'draft'),
  },
  guess: guessJson as GuessPack,
} satisfies Record<ShareMode, unknown>;

export const modeNames: Record<ShareMode, string> = {
  'would-you-rather': 'Would You Rather',
  'this-or-that': 'This or That',
  trivia: 'Trivia Blitz',
  guess: 'Guess the Answer',
};

/** Free categories; premium ones need a verified Premium purchase (see usePremium). */
export const freeCategories = (mode: ShareMode) =>
  packs[mode].categories.filter((c) => c.tier === 'free');

/** Categories this visitor may play: free ones, plus premium ones with Premium. */
export const playableCategories = (mode: ShareMode, premium: boolean) =>
  packs[mode].categories.filter((c) => c.tier === 'free' || premium);
