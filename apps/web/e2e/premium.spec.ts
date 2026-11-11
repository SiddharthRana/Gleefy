import { expect, test } from '@playwright/test';
import { account, API, signIn } from './session';

const config = (available: boolean) => ({
  enabled: available,
  web: { provider: 'dodo', available },
  googlePlay: { available, packageName: 'com.gleefy.app', productId: 'gleefy_premium_unlock' },
});

test('the Premium page shows the one-time price and what premium adds', async ({ page }) => {
  await page.goto('/');
  await page
    .getByRole('navigation', { name: 'Main' })
    .getByRole('link', { name: 'Premium' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Premium' })).toBeVisible();
  const premium = page.getByRole('region', { name: 'Gleefy Premium' });
  await expect(premium).toContainText('$2.99 once');
  await expect(premium).toContainText('No subscription');
  const included = page.getByRole('region', { name: 'Premium categories' });
  await expect(included.getByRole('listitem').first()).toContainText(/\d+ questions?/);
});

test('the header offers Premium, not sign-in (playing never needs an account)', async ({
  page,
}) => {
  await page.goto('/');
  const nav = page.getByRole('navigation', { name: 'Main' });
  await expect(nav.getByRole('link', { name: 'Sign in' })).toHaveCount(0);
  await nav.getByRole('link', { name: 'Premium' }).click();
  await expect(page).toHaveURL(/\/pricing$/);
});

test('the homepage lists what Premium adds', async ({ page }) => {
  await page.goto('/');
  const premium = page.getByRole('region', { name: /Unlock \d+ extra categories/ });
  await expect(premium).toContainText('$2.99 once');
  await expect(premium.getByRole('list', { name: 'Premium categories' })).toContainText(
    'Time Travel',
  );
});

test('without a reachable API, the page says so instead of waiting', async ({ page }) => {
  await page.route(`${API}/**`, (route) => route.abort());
  await page.goto('/pricing');
  await expect(page.getByText('We can’t check whether checkout is open right now.')).toBeVisible();
  await expect(page.getByRole('button', { name: /Unlock/ })).toHaveCount(0);
});

test('with billing off, checkout is honestly unavailable', async ({ page }) => {
  await page.route(`${API}/v1/billing/config`, (route) => route.fulfill({ json: config(false) }));
  await page.goto('/pricing');
  await expect(page.getByText('Premium isn’t on sale on the website yet.')).toBeVisible();
});

test('with billing on, a signed-out visitor is asked to sign in first', async ({ page }) => {
  await page.route(`${API}/v1/billing/config`, (route) => route.fulfill({ json: config(true) }));
  await page.goto('/pricing');
  await page.getByRole('link', { name: 'Sign in to unlock' }).click();
  await expect(page).toHaveURL(/\/account\?next=pricing/);
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();
});

test('a signed-in visitor goes to checkout for the one-time unlock', async ({ page }) => {
  await signIn(page, false);
  await page.route(`${API}/v1/billing/config`, (route) => route.fulfill({ json: config(true) }));
  let checkoutBody: unknown;
  await page.route(`${API}/v1/billing/checkout`, (route) => {
    checkoutBody = route.request().postDataJSON();
    return route.fulfill({ json: { url: 'https://checkout.dodo.test/cks_1' } });
  });
  await page.route('https://checkout.dodo.test/**', (route) =>
    route.fulfill({ contentType: 'text/html', body: '<h1>Dodo checkout</h1>' }),
  );
  await page.goto('/pricing');
  await page.getByRole('button', { name: 'Unlock Premium for $2.99' }).click();
  await expect(page).toHaveURL('https://checkout.dodo.test/cks_1');
  expect(checkoutBody).toEqual({});
});

test('sign-in requires confirming 18 or older, for email and for Google', async ({ page }) => {
  let otpRequests = 0;
  await page.route('http://supabase.test/**', (route) => {
    if (route.request().url().includes('/otp')) otpRequests++;
    return route.fulfill({ json: {} });
  });
  await page.goto('/account');
  await page.getByLabel('Email').fill('host@example.test');
  await page.getByRole('button', { name: 'Send code' }).click();
  await expect(page.getByText(/aged 18 or over/)).toBeVisible();
  await page.getByRole('button', { name: 'Continue with Google' }).click();
  await expect(page).toHaveURL(/\/account$/);
  expect(otpRequests).toBe(0);
  await page.getByLabel('I’m 18 or older').check();
  await page.getByRole('button', { name: 'Send code' }).click();
  await expect(page.getByText('We sent a 6-digit code to host@example.test.')).toBeVisible();
  expect(otpRequests).toBe(1);
});

test('Continue with Google goes to Google through Supabase and comes back to the page', async ({
  page,
}) => {
  await page.route('http://supabase.test/auth/v1/authorize**', (route) =>
    route.fulfill({ contentType: 'text/html', body: '<h1>Google</h1>' }),
  );
  await page.goto('/account?next=pricing');
  await page.getByLabel('I’m 18 or older').check();
  await page.getByRole('button', { name: 'Continue with Google' }).click();
  await expect(page).toHaveURL(/supabase\.test\/auth\/v1\/authorize/);
  const url = new URL(page.url());
  expect(url.searchParams.get('provider')).toBe('google');
  expect(url.searchParams.get('redirect_to')).toMatch(/\/auth\/callback\?next=%2Fpricing$/);
  expect(url.searchParams.get('code_challenge')).toBeTruthy(); // PKCE
});

test('a cancelled Google sign-in says so', async ({ page }) => {
  await page.goto('/auth/callback?error=access_denied&error_description=cancelled');
  await expect(page.getByRole('alert').filter({ hasText: 'Couldn’t sign you in' })).toContainText(
    'Google sign-in was cancelled.',
  );
  await page.getByRole('link', { name: 'Try again' }).click();
  await expect(page).toHaveURL(/\/account$/);
});

test('after checkout, the account page confirms Premium with a celebration', async ({ page }) => {
  await signIn(page, false);
  // The webhook lands a moment after Dodo sends the buyer back.
  const paidAt = Date.now() + 1500;
  await page.route(`${API}/v1/me`, (route) => {
    return route.fulfill({
      json:
        Date.now() < paidAt
          ? account(false)
          : account(true, [
              {
                provider: 'dodo',
                planId: 'premium',
                status: 'active',
                purchasedAt: new Date().toISOString(),
              },
            ]),
    });
  });
  await page.goto('/account?checkout=success&payment_id=pay_1&status=succeeded');
  await expect(
    page.getByRole('status').filter({ hasText: 'Confirming your payment' }),
  ).toBeVisible();
  await expect(page).toHaveURL(/\/account$/); // Dodo's parameters are removed
  await expect(page.getByText('Premium is unlocked!')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText('Premium unlock via the website')).toBeVisible();
  await expect(page.getByText(/Yours to keep/)).toBeVisible();
  // The header catches up without a reload: Premium tag, no upgrade pill.
  await expect(page.getByRole('banner').locator('.premium-tag')).toBeVisible();
  await expect(
    page
      .getByRole('navigation', { name: 'Main' })
      .getByRole('link', { name: 'Premium', exact: true }),
  ).toHaveCount(0);
});

test('a declined checkout shows a failed card, not a pending one', async ({ page }) => {
  await signIn(page, false);
  await page.goto('/account?checkout=success&payment_id=pay_1&status=failed');
  const card = page.getByRole('alert').filter({ hasText: 'Your payment didn’t go through' });
  await expect(card).toContainText('You haven’t been charged.');
  await page.getByRole('button', { name: 'Dismiss' }).click();
  await expect(card).toHaveCount(0);
});

test('with Premium, the header shows a Premium badge instead of the upgrade pill', async ({
  page,
}) => {
  await signIn(page, true);
  await page.goto('/');
  const header = page.getByRole('banner');
  await expect(header.locator('.premium-tag:not(.if-premium)')).toHaveText('Premium');
  await expect(
    page
      .getByRole('navigation', { name: 'Main' })
      .getByRole('link', { name: 'Premium', exact: true }),
  ).toHaveCount(0);
  const section = page.getByRole('region', { name: /Unlock \d+ extra categories/ });
  await expect(section).toContainText('You have Premium');
  await expect(section.getByRole('link', { name: /Unlock Premium/ })).toHaveCount(0);
});

test('with Premium, the Premium page says it is unlocked and offers no checkout', async ({
  page,
}) => {
  await signIn(page, true);
  await page.route(`${API}/v1/billing/config`, (route) => route.fulfill({ json: config(true) }));
  await page.goto('/pricing');
  await expect(page.getByText('Unlocked on this account')).toBeVisible();
  await expect(page.getByRole('button', { name: /Unlock Premium/ })).toHaveCount(0);
  await expect(page.getByRole('link', { name: 'Play now' })).toBeVisible();
});

test('without Premium, a signed-in visitor still sees the upgrade pill', async ({ page }) => {
  await signIn(page, false);
  await page.goto('/');
  await expect(
    page
      .getByRole('navigation', { name: 'Main' })
      .getByRole('link', { name: 'Premium', exact: true }),
  ).toBeVisible();
  await expect(page.getByRole('banner').locator('.premium-tag')).toHaveCount(0);
});

test('signed in, the header has an avatar button to your account', async ({ page }) => {
  await signIn(page, false);
  await page.goto('/');
  const nav = page.getByRole('navigation', { name: 'Main' });
  const avatar = nav.getByRole('link', { name: 'Your account' });
  await expect(avatar).toHaveText('H');
  await avatar.click();
  await expect(page).toHaveURL(/\/account$/);
});

test('signed out, the header has no account button', async ({ page }) => {
  await page.goto('/');
  await expect(
    page.getByRole('navigation', { name: 'Main' }).getByRole('link', { name: /Your account/ }),
  ).toHaveCount(0);
});

test('with Premium, the avatar says so', async ({ page }) => {
  await signIn(page, true);
  await page.goto('/');
  await expect(
    page.getByRole('navigation', { name: 'Main' }).getByRole('link', {
      name: 'Your account (Premium)',
    }),
  ).toBeVisible();
});

test('reloading as a Premium account never flashes the upgrade pill', async ({ page }) => {
  await signIn(page, true);
  await page.goto('/');
  const nav = page.getByRole('navigation', { name: 'Main' });
  const pill = nav.getByRole('link', { name: 'Premium', exact: true });
  await expect(page.getByRole('banner').locator('.premium-tag')).toBeVisible();
  // Now the API is slow to answer: the device's hint decides what shows meanwhile.
  await page.route(`${API}/v1/me`, async (route) => {
    await new Promise((r) => setTimeout(r, 2500));
    await route.fulfill({ json: account(true) });
  });
  const seen: boolean[] = [];
  await page.exposeFunction('notePill', (visible: boolean) => seen.push(visible));
  await page.addInitScript(() => {
    const check = () => {
      const el = document.querySelector('a[href="/pricing"].premium-pill');
      (window as unknown as { notePill: (v: boolean) => void }).notePill(
        !!el && getComputedStyle(el).display !== 'none',
      );
    };
    document.addEventListener('DOMContentLoaded', check);
    requestAnimationFrame(check);
    setTimeout(check, 300);
    setTimeout(check, 1000);
  });
  await page.reload();
  await expect(page.getByRole('banner').locator('.premium-tag:visible')).toBeVisible();
  await expect(pill).toHaveCount(0, { timeout: 5000 });
  await page.waitForTimeout(1200);
  expect(seen.length).toBeGreaterThan(0);
  expect(seen).not.toContain(true);
});

test('a free account on the same device gets the upgrade pill back', async ({ page }) => {
  await signIn(page, false);
  await page.addInitScript(() => localStorage.setItem('gleefy.premium-hint.v1', '1'));
  await page.goto('/');
  await expect(
    page
      .getByRole('navigation', { name: 'Main' })
      .getByRole('link', { name: 'Premium', exact: true }),
  ).toBeVisible();
  await expect(page.getByRole('banner').locator('.premium-tag')).toHaveCount(0);
  expect(await page.evaluate(() => localStorage.getItem('gleefy.premium-hint.v1'))).toBeNull();
});
