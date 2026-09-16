/**
 * Pinia store экрана D «Загрузка платежей» (0073 лаунчер File).
 * Список — sudzPmUplLookups; шапка — sudzPmUplLauncher / updateSudzPmUplFile.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createSudzPmUpl,
  getSudzPmUplLauncher,
  getSudzPmUplLookups,
  runSudzPmtUplFunnel,
  updateSudzPmUplFile
} from '@/api/sudz-api';
import type {
  CreateSudzPmUplInput,
  SudzPmUplLookup,
  SudzPmtUplFile,
  SudzPmtUplFunnelResult,
  SudzPmtUplLauncher,
  UpdateSudzPmUplFileInput
} from '@/types/sudz';

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
  const launcher = ref<SudzPmtUplLauncher | null>(null);
  const loading = ref(false);
  const saving = ref(false);
  const funnelRunning = ref(false);
  const error = ref<string | null>(null);

  const selectedUpl = computed(() => {
    if (selectedPmKey.value == null) {
      return null;
    }
    return upls.value.find((u) => u.pmKey === selectedPmKey.value) ?? null;
  });

  const file = computed(() => launcher.value?.file ?? null);

  /**
   * Загружает карточку лаунчера (ensure File на backend).
   */
  async function loadLauncher(pmKey: number): Promise<void> {
    try {
      launcher.value = await getSudzPmUplLauncher(pmKey);
    } catch (e) {
      launcher.value = null;
      error.value = e instanceof Error ? e.message : String(e);
    }
  }

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
          launcher.value = null;
        }
      }
      if (selectedPmKey.value == null && upls.value.length > 0) {
        await selectUpl(upls.value[0].pmKey);
      } else if (selectedPmKey.value != null) {
        await loadLauncher(selectedPmKey.value);
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Выбор строки списка и загрузка лаунчера.
   */
  async function selectUpl(pmKey: number): Promise<void> {
    selectedPmKey.value = pmKey;
    loading.value = true;
    error.value = null;
    try {
      await loadLauncher(pmKey);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Создаёт пакет cn_inv_pm_upl (+ пустой File, B3) и выбирает его.
   */
  async function createUpl(input: CreateSudzPmUplInput): Promise<SudzPmUplLookup | null> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createSudzPmUpl(input);
      await loadUpls();
      await selectUpl(created.pmKey);
      return created;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return null;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Сохраняет path / sheet / флаги шапки File (upsert).
   */
  async function saveFile(input: Omit<UpdateSudzPmUplFileInput, 'pmKey'>): Promise<boolean> {
    if (selectedPmKey.value == null) {
      return false;
    }
    saving.value = true;
    error.value = null;
    try {
      const updated: SudzPmtUplFile = await updateSudzPmUplFile({
        pmKey: selectedPmKey.value,
        ...input
      });
      if (launcher.value) {
        launcher.value = {
          ...launcher.value,
          file: updated
        };
      } else {
        await loadLauncher(selectedPmKey.value);
      }
      return true;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Алиас saveFile для UI-флагов.
   */
  async function patchFileFlags(input: Omit<UpdateSudzPmUplFileInput, 'pmKey'>): Promise<boolean> {
    return saveFile(input);
  }

  /**
   * Прогон воронки (excelToTbl при cipufFlTbl; cipu* — stub в логе).
   */
  async function runFunnel(steps: string[], flLoad: boolean): Promise<SudzPmtUplFunnelResult | null> {
    if (selectedPmKey.value == null) {
      return null;
    }
    funnelRunning.value = true;
    error.value = null;
    try {
      const result = await runSudzPmtUplFunnel({
        pmKey: selectedPmKey.value,
        steps,
        flLoad
      });
      await loadLauncher(selectedPmKey.value);
      return result;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      if (selectedPmKey.value != null) {
        try {
          await loadLauncher(selectedPmKey.value);
        } catch {
          // progress мог обновиться на сервере до ошибки ответа
        }
      }
      return null;
    } finally {
      funnelRunning.value = false;
    }
  }

  /**
   * Алиас runFunnel с flLoad из File.
   */
  async function runFunnelStub(
    steps: string[]
  ): Promise<(SudzPmtUplFunnelResult & { ok: boolean; message: string }) | null> {
    const flLoad = file.value?.cipufFlLoad ?? false;
    const result = await runFunnel(steps, flLoad);
    if (!result) {
      return null;
    }
    const wroteExcel = result.ranSteps.includes('excelToTbl');
    const extras = [
      wroteExcel ? 'Excel→Tbl' : '',
      result.stub ? 'stub cipu*' : ''
    ].filter(Boolean);
    const message = result.stub
      ? `Воронка: ${extras.join(', ') || 'шаги'} (лог обновлён)`
      : `Воронка завершена: ${extras.join(', ') || result.ranSteps.join(', ')}`;
    return { ...result, ok: true, message };
  }

  return {
    upls,
    selectedPmKey,
    launcher,
    loading,
    saving,
    funnelRunning,
    error,
    selectedUpl,
    file,
    loadUpls,
    loadLauncher,
    selectUpl,
    createUpl,
    saveFile,
    patchFileFlags,
    runFunnel,
    runFunnelStub
  };
});
