import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createSudzFioDict,
  deleteSudzFioDict,
  fetchSudzFioDict,
  prepareSudzBriefReport,
  updateSudzFioDict
} from '@/api/sudz-api';
import type {
  CreateSudzFioDictInput,
  SudzBriefReportResult,
  SudzFioDict,
  UpdateSudzFioDictInput
} from '@/types/sudz';

/**
 * Стор экрана краткого отчёта по своду (**1.1.1.0.3.3** / **.3.4** словарь).
 */
export const useSudzBriefReportStore = defineStore('sudz-brief-report', () => {
  const svodPath = ref('');
  /** Дата отчёта yyyy-MM-dd (L6). */
  const asOf = ref('');
  const running = ref(false);
  const error = ref<string | null>(null);
  const result = ref<SudzBriefReportResult | null>(null);

  const dictRows = ref<SudzFioDict[]>([]);
  const dictLoading = ref(false);
  const dictSaving = ref(false);
  const dictLoaded = ref(false);
  const dictError = ref<string | null>(null);

  const logText = computed(() => (result.value?.logLines ?? []).join('\n'));
  const canPrepare = computed(
    () => svodPath.value.trim().length > 0 && /^\d{4}-\d{2}-\d{2}$/.test(asOf.value.trim())
  );

  /**
   * Пробует вытащить дату из имени свода вида «на 31.03.2026».
   *
   * @param path путь или имя файла
   * @returns yyyy-MM-dd или null
   */
  function guessAsOfFromPath(path: string): string | null {
    const m = path.match(/(\d{2})\.(\d{2})\.(\d{4})/);
    if (!m) {
      return null;
    }
    return `${m[3]}-${m[2]}-${m[1]}`;
  }

  /**
   * При смене пути — подставить asOf из имени, если поле пусто.
   */
  function onPathChanged(path: string): void {
    svodPath.value = path;
    if (!asOf.value.trim()) {
      const guessed = guessAsOfFromPath(path);
      if (guessed) {
        asOf.value = guessed;
      }
    }
  }

  /**
   * Вызов GraphQL prepareSudzBriefReport.
   *
   * @returns результат или null при ошибке
   */
  async function prepare(): Promise<SudzBriefReportResult | null> {
    if (!canPrepare.value || running.value) {
      return null;
    }
    running.value = true;
    error.value = null;
    try {
      const data = await prepareSudzBriefReport({
        svodPath: svodPath.value.trim(),
        asOf: asOf.value.trim()
      });
      result.value = data;
      return data;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      result.value = null;
      return null;
    } finally {
      running.value = false;
    }
  }

  function clearLog(): void {
    result.value = null;
    error.value = null;
  }

  /**
   * Загрузить строки словаря (повторный вызов безопасен).
   */
  async function loadDict(force = false): Promise<void> {
    if (dictLoading.value) {
      return;
    }
    if (dictLoaded.value && !force) {
      return;
    }
    dictLoading.value = true;
    dictError.value = null;
    try {
      dictRows.value = await fetchSudzFioDict();
      dictLoaded.value = true;
    } catch (err) {
      dictError.value = err instanceof Error ? err.message : String(err);
      dictRows.value = [];
      dictLoaded.value = false;
    } finally {
      dictLoading.value = false;
    }
  }

  /**
   * Создать строку словаря и обновить список.
   */
  async function createDictRow(input: CreateSudzFioDictInput): Promise<SudzFioDict | null> {
    if (dictSaving.value) {
      return null;
    }
    dictSaving.value = true;
    dictError.value = null;
    try {
      const created = await createSudzFioDict(input);
      await loadDict(true);
      return created;
    } catch (err) {
      dictError.value = err instanceof Error ? err.message : String(err);
      return null;
    } finally {
      dictSaving.value = false;
    }
  }

  /**
   * Обновить строку словаря.
   */
  async function updateDictRow(input: UpdateSudzFioDictInput): Promise<SudzFioDict | null> {
    if (dictSaving.value) {
      return null;
    }
    dictSaving.value = true;
    dictError.value = null;
    try {
      const updated = await updateSudzFioDict(input);
      await loadDict(true);
      return updated;
    } catch (err) {
      dictError.value = err instanceof Error ? err.message : String(err);
      return null;
    } finally {
      dictSaving.value = false;
    }
  }

  /**
   * Удалить строку словаря.
   */
  async function deleteDictRow(fioDictKey: number): Promise<boolean> {
    if (dictSaving.value || fioDictKey <= 0) {
      return false;
    }
    dictSaving.value = true;
    dictError.value = null;
    try {
      const ok = await deleteSudzFioDict(fioDictKey);
      if (ok) {
        await loadDict(true);
      } else {
        dictError.value = `Строка ${fioDictKey} не найдена`;
      }
      return ok;
    } catch (err) {
      dictError.value = err instanceof Error ? err.message : String(err);
      return false;
    } finally {
      dictSaving.value = false;
    }
  }

  return {
    svodPath,
    asOf,
    running,
    error,
    result,
    logText,
    canPrepare,
    dictRows,
    dictLoading,
    dictSaving,
    dictLoaded,
    dictError,
    guessAsOfFromPath,
    onPathChanged,
    prepare,
    clearLog,
    loadDict,
    createDictRow,
    updateDictRow,
    deleteDictRow
  };
});
