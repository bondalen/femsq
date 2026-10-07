import { describe, expect, it } from 'vitest';

import type { SudzDbtCanonSlot } from '@/types/sudz';
import {
  DBT_CANON_COMMENTS_QUERY,
  DBT_CANON_VALUES_QUERY,
  DBT_CANON_VAR_QUERY,
  dbtCanonQueryRows,
  dbtCanonRootRows,
  dbtCanonRootsToken,
  slotKeyFromWalkNodeId,
  valueKeyFromWalkNodeId
} from '@/sudz/dbt-canon-tree';

const sampleSlots: SudzDbtCanonSlot[] = [
  {
    slotKey: 7,
    iKey: 3,
    idNum: 1,
    varKey: 44,
    cnNum: 'CN',
    invNum: 'INV',
    orgBuirg: 9,
    csoDate: '2020-01-01',
    accountKey: null,
    accountNum: null,
    values: [
      {
        valueKey: 55,
        uplKey: 901,
        ttl: 100,
        overd: 10,
        uplName: 'март',
        uplDate: '2026-04-01',
        uplStatusOnDate: '2026-03-31',
        comments: [
          {
            cmmKey: 9,
            valueKey: 55,
            cmmGrKey: 1,
            cmmGrName: 'g',
            groupKind: 'new',
            cnicType: 1,
            text: 'проверить'
          }
        ]
      }
    ]
  }
];

describe('dbt-canon-tree', () => {
  it('корни — слоты; token меняется с составом', () => {
    const roots = dbtCanonRootRows(sampleSlots);
    expect(roots).toHaveLength(1);
    expect(roots[0].key).toBe(7);
    expect(dbtCanonRootsToken(12, sampleSlots)).toContain('12|7:');
    expect(dbtCanonRootsToken(null, sampleSlots)).toBe('');
  });

  it('query var / values / comments', () => {
    const vars = dbtCanonQueryRows(DBT_CANON_VAR_QUERY, 7, sampleSlots);
    expect(vars[0]?.fields.find((f) => f.name === 'varKey')?.value).toBe('44');
    const values = dbtCanonQueryRows(DBT_CANON_VALUES_QUERY, 7, sampleSlots);
    expect(values[0]?.key).toBe(55);
    expect(values[0]?.fields.find((f) => f.name === 'ttl')?.value).toBe('100');
    const comments = dbtCanonQueryRows(DBT_CANON_COMMENTS_QUERY, 55, sampleSlots);
    expect(comments[0]?.key).toBe(9);
    expect(comments[0]?.fields.find((f) => f.name === 'text')?.value).toBe('проверить');
  });

  it('разбор id WalkTree → slot / value', () => {
    expect(slotKeyFromWalkNodeId('invDbt:7', sampleSlots)).toBe(7);
    expect(slotKeyFromWalkNodeId('invDbt:7/sudz.dbtCanon.values', sampleSlots)).toBe(7);
    expect(slotKeyFromWalkNodeId('DbtValue:55', sampleSlots)).toBe(7);
    expect(valueKeyFromWalkNodeId('DbtValue:55/sudz.dbtCanon.comments')).toBe(55);
  });
});
