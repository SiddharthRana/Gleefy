// Generates every Gleefy icon from one drawing: the grinning party face on the brand gradient.
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
    <radialGradient id="glow" cx="0.5" cy="0.52" r="0.55">
      <stop offset="0" stop-color="#FFE7A8" stop-opacity="0.55"/>
      <stop offset="0.55" stop-color="#FFB86B" stop-opacity="0.12"/>
      <stop offset="1" stop-color="#FFB86B" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="skin" cx="0.36" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="0.45" stop-color="#FFF4DD"/>
      <stop offset="1" stop-color="#FFD59A"/>
    </radialGradient>
    <linearGradient id="hat" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFE15C"/>
      <stop offset="1" stop-color="#FF9F1C"/>
    </linearGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="14"/></filter>
  </defs>`;

// Sunburst: 12 soft rays from the centre.
const rays = Array.from(
  { length: 12 },
  (_, i) =>
    `<path d="M512 512 L${512 + 900 * Math.cos(((i * 30 - 7) * Math.PI) / 180)} ${512 + 900 * Math.sin(((i * 30 - 7) * Math.PI) / 180)} L${512 + 900 * Math.cos(((i * 30 + 7) * Math.PI) / 180)} ${512 + 900 * Math.sin(((i * 30 + 7) * Math.PI) / 180)}Z"/>`,
).join('');

const background = `
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <g fill="#FFFFFF" opacity="0.08">${rays}</g>
  <rect width="1024" height="1024" fill="url(#glow)"/>`;

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

// The character, centred near (512, 560), tilted a little for personality.
const character = `
  <g transform="rotate(-6 512 560)">
    <circle cx="530" cy="600" r="318" fill="${INK}" opacity="0.35" filter="url(#soft)"/>
    <g stroke="${INK}" stroke-linejoin="round" stroke-linecap="round">
      <circle cx="512" cy="580" r="310" fill="url(#skin)" stroke-width="30"/>
      <ellipse cx="400" cy="400" rx="64" ry="34" fill="#FFFFFF" stroke="none" opacity="0.9" transform="rotate(-32 400 400)"/>
      <ellipse cx="352" cy="652" rx="52" ry="34" fill="#FF7FA0" stroke="none" opacity="0.7"/>
      <ellipse cx="672" cy="652" rx="52" ry="34" fill="#FF7FA0" stroke="none" opacity="0.7"/>
      <path d="M352 552q58-74 116 0M556 552q58-74 116 0" fill="none" stroke-width="38"/>
      <path d="M366 618Q512 860 658 618Z" fill="${INK}" stroke-width="24"/>
      <path d="M400 630Q512 668 624 630L616 652Q512 690 408 652Z" fill="#FFFFFF" stroke="none"/>
      <path d="M446 716q66 40 132 0q-10 44-66 48q-56-4-66-48z" fill="#FF5C8A" stroke="none"/>
    </g>
    <g transform="rotate(16 700 230)" stroke="${INK}" stroke-linejoin="round" stroke-linecap="round">
      <path d="M592 318 702 34 812 318Q702 352 592 318Z" fill="url(#hat)" stroke-width="26"/>
      <circle cx="668" cy="250" r="16" fill="#D4246A" stroke="none"/>
      <circle cx="736" cy="196" r="14" fill="#D4246A" stroke="none"/>
      <circle cx="718" cy="290" r="14" fill="#7B2FF7" stroke="none"/>
      <circle cx="690" cy="130" r="11" fill="#7B2FF7" stroke="none"/>
      <circle cx="702" cy="38" r="48" fill="#FFF6E5" stroke-width="22"/>
    </g>
  </g>`;

/** The character re-centred on its bounding box (hat pom-pom to shadow) and scaled. */
const placed = (scale) =>
  `<g transform="translate(512 512) scale(${scale}) translate(-515 -448)">${character}</g>`;

/**
 * shape: 'square' (full bleed: Play Store, iOS), 'rounded' (Android legacy, web), 'none' (logo),
 * 'foreground' / 'background' (the two layers of Android's adaptive icon).
 */
function svg(shape) {
  const open = (view) =>
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${view}" role="img" aria-label="Gleefy">${defs}`;
  switch (shape) {
    case 'none':
      return `${open('150 -40 730 980')}${character}</svg>\n`;
    case 'background':
      return `${open('0 0 1024 1024')}${background}${confetti}</svg>\n`;
    case 'foreground':
      // Android shows a circle of 72 of the layer's 108 units; the whole character stays inside it.
      return `${open('0 0 1024 1024')}${placed(0.66)}</svg>\n`;
    case 'rounded':
      return `${open('0 0 1024 1024')}<clipPath id="r"><rect width="1024" height="1024" rx="230"/></clipPath><g clip-path="url(#r)">${background}${confetti}</g>${placed(0.88)}</svg>\n`;
    default:
      return `${open('0 0 1024 1024')}${background}${confetti}${placed(0.88)}</svg>\n`;
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
// The app's in-screen logo (GleefyMark) is this image, at 3x for sharp phones.
await page.setViewportSize({ width: 438, height: 588 });
await page.setContent(
  `<html><body style="margin:0;background:transparent">${svg('none').replace('<svg ', '<svg width="438" height="588" ')}</body></html>`,
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
