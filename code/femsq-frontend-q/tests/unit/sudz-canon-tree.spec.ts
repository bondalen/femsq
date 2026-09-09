import { describe, expect, it } from 'vitest';

import type { SudzDbtCanonSlot } from '@/types/sudz';
import { buildCanonCommentTreeNodes, buildCanonTreeNodes, commentTreeExpandedKeys, defaultExpandedKeys } from '@/utils/sudz-canon-tree';

describe('sudz-canon-tree S78.4', () => {
  it('корни — слоты канона, Value с upl в заголовке', () => {
    const slots: SudzDbtCanonSlot[] = [
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
            comments: []
          }
        ]
      }
    ];
    const roots = buildCanonTreeNodes(slots);
    expect(roots).toHaveLength(1);
    expect(roots[0].id).toBe('slot:7');
    expect(roots[0].children?.map((c) => c.id)).toEqual(['var:7', 'vals:7']);
    const valuesFolder = roots[0].children?.[1];
    expect(valuesFolder?.children?.[0].id).toBe('val:55');
    expect(valuesFolder?.children?.[0].title).toContain('upl 901');
    expect(valuesFolder?.children?.[0].title).toContain('март');
    expect(defaultExpandedKeys(roots)).toEqual(['slot:7', 'vals:7']);
  });

  it('комментарии — листья DbtValue, корень Dbt', () => {
    const slots: SudzDbtCanonSlot[] = [
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
            comments: []
          }
        ]
      }
    ];
    const comments = [
      {
        id: 'cmm:local:1',
        valueKey: 55,
        groupKind: 'new' as const,
        typeKind: 'mery' as const,
        text: 'проверить оплату'
      }
    ];
    const roots = buildCanonCommentTreeNodes(4389, slots, comments);
    expect(roots[0].id).toBe('dbt:4389');
    const valueNode = roots[0].children?.[0].children?.[1].children?.[0];
    expect(valueNode?.id).toBe('val:55');
    expect(valueNode?.leaf).toBe(false);
    expect(valueNode?.children?.[0].id).toBe('cmm:local:1');
    expect(valueNode?.children?.[0].title).toContain('yr_CmmGr_New');
    expect(valueNode?.children?.[0].title).toContain('мероприятия');
    expect(commentTreeExpandedKeys(roots)).toEqual(['dbt:4389', 'slot:7', 'vals:7', 'val:55']);
  });
});
