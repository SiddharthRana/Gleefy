import { describe, expect, it } from 'vitest';
import { csvRow, parseCsv } from '../src/csv.ts';

describe('review sheet CSV', () => {
  it('round-trips quotes, commas and line breaks', () => {
    const fields = ['triv-x-001', 'Who said "hi", then left?', 'line one\nline two', ''];
    expect(parseCsv(csvRow(fields) + '\n')).toEqual([fields]);
  });

  it('reads unquoted fields and Windows line endings from spreadsheet apps', () => {
    expect(parseCsv('id,ok\r\ntriv-a-001,yes\r\ntriv-a-002,\r\n')).toEqual([
      ['id', 'ok'],
      ['triv-a-001', 'yes'],
      ['triv-a-002', ''],
    ]);
  });

  it('skips blank lines', () => {
    expect(parseCsv('a,b\n\n\nc,d\n')).toEqual([
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });
});
