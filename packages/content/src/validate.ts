import { MODE_PREFIX, packSchema, type Pack } from './schema.ts';

export type ValidationResult = { ok: true; pack: Pack } | { ok: false; errors: string[] };

const norm = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();

/**
 * Validates a pack's shape (JSON Schema-equivalent) and the rules a schema can't express:
 * unique ids, ids matching their category, known categories, no empty categories and no
 * duplicate questions.
 */
type AnyItem = Pack['items'][number];

/** Checks within one item and returns the text used to detect duplicate questions. */
function itemKey(item: AnyItem, errors: string[]): string {
  if ('name' in item) return norm(item.name);
  if ('a' in item) {
    if (norm(item.a) === norm(item.b)) errors.push(`${item.id}: both options are the same`);
    return [norm(item.a), norm(item.b)].sort().join(' | ');
  }
  if ('question' in item) {
    if (new Set(item.choices.map(norm)).size !== item.choices.length) {
      errors.push(`${item.id}: choices must be different`);
    }
    return norm(item.question);
  }
  if (new Set(item.clues.map(norm)).size !== item.clues.length) {
    errors.push(`${item.id}: clues must be different`);
  }
  for (const clue of item.clues) {
    if (norm(clue).includes(norm(item.answer)))
      errors.push(`${item.id}: a clue gives away the answer`);
  }
  return norm(item.answer);
}

export function validatePack(input: unknown): ValidationResult {
  const parsed = packSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`),
    };
  }
  const pack = parsed.data;
  const errors: string[] = [];
  const prefix = MODE_PREFIX[pack.mode];

  const categoryIds = new Set<string>();
  for (const c of pack.categories) {
    if (categoryIds.has(c.id)) errors.push(`categories: duplicate id "${c.id}"`);
    categoryIds.add(c.id);
  }

  const itemIds = new Set<string>();
  const questions = new Map<string, string>();
  const perCategory = new Map<string, number>();
  for (const item of pack.items) {
    if (itemIds.has(item.id)) errors.push(`items: duplicate id "${item.id}"`);
    itemIds.add(item.id);
    if (!categoryIds.has(item.category)) {
      errors.push(`${item.id}: unknown category "${item.category}"`);
    } else if (!item.id.startsWith(`${prefix}-${item.category}-`)) {
      errors.push(`${item.id}: id must start with "${prefix}-${item.category}-"`);
    }
    perCategory.set(item.category, (perCategory.get(item.category) ?? 0) + 1);

    const key = itemKey(item, errors);
    const dupe = questions.get(key);
    if (dupe) errors.push(`${item.id}: duplicate of ${dupe}`);
    else questions.set(key, item.id);
  }

  for (const id of categoryIds) {
    if (!perCategory.get(id)) errors.push(`category "${id}" has no items`);
  }

  if (pack.mode === 'dream-team') {
    const setIds = new Set<string>();
    for (const set of pack.roleSets) {
      if (setIds.has(set.id)) errors.push(`roleSets: duplicate id "${set.id}"`);
      setIds.add(set.id);
      const roleIds = set.roles.map((r) => r.id);
      if (new Set(roleIds).size !== roleIds.length) errors.push(`${set.id}: duplicate role ids`);
    }
    // Two sides fill every slot, plus one skip each, so a deck needs at least that many cards.
    const need = 2 * Math.max(...pack.roleSets.map((r) => r.roles.length)) + 2;
    for (const id of categoryIds) {
      if ((perCategory.get(id) ?? 0) < need)
        errors.push(`deck "${id}" needs at least ${need} cards`);
    }
  }

  return errors.length ? { ok: false, errors } : { ok: true, pack };
}
