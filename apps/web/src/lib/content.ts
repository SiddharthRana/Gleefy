import type { WyrPack } from '@gleefy/content';
import wyrJson from '@gleefy/content/packs/would-you-rather.json';

/** The same validated pack the app ships (validated in CI by `pnpm content:validate`). */
export const wyr = wyrJson as WyrPack;

export const wyrFreeCategories = wyr.categories.filter((c) => c.tier === 'free');

export function wyrCount(categoryId?: string): number {
  return categoryId ? wyr.items.filter((i) => i.category === categoryId).length : wyr.items.length;
}

/** A fixed, varied set of free questions for the website demo. */
export const wyrSamples = wyrFreeCategories
  .filter((c) => c.region === 'global')
  .flatMap((c) => wyr.items.filter((i) => i.category === c.id).slice(0, 3))
  .map(({ id, a, b }) => ({ id, a, b }));
