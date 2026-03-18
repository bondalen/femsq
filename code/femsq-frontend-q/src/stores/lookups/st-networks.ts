import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import { RequestError } from '@/api/http';
import type { StNetworkDto } from '@/api/lookups-api';
import { getStNetworksLookup } from '@/api/lookups-api';

export const useStNetworksStore = defineStore('stNetworks', () => {
  const stNetworks = ref<StNetworkDto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const stNetworkMap = computed<Map<number, string>>(() => {
    const map = new Map<number, string>();
    stNetworks.value.forEach((item) => {
      map.set(item.stNetKey, item.name);
    });
    return map;
  });

  function getStNetworkName(key: number | null | undefined): string | null {
    if (key === null || key === undefined) {
      return null;
    }
    return stNetworkMap.value.get(key) ?? null;
  }

  async function fetchStNetworks(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      console.info('[st-networks-store] Fetching stNetworks (GraphQL)');
      const response = await getStNetworksLookup();
      console.info('[st-networks-store] Received response:', response);

      stNetworks.value = response;
      lastUpdatedAt.value = new Date().toISOString();
    } catch (err) {
      console.error('[st-networks-store] Error in fetchStNetworks:', err);
      const message = err instanceof RequestError 
        ? err.message 
        : err instanceof Error 
          ? err.message 
          : 'Не удалось загрузить справочник структур сетей';
      error.value = message;
      stNetworks.value = [];
      throw err;
    } finally {
      loading.value = false;
    }
  }

  function reset(): void {
    stNetworks.value = [];
    loading.value = false;
    error.value = null;
    lastUpdatedAt.value = '';
  }

  return {
    stNetworks,
    stNetworkMap,
    loading,
    error,
    lastUpdatedAt,
    getStNetworkName,
    fetchStNetworks,
    reset
  };
});
