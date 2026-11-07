import type { Route } from 'next';
import type { ShareMode } from '@mirthmix/game-engine';
import { packs } from './packs';

export type GuideId = ShareMode | 'custom-party-pack';

export interface ModeGuide {
  id: GuideId;
  name: string;
  description: string;
  intro: string;
  rules: string[];
  tips: string[];
  /** Content pack behind the mode, for real category counts. Custom packs mix the others. */
  pack?: ShareMode;
  /** Can be played in the browser at /play. */
  webPlayer: boolean;
}

export const guides: ModeGuide[] = [
  {
    id: 'would-you-rather',
    name: 'Would You Rather',
    description:
      'Play Would You Rather on one phone: read two choices aloud, everyone votes, and see how the room splits.',
    intro:
      'Two choices, one room, no fence-sitting. The classic conversation starter, built for passing around a single phone.',
    rules: [
      'Pick categories and how many rounds to play (5 to 20).',
      'Read both options aloud. Everyone raises a hand for their pick.',
      'Tap each side once per vote. Made a mistake? Undo.',
      'Reveal to see the split, then move on to the next round.',
      'At the end, see the most divisive and the most unanimous questions.',
    ],
    tips: [
      'Set a group size so nobody can vote twice.',
      'Skip any question that doesn’t suit your group. It won’t use up a round.',
      'Ask the minority to defend their pick before you reveal the next one.',
      'Write a few questions about your own group in the app (My questions) and mix them in.',
    ],
    pack: 'would-you-rather',
    webPlayer: true,
  },
  {
    id: 'this-or-that',
    name: 'This or That',
    description:
      'Rapid-fire This or That for groups: big buttons, an optional 5-second timer, and a pass-the-phone mode that shows who agrees most.',
    intro:
      'Short, snappy picks with no time to overthink. Play it as a room, or pass the phone so everyone answers on their own.',
    rules: [
      'Choose categories and rounds. Turn on the 5-second timer for extra pressure.',
      'Room pick: read the two options and tap the one the group shouts loudest.',
      'Pass the phone: each player taps their own pick, then hands the phone on.',
      'Some rounds come with a discussion prompt. Give the loudest voice ten seconds to defend it.',
      'Results show every pick and, when passing the phone, which two players were most in sync.',
    ],
    tips: [
      'Add player names first so pass-the-phone results show who agreed with whom.',
      'Use the timer when the group starts debating every single round.',
      'Mix a free category with a regional one for more surprises.',
    ],
    pack: 'this-or-that',
    webPlayer: true,
  },
  {
    id: 'trivia',
    name: 'Trivia Blitz',
    description:
      'Team trivia on one phone: four choices, a pausable timer, speed bonuses and a short explanation after every answer.',
    intro:
      'Quick-fire multiple choice for teams. Every question has a short explanation, so even wrong answers teach you something.',
    rules: [
      'Add team names, or play as one group. Teams take turns answering.',
      'Each question has four choices and a timer (default 20 seconds). Pause it any time.',
      'A correct answer scores 100 points, plus up to 50 more for answering fast.',
      'After each answer, read the explanation aloud before moving on.',
      'The session leaderboard shows the winner at the end. Scores aren’t saved anywhere else.',
    ],
    tips: [
      'Hand the phone to the team whose turn it is, so nobody else peeks.',
      'Turn the timer off for younger players or a relaxed game.',
      'Skip a question if nobody in the room could possibly know it.',
    ],
    pack: 'trivia',
    webPlayer: true,
  },
  {
    id: 'guess',
    name: 'Guess the Answer',
    description:
      'A clue-by-clue guessing game for groups: one reader, three clues, and fewer points for every clue you need.',
    intro:
      'One person reads, everyone else shouts guesses. The fewer clues you need, the more points you get.',
    rules: [
      'Pick a reader. Only they look at the card, which shows the answer.',
      'Read the first clue. The group guesses out loud.',
      'Someone got it? Tap "Got it". If not, reveal the next clue.',
      'Points: 3 on the first clue, 2 on the second, 1 on the third, 0 if you reveal the answer.',
      'Play as one group, or as teams taking turns. The highest score wins.',
    ],
    tips: [
      'Rotate the reader every few cards so everyone gets to guess.',
      'Accept close answers if the group agrees.',
      'Play in teams for a little friendly rivalry.',
    ],
    pack: 'guess',
    webPlayer: true,
  },
  {
    id: 'custom-party-pack',
    name: 'Custom Party Pack',
    description:
      'Build your own party session: pick several MirthMix games, set the rounds for each, and play them back to back.',
    intro:
      'Can’t pick one game? Line several up. A party pack plays your chosen games in order, with a tap between each.',
    rules: [
      'In the app, open Party pack and pick two or more games.',
      'Set the rounds for each game and put them in the order you like.',
      'Save it with a name to play it again later.',
      'When one game ends, the next starts with a tap. Results appear after each game.',
    ],
    tips: [
      'Start with a quick This or That to warm the room up, finish with Trivia.',
      'Keep the whole pack under half an hour so nobody drifts off.',
      'Save a pack for each kind of group: family, friends, the office.',
    ],
    webPlayer: false,
  },
];

export const guideHref = (id: GuideId) => `/games/${id}` as Route;

export function guide(id: string): ModeGuide | undefined {
  return guides.find((g) => g.id === id);
}

export function categoryCount(mode: ShareMode, categoryId?: string): number {
  const items = packs[mode].items as { category: string }[];
  return categoryId ? items.filter((i) => i.category === categoryId).length : items.length;
}
