import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import { apiGet, RequestError } from '@/api/http';

export interface InvestmentProgramLookupDto {
  ipgKey: number;
  name: string;
}

export const useInvestmentProgramsStore = defineStore('investmentPrograms', () => {
  const investmentPrograms = ref<InvestmentProgramLookupDto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const ipgMap = computed<Map<number, string>>(() => {
    const map = new Map<number, string>();
    investmentPrograms.value.forEach((item) => {
      map.set(item.ipgKey, item.name);
    });
    return map;
  });

  function getInvestmentProgramName(key: number | null | undefined): string | null {
    if (key === null || key === undefined) {
      return null;
    }
    return ipgMap.value.get(key) ?? null;
  }

  async function fetchInvestmentPrograms(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      console.info('[investment-programs-store] Fetching investmentPrograms');
      const response = await apiGet<InvestmentProgramLookupDto[]>('/api/v1/lookups/investment-programs');
      console.info('[investment-programs-store] Received response:', response);

      investmentPrograms.value = response;
      lastUpdatedAt.value = new Date().toISOString();
    } catch (err) {
      console.error('[investment-programs-store] Error in fetchInvestmentPrograms:', err);
      const message = err instanceof RequestError 
        ? err.message 
        : err instanceof Error 
          ? err.message 
          : 'Не удалось загрузить справочник инвестиционных программ';
      error.value = message;
      investmentPrograms.value = [];
      throw err;
    } finally {
      loading.value = false;
    }
  }

  function reset(): void {
    investmentPrograms.value = [];
    loading.value = false;
    error.value = null;
    lastUpdatedAt.value = '';
  }

  return {
    investmentPrograms,
    ipgMap,
    loading,
    error,
    lastUpdatedAt,
    getInvestmentProgramName,
    fetchInvestmentPrograms,
    reset
  };
});
