import { expect, test, type Page } from '@playwright/test';
import { signIn } from './session';

/** Places cards until both teams are full (the vote starts). */
async function draftAll(page: Page) {
  for (let pick = 0; pick < 10; pick++) {
    if (await page.getByRole('heading', { name: /^Who wins/ }).isVisible()) return;
    const ready = page.getByRole('button', { name: /^I’m / });
    if (await ready.isVisible()) await ready.click();
    await page.getByRole('button', { name: 'Tap to flip' }).click();
    await page.getByRole('button', { name: /Empty/ }).first().click();
  }
}

test('Dream Team: a blind draft, the room’s vote and the stats verdict', async ({ page }) => {
  await page.goto('/games/dream-team');
  await expect(page.getByRole('heading', { level: 1, name: 'Dream Team' })).toBeVisible();
  await expect(page.getByRole('list', { name: 'Role sets' })).toContainText('Heist Crew');
  await page.getByRole('link', { name: 'Play Dream Team in your browser' }).click();
  await expect(page).toHaveURL(/\/play\/dream-team$/);

  await page.getByLabel('Side 1').fill('Ana');
  await page.getByLabel('Side 2').fill('Ben');
  await page.getByRole('button', { name: 'Start the draft' }).click();
  await expect(page.getByRole('heading', { name: 'Ana’s pick' })).toBeVisible();

  // Placing needs a flipped card; one skip each.
  await expect(page.getByRole('button', { name: /Empty/ })).toHaveCount(0);
  await page.getByRole('button', { name: 'Tap to flip' }).click();
  await page.getByRole('button', { name: 'Skip (1 left)' }).click();
  await page.getByRole('button', { name: 'Tap to flip' }).click();
  await expect(page.getByRole('button', { name: 'No skips left' })).toBeDisabled();
  await page.getByRole('button', { name: /Empty/ }).first().click();
  await expect(page.getByRole('heading', { name: 'Pass the phone to Ben' })).toBeVisible();
  await page.getByRole('button', { name: 'I’m Ben' }).click();
  await page.getByRole('button', { name: 'Tap to flip' }).click();
  await page.getByRole('button', { name: /Empty/ }).first().click();
  await draftAll(page); // the rest (it stops once both teams are full)

  await expect(page.getByRole('heading', { name: 'Who wins Captain?' })).toBeVisible();
  for (let role = 0; role < 5; role++) {
    await page.getByRole('button', { name: role % 2 ? /^Ben/ : /^Ana/ }).click();
  }
  await page.getByRole('button', { name: 'See the verdict' }).click();
  await expect(page.getByRole('heading', { name: 'The room says: Ana wins 3–2' })).toBeVisible();
  await expect(page.getByText(/The stats say:/)).toBeVisible();
  await expect(page.getByText('Ice Breaker')).toBeVisible();
  await page.getByRole('button', { name: 'Draft again' }).click();
  await expect(page.getByRole('heading', { name: 'Ana’s pick' })).toBeVisible();
});

test('Myths & Legends and custom decks need Premium', async ({ page }) => {
  await page.goto('/play/dream-team');
  await expect(page.getByRole('radio', { name: /Myths & Legends/ })).toBeDisabled();
  await expect(page.getByRole('link', { name: 'Gleefy Premium' })).toBeVisible();
  await expect(page.getByRole('button', { name: /Make your own deck/ })).toHaveCount(0);
});

test('with Premium, make a deck of your own and play it (room vote only)', async ({ page }) => {
  await signIn(page, true);
  await page.goto('/play/dream-team');
  await expect(page.getByRole('radio', { name: /Myths & Legends/ })).toBeEnabled();
  await page.getByRole('button', { name: '+ Make your own deck' }).click();
  await page.getByLabel('Deck name').fill('Office Legends');
  await page.getByLabel('Cards, one per line').fill('Sam\nPriya\nLeo');
  await page.getByRole('button', { name: 'Save deck' }).click();
  await expect(page.locator('p[role="alert"]')).toContainText('Add at least 12 cards');
  await page
    .getByLabel('Cards, one per line')
    .fill(Array.from({ length: 12 }, (_, i) => `Colleague ${i + 1}`).join('\n'));
  await page.getByRole('button', { name: 'Save deck' }).click();
  await page.getByRole('radio', { name: /Office Legends/ }).check();
  await page.getByRole('button', { name: 'Start the draft' }).click();
  await draftAll(page);
  for (let role = 0; role < 5; role++)
    await page.getByRole('button', { name: /^Player 1/ }).click();
  await page.getByRole('button', { name: 'See the verdict' }).click();
  await expect(
    page.getByText('Custom decks have no stats, so the room’s word is final.'),
  ).toBeVisible();
  // Saved in this browser.
  await page.reload();
  await expect(page.getByRole('radio', { name: /Office Legends/ })).toBeVisible();
});
