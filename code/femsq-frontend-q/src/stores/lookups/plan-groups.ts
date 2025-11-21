import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import { apiGet, RequestError } from '@/api/http';

export interface InvestmentPlanGroupLookupDto {
  planGroupKey: number;
  name: string;
}

export const usePlanGroupsStore = defineStore('planGroups', () => {
  const planGroups = ref<InvestmentPlanGroupLookupDto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const utPlGrMap = computed<Map<number, string>>(() => {
    const map = new Map<number, string>();
    planGroups.value.forEach((item) => {
      map.set(item.planGroupKey, item.name);
    });
    return map;
  });

  function getPlanGroupName(key: number | null | undefined): string | null {
    if (key === null || key === undefined) {
      return null;
    }
    return utPlGrMap.value.get(key) ?? null;
  }

  async function fetchPlanGroups(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      console.info('[plan-groups-store] Fetching planGroups');
      const response = await apiGet<InvestmentPlanGroupLookupDto[]>('/api/v1/lookups/plan-groups');
      console.info('[plan-groups-store] Received response:', response);

      planGroups.value = response;
      lastUpdatedAt.value = new Date().toISOString();
    } catch (err) {
      console.error('[plan-groups-store] Error in fetchPlanGroups:', err);
      const message = err instanceof RequestError 
        ? err.message 
        : err instanceof Error 
          ? err.message 
          : 'Не удалось загрузить справочник групп планов';
      error.value = message;
      planGroups.value = [];
      throw err;
    } finally {
      loading.value = false;
    }
  }

  function reset(): void {
    planGroups.value = [];
    loading.value = false;
    error.value = null;
    lastUpdatedAt.value = '';
  }

  return {
    planGroups,
    utPlGrMap,
    loading,
    error,
    lastUpdatedAt,
    getPlanGroupName,
    fetchPlanGroups,
    reset
  };
});
