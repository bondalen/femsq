import { beforeEach, describe, expect, it, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';

import { useStNetworksStore } from '@/stores/lookups/st-networks';
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

describe('useStNetworksStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('loads stNetworks and builds map', async () => {
    apiGetMock.mockResolvedValueOnce([
      { stNetKey: 1, name: 'Network 1' },
      { stNetKey: 2, name: 'Network 2' }
    ]);

    const store = useStNetworksStore();
    await store.fetchStNetworks();

    expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/st-networks');
    expect(store.stNetworks).toHaveLength(2);
    expect(store.stNetworkMap.get(1)).toBe('Network 1');
    expect(store.stNetworkMap.get(2)).toBe('Network 2');
  });

  it('getStNetworkName returns name for valid key', () => {
    const store = useStNetworksStore();
    store.stNetworks = [
      { stNetKey: 1, name: 'Network 1' },
      { stNetKey: 2, name: 'Network 2' }
    ];

    expect(store.getStNetworkName(1)).toBe('Network 1');
    expect(store.getStNetworkName(2)).toBe('Network 2');
  });

  it('getStNetworkName returns null for invalid key', () => {
    const store = useStNetworksStore();
    store.stNetworks = [
      { stNetKey: 1, name: 'Network 1' }
    ];

    expect(store.getStNetworkName(999)).toBeNull();
    expect(store.getStNetworkName(null)).toBeNull();
    expect(store.getStNetworkName(undefined)).toBeNull();
  });

  it('handles errors when loading stNetworks', async () => {
    const error = new RequestError('Network error', { status: 500, statusText: 'Server Error', url: '/api/v1/lookups/st-networks' });
    apiGetMock.mockRejectedValueOnce(error);

    const store = useStNetworksStore();
    await expect(store.fetchStNetworks()).rejects.toThrow();

    expect(store.error).toBe('Network error');
    expect(store.stNetworks).toHaveLength(0);
  });

  it('resets store state', () => {
    const store = useStNetworksStore();
    store.stNetworks = [{ stNetKey: 1, name: 'Network 1' }];
    store.loading = true;
    store.error = 'Error';

    store.reset();

    expect(store.stNetworks).toHaveLength(0);
    expect(store.loading).toBe(false);
    expect(store.error).toBeNull();
  });

  it('prevents concurrent loading', async () => {
    apiGetMock.mockImplementation(() => new Promise(resolve => setTimeout(() => resolve([]), 100)));

    const store = useStNetworksStore();
    const promise1 = store.fetchStNetworks();
    const promise2 = store.fetchStNetworks();

    await Promise.all([promise1, promise2]);

    expect(apiGetMock).toHaveBeenCalledTimes(1);
  });
});
