/**
 * Стор планов UtPl / LmMn (C2 O2 §4.2).
 */

import { defineStore } from 'pinia';
import { ref } from 'vue';

import {
  createIpgUtPl,
  fetchIpgUtPlByIpg,
  fetchIpgUtPlPnLmMnGrid,
  upsertIpgUtPlPnLmMnMonth,
  type IpgUtPlDto,
  type IpgUtPlPnLmMnGridDto,
  type IpgUtPlPnLmMnMonthDto
} from '@/api/ipg-utpl-api';

export const useIpgUtPlStore = defineStore('ipg-utpl', () => {
  const plans = ref<IpgUtPlDto[]>([]);
  const selectedPlKey = ref<number | null>(null);
  const selectedIpgpKey = ref<number | null>(null);
  const grid = ref<IpgUtPlPnLmMnGridDto | null>(null);
  const loading = ref(false);
  const mutating = ref(false);
  const error = ref<string | null>(null);

  /**
   * Загрузить планы текущей ИП.
   */
  async function loadPlans(ipgKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      plans.value = await fetchIpgUtPlByIpg(ipgKey);
      if (
        selectedPlKey.value != null &&
        !plans.value.some((p) => p.iuplKey === selectedPlKey.value)
      ) {
        selectedPlKey.value = null;
        grid.value = null;
      }
      if (selectedPlKey.value == null && plans.value.length > 0) {
        selectedPlKey.value = plans.value[0].iuplKey;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      plans.value = [];
    } finally {
      loading.value = false;
    }
  }

  /**
   * Выбрать план агента.
   */
  function selectPlan(plKey: number | null): void {
    selectedPlKey.value = plKey;
    grid.value = null;
  }

  /**
   * Выбрать пункт и загрузить грид.
   */
  async function selectPoint(ipgpKey: number | null): Promise<void> {
    selectedIpgpKey.value = ipgpKey;
    grid.value = null;
    if (ipgpKey == null || selectedPlKey.value == null) {
      return;
    }
    await loadGrid();
  }

  /**
   * Перечитать грид LmMn.
   */
  async function loadGrid(): Promise<void> {
    if (selectedPlKey.value == null || selectedIpgpKey.value == null) {
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      grid.value = await fetchIpgUtPlPnLmMnGrid(
        selectedPlKey.value,
        selectedIpgpKey.value
      );
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      grid.value = null;
    } finally {
      loading.value = false;
    }
  }

  /**
   * Создать план агента.
   */
  async function createPlan(input: {
    ipgKey: number;
    agKey: number;
    name?: string | null;
  }): Promise<IpgUtPlDto | null> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createIpgUtPl(input);
      await loadPlans(input.ipgKey);
      selectedPlKey.value = created.iuplKey;
      return created;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      return null;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Сохранить ось C месяца.
   */
  async function saveMonth(row: IpgUtPlPnLmMnMonthDto): Promise<boolean> {
    if (selectedPlKey.value == null || selectedIpgpKey.value == null) {
      return false;
    }
    mutating.value = true;
    error.value = null;
    try {
      grid.value = await upsertIpgUtPlPnLmMnMonth({
        plKey: selectedPlKey.value,
        ipgpKey: selectedIpgpKey.value,
        month: row.month,
        lim212: row.lim212,
        lim195: row.lim195,
        lim172: row.lim172,
        lim187: row.lim187
      });
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      return false;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Сброс при смене ИП.
   */
  function reset(): void {
    plans.value = [];
    selectedPlKey.value = null;
    selectedIpgpKey.value = null;
    grid.value = null;
    error.value = null;
  }

  return {
    plans,
    selectedPlKey,
    selectedIpgpKey,
    grid,
    loading,
    mutating,
    error,
    loadPlans,
    selectPlan,
    selectPoint,
    loadGrid,
    createPlan,
    saveMonth,
    reset
  };
});
