// Content tooling.
//   validate  validate every pack, regenerate schema/pack.schema.json (for editor autocompletion)
//             and fail if the schema or the mobile copy of the packs is stale (`--check` in CI)
//   sync      copy packs into apps/mobile/assets/content/
//   review <out.csv>
//             export every trivia question as a spreadsheet for a second reviewer
//   mark-verified <reviewed.csv>
//             set reviewStatus "verified" (and verifiedOn today) on rows whose "ok" column is "yes"
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';
import type { TriviaPack } from '../src/schema.ts';
import { packSchema } from '../src/schema.ts';
import { csvRow, parseCsv } from '../src/csv.ts';
import { validatePack } from '../src/validate.ts';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const packsDir = join(root, 'packs');
const schemaPath = join(root, 'schema/pack.schema.json');
const mobileDir = join(root, '../../apps/mobile/assets/content');
const triviaPath = join(packsDir, 'trivia.json');
const [command, fileArg] = process.argv.slice(2);
const packFiles = readdirSync(packsDir)
  .filter((f) => f.endsWith('.json'))
  .sort();

function validate(): boolean {
  let ok = true;
  for (const file of packFiles) {
    const result = validatePack(JSON.parse(readFileSync(join(packsDir, file), 'utf8')));
    if (result.ok) {
      const cats = result.pack.categories.length;
      console.log(`✓ ${file}: ${result.pack.items.length} items in ${cats} categories`);
    } else {
      ok = false;
      console.error(`✗ ${file}`);
      for (const e of result.errors) console.error(`  - ${e}`);
    }
  }

  const schema = JSON.stringify(z.toJSONSchema(packSchema, { io: 'input' }), null, 2) + '\n';
  const current = existsSync(schemaPath) ? readFileSync(schemaPath, 'utf8') : '';
  if (current !== schema) {
    mkdirSync(dirname(schemaPath), { recursive: true });
    writeFileSync(schemaPath, schema);
    ok = false;
    console.error('schema/pack.schema.json was stale and has been regenerated. Commit it.');
  }

  for (const file of packFiles) {
    const copy = join(mobileDir, file);
    if (
      !existsSync(copy) ||
      readFileSync(copy, 'utf8') !== readFileSync(join(packsDir, file), 'utf8')
    ) {
      ok = false;
      console.error(`apps/mobile/assets/content/${file} is stale. Run \`pnpm content:sync\`.`);
    }
  }
  return ok;
}

const REVIEW_HEADER = [
  'id',
  'category',
  'difficulty',
  'question',
  'correct answer',
  'other choices',
  'explanation',
  'source',
  'status',
  'ok',
  'reviewer notes',
];

function review(out: string): void {
  const pack = JSON.parse(readFileSync(triviaPath, 'utf8')) as TriviaPack;
  const lines = [csvRow(REVIEW_HEADER)];
  for (const q of pack.items) {
    lines.push(
      csvRow([
        q.id,
        q.category,
        q.difficulty,
        q.question,
        q.choices[q.answer]!,
        q.choices.filter((_, i) => i !== q.answer).join(' | '),
        q.explanation,
        q.source,
        q.reviewStatus,
        q.reviewStatus === 'verified' ? 'yes' : '',
        '',
      ]),
    );
  }
  writeFileSync(out, lines.join('\n') + '\n');
  console.log(`Wrote ${pack.items.length} questions to ${out}.`);
  console.log('Check each against its source, then put "yes" in the ok column.');
}

function markVerified(file: string): void {
  const [header = [], ...rows] = parseCsv(readFileSync(file, 'utf8'));
  const idCol = header.indexOf('id');
  const okCol = header.indexOf('ok');
  if (idCol < 0 || okCol < 0) throw new Error('The sheet needs "id" and "ok" columns.');
  const approved = new Set(
    rows.filter((r) => r[okCol]?.trim().toLowerCase() === 'yes').map((r) => r[idCol]!),
  );
  const pack = JSON.parse(readFileSync(triviaPath, 'utf8')) as TriviaPack;
  const today = new Date().toISOString().slice(0, 10);
  let marked = 0;
  for (const q of pack.items) {
    if (approved.has(q.id) && q.reviewStatus !== 'verified') {
      q.reviewStatus = 'verified';
      q.verifiedOn = today;
      marked++;
    }
  }
  writeFileSync(triviaPath, JSON.stringify(pack, null, 2) + '\n');
  const unknown = [...approved].filter((id) => !pack.items.some((q) => q.id === id));
  if (unknown.length) console.error(`Unknown ids ignored: ${unknown.join(', ')}`);
  const verified = pack.items.filter((q) => q.reviewStatus === 'verified').length;
  console.log(`Marked ${marked} verified; ${verified} of ${pack.items.length} are now verified.`);
  console.log('Next: pnpm content:sync && pnpm content:validate, then commit.');
}

if (command === 'validate') {
  if (!validate()) process.exit(1);
} else if (command === 'sync') {
  mkdirSync(mobileDir, { recursive: true });
  for (const file of packFiles) copyFileSync(join(packsDir, file), join(mobileDir, file));
  console.log(`Copied ${packFiles.length} pack(s) to apps/mobile/assets/content/`);
} else if (command === 'review' && fileArg) {
  review(fileArg);
} else if (command === 'mark-verified' && fileArg) {
  markVerified(fileArg);
} else {
  console.error(
    'Usage: content.ts validate | sync | review <out.csv> | mark-verified <reviewed.csv>',
  );
  process.exit(2);
}
