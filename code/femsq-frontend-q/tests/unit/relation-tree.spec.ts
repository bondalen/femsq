import { describe, expect, it } from 'vitest';

import {
  buildFolderNode,
  buildRecordNode,
  childTableOf,
  childrenAfterFolderLoad,
  childrenAfterRecordLoad,
  formatRelationTitle,
  patchRelationChildren,
  relationRootToken,
  shouldRebuildRelationTree
} from '@/trees/relation-tree';

describe('relation-tree walker', () => {
  it('rebuild только при смене (таблица, ключ)', () => {
    expect(relationRootToken('invNum', 85078)).toBe('invNum:85078');
    expect(shouldRebuildRelationTree('invNum', 85078, 'invNum:85078')).toBe(false);
    expect(shouldRebuildRelationTree('invNum', 85079, 'invNum:85078')).toBe(true);
    expect(shouldRebuildRelationTree('invNum', 85078, '')).toBe(true);
    expect(shouldRebuildRelationTree('invNum', null, 'invNum:85078')).toBe(true);
  });

  it('собирает заголовок из колонок spec', () => {
    expect(formatRelationTitle(['inKey', 'inNum'], { inKey: '85078', inNum: '832930' })).toBe(
      '85078 · 832930'
    );
  });

  it('N:1 дети — записи, 1:N — папка без строк', () => {
    const parent = buildRecordNode('inv', 85069, { iKey: '85069' }, {
      title: ['iKey'],
      detail: '*',
      children: [
        {
          edge: 'inv.cnInv',
          to: 'cnInv',
          card: '1:N',
          folder: 'СФ, связи с договорами',
          title: ['ciKey'],
          detail: '*',
          children: []
        }
      ]
    });
    const kids = childrenAfterRecordLoad(parent, {});
    expect(kids).toHaveLength(1);
    expect(kids[0].kind).toBe('folder');
    expect(kids[0].title).toBe('СФ, связи с договорами');
    expect(kids[0].table).toBe('cnInv');
    expect(kids[0].children).toBeUndefined();
  });

  it('папка после expand берёт to из JSON, не из каталога хоста', () => {
    const folder = buildFolderNode('inv:85069', 85069, {
      edge: 'not.in.catalog',
      to: 'cnInv',
      card: '1:N',
      folder: 'СФ, связи с договорами',
      title: ['ciKey', 'ciCn'],
      detail: '*',
      children: []
    });
    const kids = childrenAfterFolderLoad(folder, [
      { key: 87921, fields: { ciKey: '87921', ciCn: '2265' } }
    ]);
    expect(kids).toHaveLength(1);
    expect(kids[0].id).toBe('cnInv:87921');
    expect(kids[0].title).toBe('87921 · 2265');
    expect(kids[0].leaf).toBe(true);
  });

  it('N:1 запись после load использует spec.to', () => {
    const parent = buildRecordNode('invNum', 85078, { inKey: '85078' }, {
      title: ['inKey'],
      detail: '*',
      children: [
        {
          edge: 'custom.edge',
          to: 'inv',
          card: 'N:1',
          title: ['iKey'],
          detail: '*',
          children: []
        }
      ]
    });
    const kids = childrenAfterRecordLoad(parent, {
      'custom.edge': [{ key: 85069, fields: { iKey: '85069' } }]
    });
    expect(kids).toHaveLength(1);
    expect(kids[0].id).toBe('inv:85069');
    expect(kids[0].kind).toBe('record');
  });

  it('без to бросает', () => {
    expect(() =>
      childTableOf({
        edge: 'inv.cnInv',
        to: '',
        card: '1:N',
        title: ['ciKey'],
        detail: '*',
        children: []
      })
    ).toThrow(/без to/);
  });

  it('patch подставляет children по id', () => {
    const root = buildRecordNode('invNum', 1, { inKey: '1' }, {
      title: ['inKey'],
      detail: '*',
      children: [
        { edge: 'invNum.inv', to: 'inv', card: 'N:1', title: ['iKey'], detail: '*', children: [] }
      ]
    });
    const inv = buildRecordNode('inv', 2, { iKey: '2' }, {
      title: ['iKey'],
      detail: '*',
      children: []
    });
    const patched = patchRelationChildren([root], 'invNum:1', [inv]);
    expect(patched[0].children?.[0].id).toBe('inv:2');
    expect(root.children).toBeUndefined();
  });
});
