import { beforeEach, describe, expect, it, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';

import { usePlanGroupsStore } from '@/stores/lookups/plan-groups';
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

describe('usePlanGroupsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('loads plan groups and builds map', async () => {
    apiGetMock.mockResolvedValueOnce([
      { planGroupKey: 1, name: 'Group 1' },
      { planGroupKey: 2, name: 'Group 2' }
    ]);

    const store = usePlanGroupsStore();
    await store.fetchPlanGroups();

    expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/plan-groups');
    expect(store.planGroups).toHaveLength(2);
    expect(store.utPlGrMap.get(1)).toBe('Group 1');
    expect(store.utPlGrMap.get(2)).toBe('Group 2');
  });

  it('getPlanGroupName returns name for valid key', () => {
    const store = usePlanGroupsStore();
    store.planGroups = [
      { planGroupKey: 1, name: 'Group 1' },
      { planGroupKey: 2, name: 'Group 2' }
    ];

    expect(store.getPlanGroupName(1)).toBe('Group 1');
    expect(store.getPlanGroupName(2)).toBe('Group 2');
  });

  it('getPlanGroupName returns null for invalid key', () => {
    const store = usePlanGroupsStore();
    store.planGroups = [
      { planGroupKey: 1, name: 'Group 1' }
    ];

    expect(store.getPlanGroupName(999)).toBeNull();
    expect(store.getPlanGroupName(null)).toBeNull();
    expect(store.getPlanGroupName(undefined)).toBeNull();
  });

  it('handles errors when loading plan groups', async () => {
    const error = new RequestError('Network error', { status: 500, statusText: 'Server Error', url: '/api/v1/lookups/plan-groups' });
    apiGetMock.mockRejectedValueOnce(error);

    const store = usePlanGroupsStore();
    await expect(store.fetchPlanGroups()).rejects.toThrow();

    expect(store.error).toBe('Network error');
    expect(store.planGroups).toHaveLength(0);
  });

  it('resets store state', () => {
    const store = usePlanGroupsStore();
    store.planGroups = [{ planGroupKey: 1, name: 'Group 1' }];
    store.loading = true;
    store.error = 'Error';

    store.reset();

    expect(store.planGroups).toHaveLength(0);
    expect(store.loading).toBe(false);
    expect(store.error).toBeNull();
  });
});
