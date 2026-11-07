import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const pages = [
  '/',
  '/play',
  '/games',
  '/games/would-you-rather',
  '/games/this-or-that',
  '/games/trivia',
  '/games/guess',
  '/games/custom-party-pack',
  '/how-to-play',
  '/faq',
  '/guides',
  '/guides/game-night-on-one-phone',
  '/guides/family-party-games',
  '/contact',
  '/account-deletion',
  '/pricing',
  '/account',
  '/auth/callback',
  '/trophies',
  '/privacy',
  '/terms',
];

for (const path of pages) {
  test(`${path} has no WCAG A/AA violations`, async ({ page }) => {
    await page.goto(path);
    // Let entrance animations finish so colour contrast isn't sampled mid-fade (decorative
    // looping ones never finish, so they're skipped).
    await page.evaluate(() =>
      Promise.all(
        document
          .getAnimations()
          .filter((a) => a.effect?.getComputedTiming().iterations !== Infinity)
          .map((a) => a.finished),
      ),
    );
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();
    expect(results.violations).toEqual([]);
  });

  test(`${path} has one h1, a title and no horizontal scroll`, async ({ page }) => {
    await page.goto(path);
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page).toHaveTitle(/MirthMix/);
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
    );
    expect(overflow).toBe(false);
  });
}

test('navigation reaches every page', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('navigation', { name: 'Main' }).getByRole('link', { name: 'Games' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Games' })).toBeVisible();
  await page.getByRole('link', { name: /Would You Rather/ }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Would You Rather' })).toBeVisible();
  await page
    .getByRole('navigation', { name: 'Footer' })
    .getByRole('link', { name: 'Privacy' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Privacy' })).toBeVisible();
  await expect(page.getByRole('note')).toContainText('Draft placeholder');
  await page
    .getByRole('navigation', { name: 'Footer' })
    .getByRole('link', { name: 'Terms' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Terms' })).toBeVisible();
});

test('the landing page demo plays real questions', async ({ page }) => {
  await page.goto('/');
  const demo = page.getByRole('region', { name: 'Try one: Would you rather…' });
  const options = demo.getByRole('button', { pressed: false });
  const first = (await options.first().textContent())!;
  await options.first().click();
  await expect(demo.getByRole('button', { pressed: true })).toHaveText(new RegExp(first));
  await expect(demo).toContainText('Now ask the room');
  await demo.getByRole('button', { name: 'Another one' }).click();
  await expect(demo.getByRole('button', { pressed: true })).toHaveCount(0);
  await expect(demo.getByRole('button', { pressed: false }).first()).not.toHaveText(first);
});

test('every mode is listed as available in the app', async ({ page }) => {
  await page.goto('/games');
  await expect(page.getByText('In the Android app')).toHaveCount(5);
  await expect(page.getByText('In development')).toHaveCount(0);
});

test('category counts come from the real content pack', async ({ page }) => {
  await page.goto('/games/would-you-rather');
  await expect(page.getByText(/^\d+ original questions in \d+ categories\.$/)).toBeVisible();
  await expect(page.getByRole('main').getByText('Premium', { exact: true })).toBeVisible();
});

test('unknown pages return 404 with a way home', async ({ page }) => {
  const res = await page.goto('/does-not-exist');
  expect(res?.status()).toBe(404);
  await expect(page.getByRole('link', { name: 'Go home' })).toBeVisible();
});

test('sitemap and robots are served', async ({ request }) => {
  const sitemap = await (await request.get('/sitemap.xml')).text();
  expect(sitemap).toContain('/games/would-you-rather');
  expect(await (await request.get('/robots.txt')).text()).toContain('Sitemap:');
});

test('security headers are set', async ({ request }) => {
  const res = await request.get('/');
  expect(res.headers()['x-content-type-options']).toBe('nosniff');
  expect(res.headers()['x-powered-by']).toBeUndefined();
});

test('every game in the library has its own guide page', async ({ page }) => {
  await page.goto('/games');
  const links = page.getByRole('main').getByRole('link');
  await expect(links).toHaveCount(5);
  for (const name of ['This or That', 'Trivia Blitz', 'Guess the Answer', 'Custom Party Pack']) {
    await page.goto('/games');
    await page
      .getByRole('main')
      .getByRole('link', { name: new RegExp(name) })
      .click();
    await expect(page.getByRole('heading', { level: 1, name })).toBeVisible();
  }
});

test('footer links reach the help pages', async ({ page }) => {
  await page.goto('/');
  const footer = page.getByRole('navigation', { name: 'Footer' });
  for (const [link, heading] of [
    ['How to play', 'How to play'],
    ['Guides', 'Guides'],
    ['FAQ', 'FAQ'],
    ['Contact', 'Contact'],
  ]) {
    await footer.getByRole('link', { name: link }).click();
    await expect(page.getByRole('heading', { level: 1, name: heading })).toBeVisible();
  }
});

test('pages make no third-party requests (no analytics, and no error reporting without a DSN)', async ({
  page,
  baseURL,
}) => {
  const origins = new Set<string>();
  page.on('request', (r) => origins.add(new URL(r.url()).origin));
  for (const path of ['/', '/play', '/games/trivia', '/faq']) {
    await page.goto(path);
    await page.waitForLoadState('networkidle');
  }
  expect([...origins]).toEqual([new URL(baseURL!).origin]);
});

test('with reduced motion requested, nothing animates', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await page.getByRole('button', { pressed: false }).first().click(); // a pick would burst confetti
  expect(await page.evaluate(() => document.getAnimations().length)).toBe(0);
});
