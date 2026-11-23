import { describe, expect, it } from 'vitest';

import { buildStructureTree } from './st-ipg-structure';
import type { StIpgTreeNodeDto } from '@/api/st-ipg-structure-api';

describe('buildStructureTree', () => {
  it('собирает вложенное дерево из плоского fnSt', () => {
    const flat: StIpgTreeNodeDto[] = [
      {
        childKey: 1,
        parentKey: null,
        stpnNum: null,
        pnLevel: 0,
        stNum: '+.',
        name: 'Корень',
        stRelKey: null,
        stNetPnKey: null
      },
      {
        childKey: 2,
        parentKey: 1,
        stpnNum: 1,
        pnLevel: 1,
        stNum: '+.01.',
        name: 'Раздел',
        stRelKey: 10,
        stNetPnKey: 20
      },
      {
        childKey: 3,
        parentKey: 2,
        stpnNum: 1,
        pnLevel: 2,
        stNum: '+.01.01.',
        name: 'Лист',
        stRelKey: 11,
        stNetPnKey: 21
      }
    ];

    const tree = buildStructureTree(flat);
    expect(tree).toHaveLength(1);
    expect(tree[0].key).toBe(1);
    expect(tree[0].leaf).toBe(false);
    expect(tree[0].children).toHaveLength(1);
    expect(tree[0].children?.[0].key).toBe(2);
    expect(tree[0].children?.[0].children?.[0].key).toBe(3);
    expect(tree[0].children?.[0].children?.[0].leaf).toBe(true);
  });
});
