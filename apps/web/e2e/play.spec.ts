import AxeBuilder from '@axe-core/playwright';
import { expect, test, type Page } from '@playwright/test';

async function startGame(page: Page, mode: string) {
  await page.goto('/play');
  await page.getByLabel(mode).check();
  await page.getByLabel('5', { exact: true }).check();
  await page.getByRole('button', { name: 'Start game' }).click();
  await expect(page).toHaveURL(/\/play\?c=/);
}

async function finish(page: Page, perRound: (page: Page) => Promise<void>) {
  for (let i = 0; i < 5; i++) {
    await perRound(page);
    await page.getByRole('button', { name: i === 4 ? 'See results' : 'Next round' }).click();
  }
  await expect(page.getByRole('heading', { name: 'Results' })).toBeVisible();
}

test('Would You Rather plays to results', async ({ page }) => {
  await startGame(page, 'Would You Rather');
  await finish(page, async (p) => {
    const q = p.getByRole('region', { name: 'Question' });
    await q.getByRole('button').first().click();
    await q.getByRole('button').first().click();
    await p.getByRole('button', { name: 'Reveal' }).click();
  });
  await expect(page.getByText('5 rounds · 10 votes')).toBeVisible();
  // First game: 10 + 5 rounds × 2 + 5 first-game-of-the-day bonus, and the first trophy.
  const reward = page.getByRole('region', { name: 'Your reward' });
  await expect(reward).toContainText('+25 XP');
  await expect(reward).toContainText('Ice Breaker');
  await page.getByRole('button', { name: 'Play again' }).click();
  await expect(page.getByText('Round 1 of 5')).toBeVisible();
});

test('This or That reveals on one tap', async ({ page }) => {
  await startGame(page, 'This or That');
  await finish(page, async (p) => {
    await p.getByRole('region', { name: 'Question' }).getByRole('button').first().click();
    await expect(p.getByText('100%')).toBeVisible();
  });
});

test('Trivia scores answers and explains them', async ({ page }) => {
  await startGame(page, 'Trivia Blitz');
  await finish(page, async (p) => {
    await p.getByRole('region', { name: 'Question' }).getByRole('button', { name: /^A\./ }).click();
    await expect(p.getByText(/Correct! \+100|Not quite\. Answer:/)).toBeVisible();
  });
  await expect(page.getByText(/of 5 correct · \d+ points/)).toBeVisible();
});

test('Guess the Answer awards fewer points per clue', async ({ page }) => {
  await startGame(page, 'Guess the Answer');
  await expect(page.getByText('Worth 3 points')).toBeVisible();
  await finish(page, async (p) => {
    await p.getByRole('button', { name: 'Next clue' }).click();
    await p.getByRole('button', { name: 'Got it!' }).click();
    await expect(p.getByText('+2 points')).toBeVisible();
  });
  await expect(page.getByText('5 of 5 guessed · 10 points')).toBeVisible();
});

test('a shared link deals the same game on another device', async ({ page, browser }) => {
  await startGame(page, 'Guess the Answer');
  const url = page.url();
  const answer = await page.locator('p.font-display').first().textContent();
  const other = await browser.newPage();
  await other.goto(url);
  await expect(other.locator('p.font-display').first()).toHaveText(answer!);
  await other.close();
});

test('broken links explain themselves and offer a new game', async ({ page }) => {
  await page.goto('/play?c=not-a-real-game');
  await expect(page.getByText(/broken or out of date/)).toBeVisible();
});

test('a game in progress has no WCAG A/AA violations', async ({ page }) => {
  await startGame(page, 'Trivia Blitz');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});

test('finished games add up to levels and trophies, kept in the browser', async ({ page }) => {
  await page.goto('/trophies');
  await expect(page.getByRole('heading', { name: '0 of 9 trophies' })).toBeVisible();
  for (let i = 0; i < 3; i++) {
    await startGame(page, 'This or That');
    await finish(page, async (p) => {
      await p.getByRole('region', { name: 'Question' }).getByRole('button').first().click();
    });
  }
  // 25 XP, then 20 and 20 (the daily bonus comes once a day): level 2 needs 50, so the third game levels up.
  await expect(page.getByText('Level up! You’re now level 2')).toBeVisible();
  await page.getByRole('link', { name: 'See all your trophies' }).click();
  await expect(page.getByRole('heading', { name: '1 of 9 trophies' })).toBeVisible();
  await expect(page.getByText('Total XP').locator('..')).toContainText('65');
  await page.goto('/');
  await expect(page.getByRole('link', { name: /Level 2, 1 day streak/ })).toBeVisible();
});
