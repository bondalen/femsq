import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import { Notify } from 'quasar';
import * as auditsApi from '@/api/audits-api';
import type { RaADto, RaACreateRequest, RaAUpdateRequest } from '@/types/audits';
import type { AuditExecutionResult } from '@/api/audits-api';

let pollingTimer: number | null = null;

export const useAuditsStore = defineStore('audits', () => {
  const audits = ref<RaADto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  // Текущая ревизия, для которой активен polling (или null, если polling выключен)
  const pollingAuditId = ref<number | null>(null);
  const pollingErrorCount = ref(0);
  const pollingConnectionLost = ref(false);

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

  async function pollAuditStatus(id: number): Promise<void> {
    error.value = null;
    console.log('[audits-store] pollAuditStatus: tick', { id });
    try {
      const fresh = await auditsApi.getAuditById(id);
      const index = audits.value.findIndex(a => a.adtKey === id);
      if (index !== -1) {
        audits.value[index] = fresh;
      } else {
        audits.value.push(fresh);
      }
      lastUpdatedAt.value = new Date().toISOString();
      pollingErrorCount.value = 0;
      pollingConnectionLost.value = false;

      // Останавливаем polling, когда ревизия завершена (или упала)
      if (fresh.adtStatus === 'COMPLETED' || fresh.adtStatus === 'FAILED') {
        stopPolling();
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось обновить статус ревизии';
      error.value = message;
      pollingErrorCount.value += 1;
      console.error('[audits-store] Error polling audit status:', err, { id, pollingErrorCount: pollingErrorCount.value });
      throw err;
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

  async function executeAudit(id: number): Promise<AuditExecutionResult> {
    error.value = null;
    try {
      const result: AuditExecutionResult = await auditsApi.executeAudit(id);
      if (result.alreadyRunning) {
        Notify.create({
          type: 'warning',
          message: result.message ?? 'Ревизия уже выполняется',
          position: 'top'
        });
        return result;
      }

      if (result.started) {
        if (result.message) {
          Notify.create({
            type: 'positive',
            message: result.message,
            position: 'top'
          });
        }

        // Обновляем список и запускаем polling, чтобы UI увидел RUNNING/COMPLETED и лог.
        await fetchAudits();
        startPolling(id);
      }

      return result;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось выполнить ревизию';
      error.value = message;
      console.error('[audits-store] Error executing audit:', err);
      throw err;
    }
  }

  function startPolling(auditId: number, intervalMs = 3000): void {
    // Останавливаем предыдущий таймер, если он был
    stopPolling();

    console.log('[audits-store] startPolling: start', { auditId, intervalMs });
    pollingAuditId.value = auditId;
    pollingErrorCount.value = 0;
    pollingConnectionLost.value = false;

    pollingTimer = window.setInterval(async () => {
      try {
        if (pollingAuditId.value != null) {
          await pollAuditStatus(pollingAuditId.value);
        }
      } catch (err) {
        console.error('[audits-store] Error during polling pollAuditStatus:', err, {
          pollingAuditId: pollingAuditId.value,
          pollingErrorCount: pollingErrorCount.value
        });
        if (pollingErrorCount.value >= 3) {
          pollingConnectionLost.value = true;
          stopPolling();
        }
      }
    }, intervalMs);
  }

  function stopPolling(): void {
    if (pollingTimer !== null) {
      clearInterval(pollingTimer);
      pollingTimer = null;
    }
    console.log('[audits-store] stopPolling: stop', {
      previousAuditId: pollingAuditId.value,
      pollingErrorCount: pollingErrorCount.value,
      pollingConnectionLost: pollingConnectionLost.value
    });
    pollingAuditId.value = null;
  }

  function resetPollingState(): void {
    pollingErrorCount.value = 0;
    pollingConnectionLost.value = false;
  }

  function clearError(): void {
    error.value = null;
  }

  return {
    audits,
    loading,
    error,
    lastUpdatedAt,
    pollingAuditId,
    pollingErrorCount,
    pollingConnectionLost,
    hasAudits,
    fetchAudits,
    fetchAuditById,
    createAudit,
    updateAudit,
    deleteAudit,
    executeAudit,
    startPolling,
    stopPolling,
    resetPollingState,
    clearError
  };
});