import { beforeEach, describe, expect, it, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';

import { useInvestmentChainsStore } from '@/stores/investment-chains';
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

function createResponse<T>(content: T[], meta?: Partial<{ totalElements: number; totalPages: number; page: number; size: number }>) {
  return {
    content,
    totalElements: meta?.totalElements ?? content.length,
    totalPages: meta?.totalPages ?? 1,
    page: meta?.page ?? 0,
    size: meta?.size ?? content.length
  };
}

describe('useInvestmentChainsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('loads chains and selects the first one', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([
      { chainKey: 1, name: 'Chain 1', stNetKey: 10, stNetName: 'Network 1', year: 2024 },
      { chainKey: 2, name: 'Chain 2', stNetKey: 20, stNetName: 'Network 2', year: 2025 }
    ]));
    apiGetMock.mockResolvedValueOnce(createResponse([
      { relationKey: 100, chainKey: 1, investmentProgramKey: 1000, investmentProgramName: 'Program 1', planGroupKey: 2000, planGroupName: 'Group 1' }
    ]));

    const store = useInvestmentChainsStore();
    await store.fetchChains();

    expect(apiGetMock).toHaveBeenNthCalledWith(1, '/api/v1/ipg-chains', expect.objectContaining({ query: expect.any(Object) }));
    expect(apiGetMock).toHaveBeenNthCalledWith(2, '/api/v1/ipg-chains/1/relations');
    expect(store.chains).toHaveLength(2);
    expect(store.selectedChain?.chainKey).toBe(1);
    expect(store.relations).toHaveLength(1);
    expect(store.pagination.totalElements).toBe(2);
  });

  it('applies name filter and resets page', async () => {
    apiGetMock.mockResolvedValue(createResponse([
      { chainKey: 1, name: 'Filtered Chain', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ], { totalElements: 1, page: 0, size: 10 }));

    const store = useInvestmentChainsStore();
    await store.updateNameFilter('Filter');

    expect(apiGetMock).toHaveBeenCalledWith(
      '/api/v1/ipg-chains',
      expect.objectContaining({ query: expect.objectContaining({ name: 'Filter', page: 0 }) })
    );
    expect(store.pagination.page).toBe(1);
  });

  it('applies year filter', async () => {
    apiGetMock.mockResolvedValue(createResponse([
      { chainKey: 1, name: 'Chain 2024', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ], { totalElements: 1, page: 0, size: 10 }));

    const store = useInvestmentChainsStore();
    await store.updateYearFilter(2024);

    expect(apiGetMock).toHaveBeenCalledWith(
      '/api/v1/ipg-chains',
      expect.objectContaining({ query: expect.objectContaining({ year: 2024, page: 0 }) })
    );
    expect(store.pagination.page).toBe(1);
  });

  it('updates page size and refetches data', async () => {
    apiGetMock.mockResolvedValue(createResponse([
      { chainKey: 1, name: 'Chain', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ], { totalElements: 1, page: 0, size: 5 }));

    const store = useInvestmentChainsStore();
    await store.setPageSize(5);

    expect(apiGetMock).toHaveBeenCalled();
    expect(store.pagination.size).toBe(5);
    expect(store.pagination.page).toBe(1);
  });

  it('handles errors when loading chains', async () => {
    const error = new RequestError('Network error', { status: 500, statusText: 'Server Error', url: '/api/v1/ipg-chains' });
    apiGetMock.mockRejectedValueOnce(error);

    const store = useInvestmentChainsStore();
    await store.fetchChains();

    expect(store.error).toBe('Network error');
    expect(store.chains).toHaveLength(0);
    expect(store.selectedChain).toBeNull();
  });

  it('fetches relations for selected chain', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([
      { chainKey: 1, name: 'Chain', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ]));
    apiGetMock.mockResolvedValueOnce(createResponse([
      { relationKey: 100, chainKey: 1, investmentProgramKey: 1000, investmentProgramName: 'Program 1', planGroupKey: 2000, planGroupName: 'Group 1' }
    ]));
    apiGetMock.mockResolvedValueOnce(createResponse([
      { relationKey: 200, chainKey: 1, investmentProgramKey: 2000, investmentProgramName: 'Program 2', planGroupKey: null, planGroupName: null }
    ]));

    const store = useInvestmentChainsStore();
    await store.fetchChains();
    await store.selectChain(1);

    expect(apiGetMock).toHaveBeenLastCalledWith('/api/v1/ipg-chains/1/relations');
    expect(store.relations).toHaveLength(1);
  });

  it('updates current page', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([
      { chainKey: 1, name: 'Chain', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ], { totalElements: 1, page: 1, size: 10 }));
    apiGetMock.mockResolvedValueOnce(createResponse([
      { relationKey: 100, chainKey: 1, investmentProgramKey: 1000, investmentProgramName: 'Program 1', planGroupKey: null, planGroupName: null }
    ]));

    const store = useInvestmentChainsStore();
    await store.setPage(2);

    expect(apiGetMock).toHaveBeenCalledWith(
      '/api/v1/ipg-chains',
      expect.objectContaining({ query: expect.objectContaining({ page: 1 }) })
    );
    expect(store.pagination.page).toBe(1);
  });

  it('updates sort and refetches data', async () => {
    apiGetMock.mockResolvedValue(createResponse([
      { chainKey: 1, name: 'Chain', stNetKey: 10, stNetName: 'Network 1', year: 2024 }
    ], { totalElements: 1, page: 0, size: 10 }));
    apiGetMock.mockResolvedValueOnce(createResponse([
      { relationKey: 100, chainKey: 1, investmentProgramKey: 1000, investmentProgramName: 'Program 1', planGroupKey: null, planGroupName: null }
    ]));

    const store = useInvestmentChainsStore();
    await store.setSort('name,desc');

    expect(apiGetMock).toHaveBeenCalled();
    expect(store.pagination.sort).toBe('name,desc');
    expect(store.pagination.page).toBe(1);
  });

  it('resets store state', () => {
    const store = useInvestmentChainsStore();
    store.chains = [{ chainKey: 1, name: 'Chain', relationsCount: 0 }];
    store.selectedChainKey = 1;
    store.relations = [{ relationKey: 100, chainKey: 1, investmentProgramKey: 1000, investmentProgramName: 'Program 1', planGroupKey: null, planGroupName: null }];
    store.loading = true;
    store.error = 'Error';

    store.reset();

    expect(store.chains).toHaveLength(0);
    expect(store.selectedChainKey).toBeNull();
    expect(store.relations).toHaveLength(0);
    expect(store.loading).toBe(false);
    expect(store.error).toBeNull();
    expect(store.filters.name).toBe('');
    expect(store.filters.year).toBeNull();
  });
});
