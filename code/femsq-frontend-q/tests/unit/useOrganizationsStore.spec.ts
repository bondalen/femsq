import { beforeEach, describe, expect, it, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';

import { useOrganizationsStore } from '@/stores/organizations';
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

describe('useOrganizationsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('loads organizations and selects the first one', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([
      { ogKey: 1, ogName: 'Org 1' },
      { ogKey: 2, ogName: 'Org 2' }
    ]));
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogAgKey: 10, code: 'AG-10', organizationKey: 1 }]));

    const store = useOrganizationsStore();
    await store.fetchOrganizations();

    expect(apiGetMock).toHaveBeenNthCalledWith(1, '/api/v1/organizations', expect.objectContaining({ query: expect.any(Object) }));
    expect(apiGetMock).toHaveBeenNthCalledWith(2, '/api/v1/organizations/1/agents');
    expect(store.organizations).toHaveLength(2);
    expect(store.selectedOrganization?.ogKey).toBe(1);
    expect(store.agents).toHaveLength(1);
    expect(store.pagination.totalElements).toBe(2);
  });

  it('applies ogName filter and resets page', async () => {
    apiGetMock.mockResolvedValue(createResponse([{ ogKey: 1, ogName: 'Filtered Org' }], { totalElements: 1, page: 0, size: 10 }));

    const store = useOrganizationsStore();
    await store.updateNameFilter('Filter');

    expect(apiGetMock).toHaveBeenCalledWith(
      '/api/v1/organizations',
      expect.objectContaining({ query: expect.objectContaining({ ogName: 'Filter', page: 0 }) })
    );
    expect(store.pagination.page).toBe(1);
  });

  it('updates page size and refetches data', async () => {
    apiGetMock.mockResolvedValue(createResponse([{ ogKey: 1, ogName: 'Org' }], { totalElements: 1, page: 0, size: 5 }));

    const store = useOrganizationsStore();
    await store.setPageSize(5);

    expect(apiGetMock).toHaveBeenCalled();
    expect(store.pagination.size).toBe(5);
    expect(store.pagination.page).toBe(1);
  });

  it('handles errors when loading organizations', async () => {
    const error = new RequestError('Network error', { status: 500, statusText: 'Server Error', url: '/api/v1/organizations' });
    apiGetMock.mockRejectedValueOnce(error);

    const store = useOrganizationsStore();
    await store.fetchOrganizations();

    expect(store.error).toBe('Network error');
    expect(store.organizations).toHaveLength(0);
    expect(store.selectedOrganization).toBeNull();
  });

  it('fetches agents for selected organization', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogKey: 1, ogName: 'Org' }]));
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogAgKey: 10, code: 'AG-10', organizationKey: 1 }]));
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogAgKey: 20, code: 'AG-20', organizationKey: 1 }]));

    const store = useOrganizationsStore();
    await store.fetchOrganizations();
    await store.selectOrganization(1);

    expect(apiGetMock).toHaveBeenLastCalledWith('/api/v1/organizations/1/agents');
    expect(store.agents).toHaveLength(1);
  });

  it('updates current page', async () => {
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogKey: 1, ogName: 'Org' }], { totalElements: 1, page: 1, size: 10 }));
    apiGetMock.mockResolvedValueOnce(createResponse([{ ogAgKey: 10, code: 'AG-10', organizationKey: 1 }]));

    const store = useOrganizationsStore();
    await store.setPage(2);

    expect(apiGetMock).toHaveBeenCalledWith(
      '/api/v1/organizations',
      expect.objectContaining({ query: expect.objectContaining({ page: 1 }) })
    );
    expect(store.pagination.page).toBe(1);
  });
});
