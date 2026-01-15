import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import * as auditsApi from '@/api/audits-api';
import type { RaADto, RaACreateRequest, RaAUpdateRequest } from '@/types/audits';

export const useAuditsStore = defineStore('audits', () => {
  const audits = ref<RaADto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const hasAudits = computed(() => audits.value.length > 0);

  async function fetchAudits(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      audits.value = await auditsApi.getAudits();
      lastUpdatedAt.value = new Date().toISOString();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось загрузить ревизии';
      error.value = message;
      console.error('[audits-store] Error fetching audits:', err);
      audits.value = [];
    } finally {
      loading.value = false;
    }
  }

  async function fetchAuditById(id: number): Promise<RaADto | null> {
    try {
      return await auditsApi.getAuditById(id);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось загрузить ревизию';
      error.value = message;
      console.error('[audits-store] Error fetching audit:', err);
      return null;
    }
  }

  async function createAudit(request: RaACreateRequest): Promise<RaADto | null> {
    error.value = null;
    try {
      const created = await auditsApi.createAudit(request);
      audits.value.push(created);
      return created;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось создать ревизию';
      error.value = message;
      console.error('[audits-store] Error creating audit:', err);
      throw err;
    }
  }

  async function updateAudit(id: number, request: RaAUpdateRequest): Promise<RaADto | null> {
    error.value = null;
    try {
      const updated = await auditsApi.updateAudit(id, request);
      const index = audits.value.findIndex(a => a.adtKey === id);
      if (index !== -1) {
        audits.value[index] = updated;
      }
      return updated;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось обновить ревизию';
      error.value = message;
      console.error('[audits-store] Error updating audit:', err);
      throw err;
    }
  }

  async function deleteAudit(id: number): Promise<boolean> {
    error.value = null;
    try {
      await auditsApi.deleteAudit(id);
      audits.value = audits.value.filter(a => a.adtKey !== id);
      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось удалить ревизию';
      error.value = message;
      console.error('[audits-store] Error deleting audit:', err);
      throw err;
    }
  }

  function clearError(): void {
    error.value = null;
  }

  return {
    audits,
    loading,
    error,
    lastUpdatedAt,
    hasAudits,
    fetchAudits,
    fetchAuditById,
    createAudit,
    updateAudit,
    deleteAudit,
    clearError
  };
});