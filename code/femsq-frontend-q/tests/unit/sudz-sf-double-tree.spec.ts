import { describe, expect, it } from 'vitest';

import type { SudzSfDoubleDomainMatch } from '@/types/sudz';
import {
  buildSudzSfDoubleTree,
  collectExpandedKeys,
  dash
} from '@/utils/sudz-sf-double-tree';

function match(partial: Partial<SudzSfDoubleDomainMatch> & Pick<SudzSfDoubleDomainMatch, 'invKey'>): SudzSfDoubleDomainMatch {
  return {
    invNum: '2',
    invNumKey: 20,
    invEntered: '2024-01-02T00:00:00Z',
    ciKey: 100,
    cnKey: 356,
    cnNum: 'Д-1',
    ...partial
  };
}

describe('sudz-sf-double-tree', () => {
  it('dash подставляет тире', () => {
    expect(dash(null)).toBe('—');
    expect(dash('')).toBe('—');
    expect(dash(12)).toBe('12');
  });

  it('пустой selected даёт пустое дерево', () => {
    expect(buildSudzSfDoubleTree(null, [])).toEqual({
      nodes: [],
      expandedKeys: [],
      selectedKey: null
    });
  });

  it('строит корень с составными ключами и не дублирует invKey', () => {
    const selected = match({ invKey: 12, ciKey: 100 });
    const other = match({ invKey: 13, invNum: '2', ciKey: 101, cnKey: 357, cnNum: 'Д-2' });
    const duplicateLink = match({ invKey: 12, ciKey: 100 });
    const built = buildSudzSfDoubleTree(selected, [selected, duplicateLink, other]);

    expect(built.selectedKey).toBe('sf-root:12');
    expect(built.nodes).toHaveLength(1);

    const ids: string[] = [];
    const walk = (nodes: typeof built.nodes): void => {
      for (const node of nodes) {
        ids.push(node.id);
        if (node.children) walk(node.children);
      }
    };
    walk(built.nodes);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).toContain('sf-root:12:nums:sf:12');
    expect(ids).toContain('sf-root:12:nums:sf:13');
    expect(ids.filter((id) => id === 'sf-root:12:links:ci:100')).toHaveLength(1);

    const kinds = new Map<string, string>();
    const walkKind = (nodes: typeof built.nodes): void => {
      for (const node of nodes) {
        kinds.set(node.kind, node.id);
        if (node.children) walkKind(node.children);
      }
    };
    walkKind(built.nodes);
    expect(kinds.has('sgk-simple')).toBe(true);
    expect(kinds.has('sf-debts')).toBe(true);
    expect(kinds.has('cn-parties')).toBe(true);

    expect(collectExpandedKeys(built.nodes)).toEqual(built.expandedKeys);
    expect(built.expandedKeys).toContain('sf-root:12');
    expect(built.expandedKeys).toContain('sf-root:12:sgk');
    expect(built.expandedKeys).toContain('sf-root:12:debts');
  });

  it('рисует стороны, СГК и cn_inv_dbt из extras', () => {
    const selected = match({ invKey: 85069, ciKey: 87921, cnKey: 2265, cnNum: '1', invNum: '832930' });
    const built = buildSudzSfDoubleTree(selected, [selected], {
      contracts: {
        2265: {
          cn: {
            cnKey: 2265,
            cnNumber: '1',
            cnDate: null,
            cnNote: '1 ГазЭнергоСервис, ООО',
            cnMark: null
          },
          nums: [
            {
              cnnKey: 2254,
              cnnNum: '1',
              cnnCn: 2265,
              cnnType: 1,
              cnnTypeName: 'основной',
              cnnNote: 'вручную'
            }
          ],
          sides: [
            {
              cnSKey: 3141,
              cnKey: 2265,
              cnSType: 2,
              cnSTypeName: 'исполнитель',
              smpls: [
                {
                  csosKey: 3196,
                  csosCnS: 3141,
                  csosOrgId: 182,
                  orgLabel: '1010817 ГазЭнергоСервис, ООО',
                  csosTimeOfEntry: null,
                  orgs: [
                    {
                      cnSOrgKey: 2951,
                      csoCnSOrgSmpl: 3196,
                      dateBeg: null,
                      dateEnd: null,
                      csoAsbuId: null,
                      csoCnDate: '2024-05-03',
                      csoTimeOfEntry: null
                    }
                  ]
                }
              ]
            }
          ]
        }
      },
      smpls: [
        {
          ciasKey: 94732,
          ciasCnInv: 87921,
          ciasAccnt: 19,
          accountNum: 606012,
          ciasCnSOrgSmpl: 3196,
          ciasNote: null,
          ciasTimeOfEntry: null,
          accounts: [
            {
              ciaKey: 18674,
              ciaCnSOrg: 2951,
              ciaName: null,
              ciaNote: null,
              ciaCnInvAccntSmpl: 94732,
              ciaTimeOfEntry: null,
              debts: [
                {
                  cnInvDbtKey: 59543,
                  dateStart: '2025-04-09',
                  dateMaturity: '2026-12-31',
                  debtType: 'D',
                  dbtTtl: 32103268.75,
                  dbtOverd: 0,
                  docBase: null,
                  link: null,
                  uplKey: 28,
                  number: 366,
                  mark: null,
                  cidTimeOfEntry: null
                }
              ]
            }
          ]
        }
      ],
      invDbts: []
    });

    const titles: string[] = [];
    const walk = (nodes: typeof built.nodes): void => {
      for (const node of nodes) {
        titles.push(node.title);
        if (node.children) walk(node.children);
      }
    };
    walk(built.nodes);
    expect(titles).toContain('Сторона 1. исполнитель');
    expect(titles.some((title) => title.includes('ГазЭнергоСервис'))).toBe(true);
    expect(titles).toContain('cnInvAccntSmpl 94732');
    expect(titles).toContain('cn_inv_dbt 59543');
    expect(titles).toContain('СФ, задолженности');
  });
});
