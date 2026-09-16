import { describe, expect, it } from 'vitest';

import { normalizeExplorerPath } from '@/utils/explorer-path';

describe('normalizeExplorerPath', () => {
  it('оставляет обычный Windows-путь', () => {
    expect(normalizeExplorerPath('D:\\femsq\\excel\\a.xlsx')).toBe('D:\\femsq\\excel\\a.xlsx');
  });

  it('снимает кавычки Проводника', () => {
    expect(normalizeExplorerPath('"D:\\femsq\\a.xlsx"')).toBe('D:\\femsq\\a.xlsx');
  });

  it('убирает ведущий / перед диском', () => {
    expect(normalizeExplorerPath('/D:\\femsq\\excel\\test.xlsx')).toBe(
      'D:\\femsq\\excel\\test.xlsx'
    );
    expect(normalizeExplorerPath('/D:/femsq/a.xlsx')).toBe('D:/femsq/a.xlsx');
  });

  it('не трогает Unix-пути без диска', () => {
    expect(normalizeExplorerPath('/mnt/nb-win-share/femsq/a.xlsx')).toBe(
      '/mnt/nb-win-share/femsq/a.xlsx'
    );
  });

  it('trim пробелов', () => {
    expect(normalizeExplorerPath('  D:\\a.xlsx  ')).toBe('D:\\a.xlsx');
  });
});
