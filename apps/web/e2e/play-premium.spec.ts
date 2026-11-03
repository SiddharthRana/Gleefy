import { encodeShare } from '@mirthmix/game-engine';
import { expect, test, type Page } from '@playwright/test';

const API = 'http://localhost:4000';

/** Signs the browser in by seeding a Supabase session (the e2e build points at supabase.test). */
async function signIn(page: Page, premium: boolean) {
  await page.addInitScript(() => {
    const expiresAt = Math.floor(Date.now() / 1000) + 24 * 3600;
    window.localStorage.setItem(
      'sb-supabase-auth-token',
      JSON.stringify({
        access_token: 'e2e.access.token',
        refresh_token: 'e2e-refresh',
        token_type: 'bearer',
        expires_in: 86400,
        expires_at: expiresAt,
        user: {
          id: 'u-e2e',
          email: 'host@example.test',
          aud: 'authenticated',
          role: 'authenticated',
        },
      }),
    );
  });
  await page.route('http://supabase.test/**', (route) => route.fulfill({ json: {} }));
  await page.route(`${API}/v1/me`, (route) =>
    route.fulfill({
      json: {
        id: 'u-e2e',
        email: 'host@example.test',
        plan: { id: premium ? 'premium' : 'free', name: '', paid: premium, source: 'default' },
        entitlements: { premiumContent: premium },
        validUntil: null,
        subscriptions: [],
      },
    }),
  );
}

const link = (categoryIds: string[]) =>
  `/play?c=${encodeShare({ mode: 'would-you-rather', categoryIds, rounds: 5, seed: 7, timeLimitMs: 0 })}`;

test('signed out, premium categories are shown but locked', async ({ page }) => {
  await page.goto('/play');
  const premium = page.getByRole('checkbox', { name: /Time Travel/ });
  await expect(premium).toBeDisabled();
  await expect(page.getByRole('link', { name: 'MirthMix Premium' })).toBeVisible();
});

test('a Premium subscriber can pick premium categories', async ({ page }) => {
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
