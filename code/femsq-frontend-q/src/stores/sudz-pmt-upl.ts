/**
 * Pinia store экрана D «Загрузка платежей» (0072 visual v1).
 * Список — sudzPmUplLookups; лаунчер File / воронка cipu* — вне v1.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import { createSudzPmUpl, getSudzPmUplLookups } from '@/api/sudz-api';
import type { CreateSudzPmUplInput, SudzPmUplLookup } from '@/types/sudz';

function comparePmDateDesc(a: SudzPmUplLookup, b: SudzPmUplLookup): number {
  const da = a.date ?? '';
  const db = b.date ?? '';
  if (da !== db) {
    return db.localeCompare(da);
  }
  return b.pmKey - a.pmKey;
}

export const useSudzPmtUplStore = defineStore('sudz-pmt-upl', () => {
  const upls = ref<SudzPmUplLookup[]>([]);
  const selectedPmKey = ref<number | null>(null);
  const loading = ref(false);
  const saving = ref(false);
  const error = ref<string | null>(null);

  const selectedUpl = computed(() => {
    if (selectedPmKey.value == null) {
      return null;
    }
    return upls.value.find((u) => u.pmKey === selectedPmKey.value) ?? null;
  });

  /**
   * Загружает список пакетов cn_inv_pm_upl (новые сверху).
   */
  async function loadUpls(): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      const list = await getSudzPmUplLookups();
      upls.value = [...list].sort(comparePmDateDesc);
      if (selectedPmKey.value != null) {
        const still = upls.value.some((u) => u.pmKey === selectedPmKey.value);
        if (!still) {
          selectedPmKey.value = null;
        }
      }
      if (selectedPmKey.value == null && upls.value.length > 0) {
        selectedPmKey.value = upls.value[0].pmKey;
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Выбор строки списка.
   */
  function selectUpl(pmKey: number): void {
    selectedPmKey.value = pmKey;
    error.value = null;
  }

  /**
   * Создаёт пакет cn_inv_pm_upl и выбирает его.
   */
  async function createUpl(input: CreateSudzPmUplInput): Promise<SudzPmUplLookup | null> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createSudzPmUpl(input);
      await loadUpls();
      selectUpl(created.pmKey);
      return created;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return null;
    } finally {
      saving.value = false;
    }
  }

  return {
    upls,
    selectedPmKey,
    loading,
    saving,
    error,
    selectedUpl,
    loadUpls,
    selectUpl,
    createUpl
  };
});
