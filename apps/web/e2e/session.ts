import type { Page } from '@playwright/test';

export const API = 'http://localhost:4000';

export const account = (premium: boolean, purchases: object[] = []) => ({
  id: 'u-e2e',
  email: 'host@example.test',
  plan: { id: premium ? 'premium' : 'free', name: '', paid: premium, source: 'default' },
  entitlements: { premiumContent: premium },
  lifetime: premium,
  validUntil: null,
  purchases,
});

/** Signs the browser in by seeding a Supabase session (the e2e build points at supabase.test). */
export async function signIn(page: Page, premium: boolean) {
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
  await page.route(`${API}/v1/me`, (route) => route.fulfill({ json: account(premium) }));
}
