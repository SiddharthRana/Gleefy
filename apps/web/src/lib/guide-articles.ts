import type { Route } from 'next';

/** Long-form guides (MDX pages under src/app/guides). */
export const articles: { href: Route; title: string; summary: string }[] = [
  {
    href: '/guides/game-night-on-one-phone',
    title: 'Hosting a game night on one phone',
    summary: 'How to run a smooth, fun game night when the only thing you need is your own phone.',
  },
  {
    href: '/guides/family-party-games',
    title: 'Party games for mixed-age family gatherings',
    summary: 'Picking games, categories and house rules that work from teenagers to grandparents.',
  },
];
