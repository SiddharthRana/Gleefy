import type { DreamTeamPack } from '@gleefy/content';
import dreamTeamJson from '@gleefy/content/packs/dream-team.json';
import { cardsNeeded, type DreamTeamCard } from '@gleefy/game-engine';

/** The same validated pack the app ships: decks are its categories. */
export const dreamTeam = dreamTeamJson as DreamTeamPack;

export const dreamTeamSkips = 1;

export const deckCards = (deckId: string): DreamTeamCard[] =>
  dreamTeam.items
    .filter((i) => i.category === deckId)
    .map(({ id, name, stats }) => ({ id, name, stats }));

export const blurbs = new Map(dreamTeam.items.map((i) => [i.id, i.blurb]));

/** Cards a custom deck needs so it works with every role set. */
export const minCustomCards = cardsNeeded(
  Math.max(...dreamTeam.roleSets.map((r) => r.roles.length)),
  dreamTeamSkips,
);
export const customDeckMax = 60;
export const customNameMax = 40;
export const customTitleMax = 30;

/** A deck someone typed themselves (Premium). Kept only in this browser. */
export interface CustomDeck {
  id: string;
  name: string;
  cards: string[];
  /** Small JPEG data URLs, keyed by photoKey(card name). Kept only in this browser. */
  photos?: Record<string, string>;
}

/** A fresh id for a new custom deck. */
export const newDeckId = () => `mine-${Math.random().toString(36).slice(2, 10)}`;

/** Photos follow a card's name, so editing the list keeps them on the right cards. */
export const photoKey = (name: string) => name.trim().toLowerCase();

/** Shrinks a picked image to a small square-ish JPEG so many fit in browser storage. */
export async function shrinkPhoto(file: File, max = 320): Promise<string> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, max / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext('2d')!.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return canvas.toDataURL('image/jpeg', 0.8);
}

const DECKS_KEY = 'gleefy.dream-team.decks.v1';

export function readCustomDecks(): CustomDeck[] {
  try {
    const raw = window.localStorage.getItem(DECKS_KEY);
    const v = raw ? (JSON.parse(raw) as unknown) : [];
    return Array.isArray(v)
      ? v.filter(
          (d): d is CustomDeck =>
            typeof d?.id === 'string' && typeof d?.name === 'string' && Array.isArray(d?.cards),
        )
      : [];
  } catch {
    return [];
  }
}

/** Saves decks; false when the browser's storage is full or blocked (photos take space). */
export function writeCustomDecks(decks: CustomDeck[]): boolean {
  try {
    window.localStorage.setItem(DECKS_KEY, JSON.stringify(decks));
    return true;
  } catch {
    return false;
  }
}

const clean = (s: string) => s.trim().replace(/\s+/g, ' ');

/** One name per line, tidied, blank lines and repeats dropped. */
export function parseDeckNames(text: string): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const line of text.split('\n')) {
    const n = clean(line);
    if (n && !seen.has(n.toLowerCase())) {
      seen.add(n.toLowerCase());
      out.push(n);
    }
  }
  return out;
}

/** What's wrong with a deck, or null. Mirrors the app's checkDeck. */
export function deckProblem(title: string, names: string[]): string | null {
  const t = clean(title);
  if (!t) return 'Give the deck a name.';
  if (t.length > customTitleMax) return `Keep the deck name to ${customTitleMax} characters.`;
  if (names.length < minCustomCards)
    return `Add at least ${minCustomCards} cards, so both teams can fill every role.`;
  if (names.length > customDeckMax) return `A deck can hold up to ${customDeckMax} cards.`;
  if (names.some((n) => n.length > customNameMax))
    return `Keep each card to ${customNameMax} characters.`;
  return null;
}

export const customCards = (deck: CustomDeck): DreamTeamCard[] =>
  deck.cards.map((name, i) => ({ id: `${deck.id}-${i}`, name }));

/** Card id → photo, for a custom deck's cards. */
export const customPhotos = (deck: CustomDeck): Map<string, string> =>
  new Map(
    deck.cards.flatMap((name, i) => {
      const photo = deck.photos?.[photoKey(name)];
      return photo ? [[`${deck.id}-${i}`, photo] as const] : [];
    }),
  );
