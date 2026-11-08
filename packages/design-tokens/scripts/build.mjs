// Generates platform outputs from tokens.json:
//   dist/tokens.css   CSS custom properties (light + dark) for the web app
//   dist/index.js/.d.ts  typed token object for TypeScript consumers
//   apps/mobile/lib/theme/tokens.g.dart  Dart constants for Flutter (committed)
//
// `--check` regenerates in memory and fails if the committed Dart file is stale.
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const tokens = JSON.parse(readFileSync(join(root, 'tokens.json'), 'utf8'));
const dartPath = join(root, '../../apps/mobile/lib/theme/tokens.g.dart');
const checkOnly = process.argv.includes('--check');

const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
const union = (obj) =>
  Object.keys(obj)
    .map((s) => `'${s}'`)
    .join(' | ');
const HEADER = 'GENERATED FILE — do not edit. Source: packages/design-tokens/tokens.json';

const cssVars = (mode) =>
  Object.entries(tokens.color[mode]).map(([k, v]) => `--gf-${kebab(k)}: ${v};`);

function buildCss() {
  const shared = [];
  for (const [k, v] of Object.entries(tokens.font.size))
    shared.push(`--gf-font-size-${k}: ${v / 16}rem;`);
  for (const [k, v] of Object.entries(tokens.space)) shared.push(`--gf-space-${k}: ${v / 16}rem;`);
  for (const [k, v] of Object.entries(tokens.radius)) shared.push(`--gf-radius-${k}: ${v}px;`);
  for (const [k, v] of Object.entries(tokens.touch)) shared.push(`--gf-touch-${k}: ${v}px;`);
  const indent = (arr, n = 2) => arr.map((l) => ' '.repeat(n) + l).join('\n');
  return `/* ${HEADER} */
:root {
${indent([...shared, ...cssVars('light')])}
  color-scheme: light;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme='light']) {
${indent(cssVars('dark'), 4)}
    color-scheme: dark;
  }
}

:root[data-theme='dark'] {
${indent(cssVars('dark'))}
  color-scheme: dark;
}
`;
}

function buildJs() {
  const body = JSON.stringify(
    {
      color: tokens.color,
      font: tokens.font,
      space: tokens.space,
      radius: tokens.radius,
      touch: tokens.touch,
    },
    null,
    2,
  );
  const js = `// ${HEADER}\nexport const tokens = ${body};\nexport default tokens;\n`;
  const dts = `// ${HEADER}
export type ColorMode = 'light' | 'dark';
export type ColorTokens = { ${Object.keys(tokens.color.light)
    .map((k) => `${k}: string`)
    .join('; ')} };
export declare const tokens: {
  color: Record<ColorMode, ColorTokens>;
  font: {
    family: { display: string; sans: string };
    size: Record<${union(tokens.font.size)}, number>;
    weight: Record<${union(tokens.font.weight)}, number>;
  };
  space: Record<${union(tokens.space)}, number>;
  radius: Record<${union(tokens.radius)}, number>;
  touch: Record<${union(tokens.touch)}, number>;
};
export default tokens;
`;
  return { js, dts };
}

const dartColor = (hex) => `Color(0xFF${hex.replace('#', '').toUpperCase()})`;
// Dart identifiers can't start with a digit: space "2" -> s2, size "2xl" -> s2xl.
const dartIdent = (k) => (/^[0-9]/.test(k) ? `s${k}` : k);

function buildDart() {
  const colorClass = (mode) => {
    const name = mode === 'light' ? 'GfColorsLight' : 'GfColorsDark';
    const fields = Object.entries(tokens.color[mode])
      .map(([k, v]) => `  static const ${k} = ${dartColor(v)};`)
      .join('\n');
    return `abstract final class ${name} {\n${fields}\n}`;
  };
  const numClass = (name, obj) =>
    `abstract final class ${name} {\n${Object.entries(obj)
      .map(([k, v]) => `  static const double ${dartIdent(k)} = ${Number(v).toFixed(1)};`)
      .join('\n')}\n}`;
  return `// ${HEADER}
import 'package:flutter/painting.dart';

${colorClass('light')}

${colorClass('dark')}

${numClass('GfFontSize', tokens.font.size)}

${numClass('GfSpace', tokens.space)}

${numClass('GfRadius', tokens.radius)}

${numClass('GfTouch', tokens.touch)}

abstract final class GfFont {
  static const display = '${tokens.font.family.display}';
  static const sans = '${tokens.font.family.sans}';
}
`;
}

const dart = buildDart();
if (checkOnly) {
  const current = existsSync(dartPath) ? readFileSync(dartPath, 'utf8') : '';
  if (current !== dart) {
    console.error(
      'apps/mobile/lib/theme/tokens.g.dart is stale. Run `pnpm tokens` and commit the result.',
    );
    process.exit(1);
  }
  console.log('Design tokens: generated Dart file is up to date.');
} else {
  mkdirSync(join(root, 'dist'), { recursive: true });
  writeFileSync(join(root, 'dist/tokens.css'), buildCss());
  const { js, dts } = buildJs();
  writeFileSync(join(root, 'dist/index.js'), js);
  writeFileSync(join(root, 'dist/index.d.ts'), dts);
  mkdirSync(dirname(dartPath), { recursive: true });
  writeFileSync(dartPath, dart);
  console.log(
    'Design tokens built: dist/tokens.css, dist/index.js, apps/mobile/lib/theme/tokens.g.dart',
  );
}
