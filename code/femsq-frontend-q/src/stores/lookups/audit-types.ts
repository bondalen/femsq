import { ref } from 'vue';
import { defineStore } from 'pinia';

import * as auditTypesApi from '@/api/audit-types-api';
import type { RaAtDto } from '@/types/audits';

export const useAuditTypesStore = defineStore('audit-types', () => {
  const auditTypes = ref<RaAtDto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function fetchAuditTypes(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      auditTypes.value = await auditTypesApi.getAuditTypes();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось загрузить типы ревизий';
      error.value = message;
      console.error('[audit-types-store] Error fetching audit types:', err);
      auditTypes.value = [];
    } finally {
      loading.value = false;
    }
  }

  return {
    auditTypes,
    loading,
    error,
    fetchAuditTypes
  };
});