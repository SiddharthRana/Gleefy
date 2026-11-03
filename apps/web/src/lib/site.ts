import type { Route } from 'next';
import { guideHref } from './guides';

export const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL ?? 'https://mirthmix.example').replace(
  /\/$/,
  '',
);

export type ModeStatus = 'available' | 'in-development';

export interface ModeInfo {
  id: string;
  name: string;
  blurb: string;
  status: ModeStatus;
  href?: Route;
}

/** The game library. Status is honest: only modes that exist in the app are "available". */
export const modes: ModeInfo[] = [
  {
    id: 'would-you-rather',
    name: 'Would You Rather',
    blurb: 'Two choices. Everyone raises a hand. See how the room splits.',
    status: 'available',
    href: guideHref('would-you-rather'),
  },
  {
    id: 'this-or-that',
    name: 'This or That',
    blurb: 'Rapid-fire picks with big buttons, made for passing the phone.',
    status: 'available',
    href: guideHref('this-or-that'),
  },
  {
    id: 'trivia',
    name: 'Trivia Blitz',
    blurb: 'Multiple choice against the clock, played in teams.',
    status: 'available',
    href: guideHref('trivia'),
  },
  {
    id: 'guess',
    name: 'Guess the Answer',
    blurb: 'Reveal clues one at a time. Fewer clues, more points.',
    status: 'available',
    href: guideHref('guess'),
  },
  {
    id: 'custom',
    name: 'Custom Party Pack',
    blurb: 'Mix modes and categories into one party session.',
    status: 'available',
    href: guideHref('custom-party-pack'),
  },
];

export const statusLabel: Record<ModeStatus, string> = {
  available: 'In the Android app',
  'in-development': 'In development',
};
