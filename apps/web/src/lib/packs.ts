import type { GuessPack, TotPack, TriviaPack, WyrPack } from '@gleefy/content';
import guessJson from '@gleefy/content/packs/guess.json';
import totJson from '@gleefy/content/packs/this-or-that.json';
import triviaJson from '@gleefy/content/packs/trivia.json';
import wyrJson from '@gleefy/content/packs/would-you-rather.json';
import type { ShareMode } from '@gleefy/game-engine';

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

export interface PremiumCategory {
  id: string;
  name: string;
  mode: string;
  count: number;
}

/** Every premium category with its real question count, for the homepage and pricing page. */
export const premiumCategories: PremiumCategory[] = (Object.keys(packs) as ShareMode[]).flatMap(
  (mode) =>
    packs[mode].categories
      .filter((c) => c.tier === 'premium')
      .map((c) => ({
        id: `${mode}-${c.id}`,
        name: c.name,
        mode: modeNames[mode],
        count: (packs[mode].items as { category: string }[]).filter((i) => i.category === c.id)
          .length,
      })),
);

export const premiumQuestionCount = premiumCategories.reduce((n, c) => n + c.count, 0);
