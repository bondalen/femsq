/**
 * Стор LdM / Monf (C2 §6.4): список строк помесячных Excel.
 */

import { defineStore } from 'pinia';
import { computed, ref } from 'vue';

import {
  applyImpIpgLoadMonf,
  createImpIpgLoadMonf,
  deleteImpIpgLoadMonf,
  fetchImpIpgLoadMonfs,
  parseImpIpgLoadMonf,
  updateImpIpgLoadMonf,
  type CreateImpIpgLoadMonfInput,
  type ImpIpgLoadMonfDto,
  type ImpIpgMonfApplyResultDto,
  type ImpIpgMonfParseResultDto,
  type UpdateImpIpgLoadMonfInput
} from '@/api/imp-ipg-load-monf-api';

export const useImpIpgLoadMonfStore = defineStore('imp-ipg-load-monf', () => {
  const rows = ref<ImpIpgLoadMonfDto[]>([]);
  const selectedId = ref<number | null>(null);
  const filterLoadKey = ref<number | null>(null);
  const loading = ref(false);
  const mutating = ref(false);
  const parsing = ref(false);
  const applying = ref(false);
  const parseResult = ref<ImpIpgMonfParseResultDto | null>(null);
  const applyResult = ref<ImpIpgMonfApplyResultDto | null>(null);
  const error = ref<string | null>(null);

  const selected = computed(
    () => rows.value.find((r) => r.id === selectedId.value) ?? null
  );

  const filteredRows = computed(() => {
    if (filterLoadKey.value == null) {
      return rows.value;
    }
    return rows.value.filter((r) => r.loadKey === filterLoadKey.value);
  });

  /**
   * Загрузить Monf текущей ИП.
   */
  async function loadForIpg(ipgKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      rows.value = await fetchImpIpgLoadMonfs(ipgKey);
      if (
        selectedId.value != null &&
        !rows.value.some((r) => r.id === selectedId.value)
      ) {
        selectedId.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      rows.value = [];
    } finally {
      loading.value = false;
    }
  }

  /**
   * Фильтр по сессии load (null = все).
   */
  function setLoadFilter(loadKey: number | null): void {
    filterLoadKey.value = loadKey;
  }

  /**
   * Выбрать строку.
   */
  function select(id: number | null): void {
    selectedId.value = id;
  }

  /**
   * Создать Monf.
   */
  async function create(input: CreateImpIpgLoadMonfInput): Promise<ImpIpgLoadMonfDto> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createImpIpgLoadMonf(input);
      rows.value = [created, ...rows.value];
      selectedId.value = created.id;
      return created;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Обновить Monf.
   */
  async function update(
    id: number,
    input: UpdateImpIpgLoadMonfInput
  ): Promise<ImpIpgLoadMonfDto> {
    mutating.value = true;
    error.value = null;
    try {
      const updated = await updateImpIpgLoadMonf(id, input);
      rows.value = rows.value.map((r) => (r.id === id ? updated : r));
      return updated;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Удалить Monf.
   */
  async function remove(id: number): Promise<boolean> {
    mutating.value = true;
    error.value = null;
    try {
      const ok = await deleteImpIpgLoadMonf(id);
      if (ok) {
        rows.value = rows.value.filter((r) => r.id !== id);
        if (selectedId.value === id) {
          selectedId.value = null;
        }
      }
      return ok;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Parse skeleton выбранной строки Monf.
   */
  async function parse(filePath?: string | null): Promise<ImpIpgMonfParseResultDto | null> {
    if (selectedId.value == null) {
      error.value = 'Выберите строку Monf';
      return null;
    }
    parsing.value = true;
    error.value = null;
    try {
      const result = await parseImpIpgLoadMonf(selectedId.value, filePath);
      parseResult.value = result;
      rows.value = rows.value.map((r) =>
        r.id === selectedId.value ? { ...r, logHtml: result.logHtml ?? r.logHtml } : r
      );
      return result;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      parsing.value = false;
    }
  }

  /**
   * Apply Monf → UtPlP / LmMn@212.
   */
  async function apply(dryRun = false): Promise<ImpIpgMonfApplyResultDto | null> {
    if (selectedId.value == null) {
      error.value = 'Выберите строку Monf';
      return null;
    }
    applying.value = true;
    error.value = null;
    try {
      const result = await applyImpIpgLoadMonf(selectedId.value, dryRun);
      applyResult.value = result;
      rows.value = rows.value.map((r) =>
        r.id === selectedId.value ? { ...r, logHtml: result.logHtml ?? r.logHtml } : r
      );
      return result;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      applying.value = false;
    }
  }

  /**
   * Сброс при смене ИП.
   */
  function reset(): void {
    rows.value = [];
    selectedId.value = null;
    filterLoadKey.value = null;
    parseResult.value = null;
    applyResult.value = null;
    error.value = null;
  }

  return {
    rows,
    filteredRows,
    selectedId,
    selected,
    filterLoadKey,
    loading,
    mutating,
    parsing,
    applying,
    parseResult,
    applyResult,
    error,
    loadForIpg,
    setLoadFilter,
    select,
    create,
    update,
    remove,
    parse,
    apply,
    reset
  };
});
