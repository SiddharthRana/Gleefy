import { encodeShare } from '@mirthmix/game-engine';
import { expect, test } from '@playwright/test';
import { signIn } from './session';

const link = (categoryIds: string[]) =>
  `/play?c=${encodeShare({ mode: 'would-you-rather', categoryIds, rounds: 5, seed: 7, timeLimitMs: 0 })}`;

test('signed out, premium categories are shown but locked', async ({ page }) => {
  await page.goto('/play');
  const premium = page.getByRole('checkbox', { name: /Time Travel/ });
  await expect(premium).toBeDisabled();
  await expect(page.getByRole('link', { name: 'MirthMix Premium' })).toBeVisible();
});

test('someone who unlocked Premium can pick premium categories', async ({ page }) => {
  await signIn(page, true);
  await page.goto('/play');
  const premium = page.getByRole('checkbox', { name: /Time Travel/ });
  await expect(premium).toBeEnabled();
  await expect(page.getByRole('link', { name: 'MirthMix Premium' })).toHaveCount(0);
});

test('a shared link with premium categories plays only the free ones without Premium', async ({
  page,
}) => {
  await signIn(page, false);
  await page.goto(link(['casual', 'time-travel']));
  await expect(page.getByRole('note')).toContainText('Time Travel');
  await expect(page.getByText(/Round 1 of 5/)).toBeVisible();
});

test('a link with only premium categories explains itself', async ({ page }) => {
  await page.goto(link(['time-travel']));
  await expect(page.getByText(/only uses Premium categories/)).toBeVisible();
});

test('with Premium, the same link plays its premium questions', async ({ page }) => {
  await signIn(page, true);
  await page.goto(link(['time-travel']));
  await expect(page.getByText(/Round 1 of 5/)).toBeVisible();
  await expect(page.getByRole('note')).toHaveCount(0);
});
