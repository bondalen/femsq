import { beforeEach, describe, expect, it, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';

import { useInvestmentProgramsStore } from '@/stores/lookups/investment-programs';
import * as http from '@/api/http';

vi.mock('@/api/http', async () => {
  const actual = await vi.importActual<typeof http>('@/api/http');
  return {
    ...actual,
    apiGet: vi.fn()
  } satisfies Partial<typeof actual>;
});

const apiGetMock = vi.mocked(http.apiGet);
const { RequestError } = http;

describe('useInvestmentProgramsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('loads investment programs and builds map', async () => {
    apiGetMock.mockResolvedValueOnce([
      { ipgKey: 1, name: 'Program 1' },
      { ipgKey: 2, name: 'Program 2' }
    ]);

    const store = useInvestmentProgramsStore();
    await store.fetchInvestmentPrograms();

    expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/investment-programs');
    expect(store.investmentPrograms).toHaveLength(2);
    expect(store.ipgMap.get(1)).toBe('Program 1');
    expect(store.ipgMap.get(2)).toBe('Program 2');
  });

  it('getInvestmentProgramName returns name for valid key', () => {
    const store = useInvestmentProgramsStore();
    store.investmentPrograms = [
      { ipgKey: 1, name: 'Program 1' },
      { ipgKey: 2, name: 'Program 2' }
    ];

    expect(store.getInvestmentProgramName(1)).toBe('Program 1');
    expect(store.getInvestmentProgramName(2)).toBe('Program 2');
  });

  it('getInvestmentProgramName returns null for invalid key', () => {
    const store = useInvestmentProgramsStore();
    store.investmentPrograms = [
      { ipgKey: 1, name: 'Program 1' }
    ];

    expect(store.getInvestmentProgramName(999)).toBeNull();
    expect(store.getInvestmentProgramName(null)).toBeNull();
    expect(store.getInvestmentProgramName(undefined)).toBeNull();
  });

  it('handles errors when loading investment programs', async () => {
    const error = new RequestError('Network error', { status: 500, statusText: 'Server Error', url: '/api/v1/lookups/investment-programs' });
    apiGetMock.mockRejectedValueOnce(error);

    const store = useInvestmentProgramsStore();
    await expect(store.fetchInvestmentPrograms()).rejects.toThrow();

    expect(store.error).toBe('Network error');
    expect(store.investmentPrograms).toHaveLength(0);
  });

  it('resets store state', () => {
    const store = useInvestmentProgramsStore();
    store.investmentPrograms = [{ ipgKey: 1, name: 'Program 1' }];
    store.loading = true;
    store.error = 'Error';

    store.reset();

    expect(store.investmentPrograms).toHaveLength(0);
    expect(store.loading).toBe(false);
    expect(store.error).toBeNull();
  });
});
