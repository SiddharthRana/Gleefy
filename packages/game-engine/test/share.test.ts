import { describe, expect, it } from 'vitest';
import { decodeShare, encodeShare, type SharedGame } from '../src/share.ts';

describe('share links', () => {
  const game: SharedGame = {
    mode: 'trivia',
    categoryIds: ['science', 'world'],
    rounds: 10,
    seed: 4294967295,
    timeLimitMs: 10000,
  };

  it('round-trips every mode and stays URL-safe', () => {
    for (const mode of ['would-you-rather', 'this-or-that', 'guess'] as const) {
      const g = { mode, categoryIds: ['casual'], rounds: 5, seed: 7 };
      expect(decodeShare(encodeShare(g))).toEqual(g);
    }
    const code = encodeShare(game);
    expect(code).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(decodeShare(code)).toEqual(game);
  });

  it('rejects malformed or hostile input', () => {
    const enc = (v: unknown) => btoa(JSON.stringify(v)).replace(/=+$/, '');
    for (const bad of [
      '',
      'not base64!',
      'x'.repeat(3000),
      enc({ m: 9, c: ['a'], r: 5, s: 1 }),
      enc({ m: 0, c: [], r: 5, s: 1 }),
      enc({ m: 0, c: ['<script>'], r: 5, s: 1 }),
      enc({ m: 0, c: ['a'], r: 0, s: 1 }),
      enc({ m: 0, c: ['a'], r: 500, s: 1 }),
      enc({ m: 0, c: ['a'], r: 5, s: -1 }),
    ]) {
      expect(decodeShare(bad), bad).toBeNull();
    }
  });

  it('defaults a bad trivia timer to 20 seconds', () => {
    const code = btoa(JSON.stringify({ m: 2, c: ['a'], r: 5, s: 1, t: 999999 })).replace(/=+$/, '');
    expect(decodeShare(code)?.timeLimitMs).toBe(20000);
  });
});
