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

/** The face, hat and confetti on a 1024 canvas. */
const face = `
  <g stroke="${INK}" stroke-linejoin="round" stroke-linecap="round">
    <circle cx="512" cy="580" r="300" fill="#FFF6E5" stroke-width="30"/>
    <circle cx="372" cy="650" r="40" fill="#FF8FAB" stroke="none" opacity="0.75"/>
    <circle cx="652" cy="650" r="40" fill="#FF8FAB" stroke="none" opacity="0.75"/>
    <path d="M370 548q50-62 100 0M554 548q50-62 100 0" fill="none" stroke-width="34"/>
    <path d="M384 628Q512 820 640 628Z" fill="${INK}" stroke-width="22"/>
    <path d="M458 684q54 30 108 0q-10 34-54 36q-44-2-54-36z" fill="#FF5C8A" stroke="none"/>
    <path d="M548 292 742 72 790 350Z" fill="#FFB020" stroke-width="26"/>
    <path d="M622 232 754 196M650 290 770 262" fill="none" stroke="#C42654" stroke-width="22"/>
    <circle cx="742" cy="72" r="44" fill="#FFF6E5" stroke-width="22"/>
  </g>`;

const confetti = `
  <g stroke="none">
    <circle cx="190" cy="250" r="30" fill="#FFB020"/>
    <rect x="820" y="560" width="54" height="34" rx="8" fill="#FFF6E5" transform="rotate(-24 847 577)"/>
    <circle cx="150" cy="760" r="22" fill="#FFF6E5"/>
    <rect x="300" y="120" width="50" height="30" rx="8" fill="#FF8FAB" transform="rotate(20 325 135)"/>
  </g>`;

const gradient = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#6B2BD9"/>
      <stop offset="0.55" stop-color="#C42654"/>
      <stop offset="1" stop-color="#C2410C"/>
    </linearGradient>
  </defs>`;

/**
 * shape: 'square' (full bleed: Play Store, iOS), 'rounded' (Android legacy, web), 'none' (logo),
 * 'foreground' / 'background' (the two layers of Android's adaptive icon).
 */
function svg(shape) {
  if (shape === 'background') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">${gradient}<rect width="1024" height="1024" fill="url(#bg)"/>${confetti}</svg>\n`;
  }
  if (shape === 'foreground') {
    // Android shows only the middle 66 of 108 units; keep the face inside that circle.
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><g transform="translate(512 512) scale(0.56) translate(-512 -490)">${face}</g></svg>\n`;
  }
  const bg =
    shape === 'square'
      ? '<rect width="1024" height="1024" fill="url(#bg)"/>'
      : shape === 'rounded'
        ? '<rect width="1024" height="1024" rx="230" fill="url(#bg)"/>'
        : '';
  const body =
    shape === 'none'
      ? face
      : `${confetti}<g transform="translate(512 512) scale(0.86) translate(-512 -540)">${face}</g>`;
  const view = shape === 'none' ? '150 30 700 870' : '0 0 1024 1024';
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${view}" role="img" aria-label="Gleefy">${shape === 'none' ? '' : gradient}${bg}${body}</svg>\n`;
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
