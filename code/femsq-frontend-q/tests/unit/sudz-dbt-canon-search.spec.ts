import { describe, expect, it } from 'vitest';

import { columnFiltersToSearchInput } from '@/stores/sudz-dbt-canon';

describe('columnFiltersToSearchInput', () => {
  it('не валит поиск СФ, если в dbtKey омоглиф/текст', () => {
    const parsed = columnFiltersToSearchInput({ dbtKey: 'А56', invNum: 'A56-69288' });
    expect('input' in parsed).toBe(true);
    if ('input' in parsed) {
      expect(parsed.input.dbtKey).toBeNull();
      expect(parsed.input.invNum).toBe('A56-69288');
    }
  });
});
