// Generates every Gleefy icon from one drawing: a phone in a party hat on the brand gradient
// (one phone, passed around the party).
//   node scripts/brand-icons.mjs
// Writes docs/brand (SVG sources, Play Store icon), the website icons, the Android launcher icons
// and the iOS app icons. Rasterised with Playwright's Chromium (already used by the web e2e tests).
import { mkdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(join(root, 'apps/web/package.json'));
const { chromium } = require('@playwright/test');

const INK = '#1D1530';

const defs = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#7B2FF7"/>
      <stop offset="0.5" stop-color="#D4246A"/>
      <stop offset="1" stop-color="#F06A1D"/>
    </linearGradient>
    <linearGradient id="hat" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFE15C"/>
      <stop offset="1" stop-color="#FF9F1C"/>
    </linearGradient>
  </defs>`;

// Sunburst: 12 soft rays from the centre.
const rays = Array.from(
  { length: 12 },
  (_, i) =>
    `<path d="M512 512 L${512 + 900 * Math.cos(((i * 30 - 7) * Math.PI) / 180)} ${512 + 900 * Math.sin(((i * 30 - 7) * Math.PI) / 180)} L${512 + 900 * Math.cos(((i * 30 + 7) * Math.PI) / 180)} ${512 + 900 * Math.sin(((i * 30 + 7) * Math.PI) / 180)}Z"/>`,
).join('');

const background = `
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <g fill="#FFFFFF" opacity="0.08">${rays}</g>`;

const sparkle = (x, y, s, c = '#FFFFFF') =>
  `<path transform="translate(${x} ${y}) scale(${s})" d="M0-40C6-8 8-6 40 0C8 6 6 8 0 40C-6 8-8 6-40 0C-8-6-6-8 0-40Z" fill="${c}"/>`;

const confetti = `
  <g stroke="none">
    <rect x="132" y="210" width="62" height="34" rx="10" fill="#FFD23F" transform="rotate(-28 163 227)"/>
    <circle cx="858" cy="300" r="26" fill="#3DDCC8"/>
    <rect x="820" y="742" width="60" height="32" rx="10" fill="#FFF6E5" transform="rotate(32 850 758)"/>
    <circle cx="190" cy="790" r="24" fill="#3DDCC8"/>
    <rect x="236" y="96" width="44" height="26" rx="8" fill="#FF8FB1" transform="rotate(18 258 109)"/>
    <circle cx="905" cy="560" r="16" fill="#FFD23F"/>
    <path d="M118 520c26-30 52 30 78 0s52 30 78 0" fill="none" stroke="#FFF6E5" stroke-width="16" stroke-linecap="round"/>
    ${sparkle(830, 170, 1.1)}
    ${sparkle(150, 640, 0.75, '#FFE7A8')}
    ${sparkle(770, 880, 0.7)}
  </g>`;

// The character: a phone in a party hat, tilted for personality. Flat shapes with a chunky ink
// outline and a hard offset shadow, so it stays crisp from 20 px to the Play Store's 512 px.
const phone = (fill, stroke) =>
  `<rect x="312" y="360" width="400" height="500" rx="88" fill="${fill}"${stroke ? ` stroke="${INK}" stroke-width="32"` : ''}/>`;
const character = `
  <g transform="rotate(-10 512 610)" stroke-linejoin="round" stroke-linecap="round">
    <g transform="translate(30 30)" opacity="0.28">${phone(INK)}</g>
    ${phone('#FFFFFF', true)}
    <rect x="358" y="432" width="308" height="358" rx="42" fill="#7B2FF7"/>
    <rect x="466" y="390" width="92" height="20" rx="10" fill="${INK}"/>
    <rect x="470" y="810" width="84" height="18" rx="9" fill="#E3DDF0"/>
    <polygon points="512.0,484.0 548.4,573.8 645.1,580.7 571.0,643.2 594.3,737.3 512.0,686.0 429.7,737.3 453.0,643.2 378.9,580.7 475.6,573.8" fill="#FFD23F" stroke="${INK}" stroke-width="18"/>
    <circle cx="398" cy="480" r="16" fill="#3DDCC8"/>
    <circle cx="628" cy="750" r="14" fill="#FF8FB1"/>
    <rect x="600" y="468" width="34" height="18" rx="7" fill="#FFF6E5" transform="rotate(30 617 477)"/>
    <circle cx="396" cy="748" r="10" fill="#FFD23F"/>
    <g transform="rotate(22 590 380)" stroke="${INK}">
      <path d="M496 384 590 104 684 384Q590 410 496 384Z" fill="url(#hat)" stroke-width="28"/>
      <path d="M552 216q38 14 76 0M524 298q66 22 132 0" fill="none" stroke="#D4246A" stroke-width="22"/>
      <circle cx="590" cy="96" r="50" fill="#FFF6E5" stroke-width="24"/>
    </g>
  </g>`;

/** The character re-centred on its bounding box (pom-pom to shadow) and scaled. */
const placed = (scale) =>
  `<g transform="translate(512 512) scale(${scale}) translate(-539 -465)">${character}</g>`;

/**
 * shape: 'square' (full bleed: Play Store, iOS), 'rounded' (Android legacy, web), 'none' (logo),
 * 'foreground' / 'background' (the two layers of Android's adaptive icon).
 */
function svg(shape) {
  const open = (view) =>
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${view}" role="img" aria-label="Gleefy">${defs}`;
  switch (shape) {
    case 'none':
      return `${open('205 -15 665 960')}${character}</svg>\n`;
    case 'background':
      return `${open('0 0 1024 1024')}${background}${confetti}</svg>\n`;
    case 'foreground':
      // Android shows a circle of 72 of the layer's 108 units; the whole character stays inside it.
      return `${open('0 0 1024 1024')}${placed(0.6)}</svg>\n`;
    case 'rounded':
      return `${open('0 0 1024 1024')}<clipPath id="r"><rect width="1024" height="1024" rx="230"/></clipPath><g clip-path="url(#r)">${background}${confetti}</g>${placed(0.9)}</svg>\n`;
    default:
      return `${open('0 0 1024 1024')}${background}${confetti}${placed(0.9)}</svg>\n`;
  }
}

const out = (p, data) => {
  mkdirSync(dirname(join(root, p)), { recursive: true });
  writeFileSync(join(root, p), data);
  console.log(`wrote ${p}`);
};

out('docs/brand/icon.svg', svg('rounded'));
out('docs/brand/icon-square.svg', svg('square'));
out('docs/brand/logo.svg', svg('none'));
out('apps/web/src/app/icon.svg', svg('rounded'));
out('apps/web/public/logo.svg', svg('none'));
// The pre-launch coming-soon page (production) uses the same mark.
out('apps/web/coming-soon/logo.svg', svg('none'));
out('apps/web/coming-soon/favicon.svg', svg('rounded'));

const browser = await chromium.launch();
const page = await browser.newPage();
async function png(shape, size, path) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(
    `<html><body style="margin:0;background:transparent">${svg(shape).replace('<svg ', `<svg width="${size}" height="${size}" `)}</body></html>`,
  );
  out(
    path,
    await page.screenshot({
      omitBackground: shape !== 'square' && shape !== 'background',
      type: 'png',
    }),
  );
}

await png('square', 512, 'docs/brand/play-store-icon-512.png');
await png('square', 180, 'apps/web/src/app/apple-icon.png');
await png('square', 180, 'apps/web/coming-soon/apple-touch-icon.png');
// The app's in-screen logo (GleefyMark) is this image, at 3x for sharp phones.
await page.setViewportSize({ width: 333, height: 480 });
await page.setContent(
  `<html><body style="margin:0;background:transparent">${svg('none').replace('<svg ', '<svg width="333" height="480" ')}</body></html>`,
);
out(
  'apps/mobile/assets/brand/mark.png',
  await page.screenshot({ omitBackground: true, type: 'png' }),
);
// The full icon, shown big on the first onboarding page.
await png('rounded', 480, 'apps/mobile/assets/brand/icon.png');
for (const [dir, size] of [
  ['mdpi', 48],
  ['hdpi', 72],
  ['xhdpi', 96],
  ['xxhdpi', 144],
  ['xxxhdpi', 192],
]) {
  await png('rounded', size, `apps/mobile/android/app/src/main/res/mipmap-${dir}/ic_launcher.png`);
  // Adaptive icon layers are 108 dp (the legacy icon is 48 dp).
  const layer = Math.round((size * 108) / 48);
  await png(
    'foreground',
    layer,
    `apps/mobile/android/app/src/main/res/mipmap-${dir}/ic_launcher_foreground.png`,
  );
  await png(
    'background',
    layer,
    `apps/mobile/android/app/src/main/res/mipmap-${dir}/ic_launcher_background.png`,
  );
}
out(
  'apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
  `<?xml version="1.0" encoding="utf-8"?>
<!-- Adaptive launcher icon (Android 8+), generated by scripts/brand-icons.mjs. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`,
);
// iOS masks the corners itself and rejects transparency, so its icons are full bleed.
const ios = 'apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset';
for (const [name, size] of [
  ['20x20@1x', 20],
  ['20x20@2x', 40],
  ['20x20@3x', 60],
  ['29x29@1x', 29],
  ['29x29@2x', 58],
  ['29x29@3x', 87],
  ['40x40@1x', 40],
  ['40x40@2x', 80],
  ['40x40@3x', 120],
  ['60x60@2x', 120],
  ['60x60@3x', 180],
  ['76x76@1x', 76],
  ['76x76@2x', 152],
  ['83.5x83.5@2x', 167],
  ['1024x1024@1x', 1024],
]) {
  await png('square', size, `${ios}/Icon-App-${name}.png`);
}
await browser.close();
