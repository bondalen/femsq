/**
 * Pinia store экрана «Долг (канон)» (S78).
 */

import { defineStore } from 'pinia';
import { ref } from 'vue';

import {
  deleteSudzDbtCanonComment,
  deleteSudzDbtCanonValue,
  getSudzDbtCanon,
  linkSudzInvDbtToDbt,
  mergeSudzDbt,
  searchSudzDbtCanons,
  splitSudzDbt,
  unlinkSudzInvDbtFromDbt,
  upsertSudzDbtCanonComment,
  upsertSudzDbtCanonValue
} from '@/api/sudz-api';
import type {
  MergeSudzDbtInput,
  SplitSudzDbtInput,
  SudzDbtCanonCandidate,
  SudzDbtCanonDetail,
  SudzDbtCanonSearchInput,
  UpsertSudzDbtCanonCommentInput,
  UpsertSudzDbtCanonValueInput
} from '@/types/sudz';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Нормализует карточку: пустые comments / cmmYears.
 *
 * @param row ответ GraphQL
 */
function acceptDetail(row: SudzDbtCanonDetail): SudzDbtCanonDetail {
  return {
    ...row,
    cmmYears: row.cmmYears ?? [],
    slots: (row.slots ?? []).map((slot) => ({
      ...slot,
      values: (slot.values ?? []).map((value) => ({
        ...value,
        comments: value.comments ?? []
      }))
    }))
  };
}

/**
 * Разбор целого из текста колоночного фильтра.
 *
 * @param raw значение поля фильтра
 * @returns число, null если пусто, NaN если не целое
 */
function parseOptionalInt(raw: string | undefined): number | null {
  const text = raw?.trim() ?? '';
  if (text === '') {
    return null;
  }
  if (!/^-?\d+$/.test(text)) {
    return Number.NaN;
  }
  return Number(text);
}

/**
 * Собирает GraphQL-вход из фильтров колонок FemsqTable.
 *
 * @param filters ключ = column.name
 * @returns вход поиска или текст ошибки валидации
 */
export function columnFiltersToSearchInput(
  filters: Record<string, string>
): { input: SudzDbtCanonSearchInput } | { error: string } {
  const org = parseOptionalInt(filters.orgBuirg);
  const idn = parseOptionalInt(filters.idNum);
  const dk = parseOptionalInt(filters.dbtKey);
  const hasTextCriteria = Boolean(
    filters.cnNum?.trim() || filters.invNum?.trim() || filters.orgName?.trim()
  );
  if (Number.isNaN(org) && !hasTextCriteria) {
    return { error: 'БУиРГ — целое число' };
  }
  if (Number.isNaN(idn) && !hasTextCriteria) {
    return { error: '№ слота — целое число' };
  }
  if (Number.isNaN(dk) && !hasTextCriteria) {
    return { error: 'dbtKey — целое число' };
  }
  const csoDate = filters.csoDate?.trim() || null;
  if (csoDate && !ISO_DATE.test(csoDate)) {
    return { error: 'Дата стороны — ГГГГ-ММ-ДД' };
  }
  return {
    input: {
      cnNum: filters.cnNum?.trim() || null,
      invNum: filters.invNum?.trim() || null,
      orgBuirg: Number.isNaN(org) ? null : org,
      orgName: filters.orgName?.trim() || null,
      csoDate,
      idNum: Number.isNaN(idn) ? null : idn,
      dbtKey: Number.isNaN(dk) ? null : dk,
      limit: 50
    }
  };
}

/**
 * Есть ли хотя бы один серверный критерий.
 *
 * @param input вход GraphQL
 */
export function searchInputHasCriteria(input: SudzDbtCanonSearchInput): boolean {
  return (
    (input.dbtKey != null && input.dbtKey > 0) ||
    Boolean(input.cnNum) ||
    Boolean(input.invNum) ||
    Boolean(input.orgName) ||
    input.orgBuirg != null ||
    Boolean(input.csoDate) ||
    input.idNum != null
  );
}

export const useSudzDbtCanonStore = defineStore('sudz-dbt-canon', () => {
  const candidates = ref<SudzDbtCanonCandidate[]>([]);
  const detail = ref<SudzDbtCanonDetail | null>(null);
  const selectedDbtKey = ref<number | null>(null);
  const linkSlotKey = ref<string>('');

  const loading = ref(false);
  const error = ref<string | null>(null);

  let searchSeq = 0;

  /**
   * Поиск кандидатов по фильтрам колонок. Пустые критерии — не вызывать API.
   *
   * @param filters v-model:columnFilters FemsqTable
   */
  async function searchByColumnFilters(filters: Record<string, string>): Promise<void> {
    const parsed = columnFiltersToSearchInput(filters);
    if ('error' in parsed) {
      searchSeq += 1;
      error.value = parsed.error;
      candidates.value = [];
      return;
    }
    if (!searchInputHasCriteria(parsed.input)) {
      searchSeq += 1;
      error.value = null;
      candidates.value = [];
      return;
    }
    const seq = ++searchSeq;
    loading.value = true;
    error.value = null;
    try {
      const rows = await searchSudzDbtCanons(parsed.input);
      if (seq !== searchSeq) {
        return;
      }
      candidates.value = rows;
      if (rows.length === 1) {
        await openCanon(rows[0].dbtKey);
      }
    } catch (e) {
      if (seq !== searchSeq) {
        return;
      }
      error.value = e instanceof Error ? e.message : String(e);
      candidates.value = [];
    } finally {
      if (seq === searchSeq) {
        loading.value = false;
      }
    }
  }

  /**
   * Открыть карточку канона.
   *
   * @param key dbtKey
   */
  async function openCanon(key: number): Promise<void> {
    loading.value = true;
    error.value = null;
    selectedDbtKey.value = key;
    try {
      detail.value = acceptDetail(await getSudzDbtCanon(key));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      detail.value = null;
    } finally {
      loading.value = false;
    }
  }

  /**
   * Привязать слот к открытому канону.
   */
  async function linkSlot(): Promise<void> {
    if (selectedDbtKey.value == null) {
      error.value = 'Сначала выберите канон';
      return;
    }
    const sk = Number(linkSlotKey.value);
    if (!sk || Number.isNaN(sk)) {
      error.value = 'Укажите slotKey (idKey слота)';
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await linkSudzInvDbtToDbt(sk, selectedDbtKey.value));
      linkSlotKey.value = '';
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Отвязать слот от канона.
   *
   * @param slotKey слот
   */
  async function unlinkSlot(slotKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await unlinkSudzInvDbtFromDbt(slotKey));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Задать или обновить Value.
   *
   * @param input upsert
   */
  async function upsertValue(input: UpsertSudzDbtCanonValueInput): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await upsertSudzDbtCanonValue(input));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Снять Value со слота.
   *
   * @param valueKey ключ
   */
  async function deleteValue(valueKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await deleteSudzDbtCanonValue(valueKey));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Split канона на доли одной upl.
   *
   * @param input splitSudzDbt
   */
  async function splitCanon(input: SplitSudzDbtInput): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      await splitSudzDbt(input);
      if (selectedDbtKey.value != null) {
        detail.value = acceptDetail(await getSudzDbtCanon(selectedDbtKey.value));
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Merge канонов или долей.
   *
   * @param input mergeSudzDbt
   */
  async function mergeCanon(input: MergeSudzDbtInput): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      const result = await mergeSudzDbt(input);
      selectedDbtKey.value = result.survivorDbtKey;
      detail.value = acceptDetail(await getSudzDbtCanon(result.survivorDbtKey));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Сохранить комментарий на DbtValue.
   *
   * @param input upsert
   */
  async function upsertComment(input: UpsertSudzDbtCanonCommentInput): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await upsertSudzDbtCanonComment(input));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Удалить комментарий канона.
   *
   * @param cmmKey {@code cnicKey}
   */
  async function deleteComment(cmmKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      detail.value = acceptDetail(await deleteSudzDbtCanonComment(cmmKey));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Сброс выборки и карточки.
   */
  function resetFilters(): void {
    searchSeq += 1;
    candidates.value = [];
    detail.value = null;
    selectedDbtKey.value = null;
    error.value = null;
    linkSlotKey.value = '';
  }

  return {
    candidates,
    detail,
    selectedDbtKey,
    linkSlotKey,
    loading,
    error,
    searchByColumnFilters,
    openCanon,
    linkSlot,
    unlinkSlot,
    upsertValue,
    deleteValue,
    splitCanon,
    mergeCanon,
    upsertComment,
    deleteComment,
    resetFilters
  };
});
