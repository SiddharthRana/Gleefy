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
  /** Decorative icon for the game card. */
  icon: string;
  /** Card colour (a design token). */
  color: string;
  players: string;
  minutes: string;
}

/** The game library. Status is honest: only modes that exist in the app are "available". */
export const modes: ModeInfo[] = [
  {
    id: 'would-you-rather',
    icon: '⚖️',
    color: 'var(--mm-option-a)',
    players: '2+',
    minutes: '10',
    name: 'Would You Rather',
    blurb: 'Two choices. Everyone raises a hand. See how the room splits.',
    status: 'available',
    href: guideHref('would-you-rather'),
  },
  {
    id: 'this-or-that',
    icon: '⚡',
    color: 'var(--mm-option-b)',
    players: '2+',
    minutes: '5',
    name: 'This or That',
    blurb: 'Rapid-fire picks with big buttons, made for passing the phone.',
    status: 'available',
    href: guideHref('this-or-that'),
  },
  {
    id: 'trivia',
    icon: '🧠',
    color: 'var(--mm-primary)',
    players: '2+',
    minutes: '10',
    name: 'Trivia Blitz',
    blurb: 'Multiple choice against the clock, played in teams.',
    status: 'available',
    href: guideHref('trivia'),
  },
  {
    id: 'guess',
    icon: '🔍',
    color: 'var(--mm-accent)',
    players: '2+',
    minutes: '10',
    name: 'Guess the Answer',
    blurb: 'Reveal clues one at a time. Fewer clues, more points.',
    status: 'available',
    href: guideHref('guess'),
  },
  {
    id: 'custom',
    icon: '🎁',
    color: 'var(--mm-success)',
    players: '2+',
    minutes: '20',
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
