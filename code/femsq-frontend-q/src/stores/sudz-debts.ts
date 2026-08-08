/**
 * Pinia store экрана «Долги / мероприятия» (СУДЗ / 0068).
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  getSudzD644,
  getSudzYears,
  getSudzYrDbtChanges,
  updateSudzDebtCollection
} from '@/api/sudz-api';
import type {
  SudzD644Row,
  SudzPortfolioRow,
  SudzRsltDebt,
  SudzYear
} from '@/types/sudz';

function toPortfolioRow(debt: SudzRsltDebt): SudzPortfolioRow {
  const periods = debt.periods ?? [];
  const base = periods[0];
  return {
    dbtKey: debt.dbtKey,
    accountNum: debt.accountNum,
    counterpart: base?.ctptOrg ?? null,
    baseOverd: base?.overd ?? null,
    invoice: base?.invNumEnum ?? null,
    cstCode: debt.cstCode,
    curator: debt.curator,
    mery: debt.mery,
    cstName: debt.cstName,
    debt
  };
}

export const useSudzDebtsStore = defineStore('sudz-debts', () => {
  const years = ref<SudzYear[]>([]);
  const selectedYr = ref<number | null>(null);
  const debts = ref<SudzRsltDebt[]>([]);
  const selectedDbtKey = ref<number | null>(null);
  const loading = ref(false);
  const saving = ref(false);
  const error = ref<string | null>(null);
  const saveStatus = ref<string | null>(null);
  const accountFilter = ref<string | null>(null);
  const searchTerm = ref('');
  const d644Preview = ref<SudzD644Row | null>(null);
  const d644Loading = ref(false);

  const selectedYear = computed(() => years.value.find((y) => y.yrKey === selectedYr.value) ?? null);

  const portfolioRows = computed(() => debts.value.map(toPortfolioRow));

  const filteredRows = computed(() => {
    const term = searchTerm.value.trim().toLowerCase();
    return portfolioRows.value.filter((row) => {
      if (accountFilter.value && String(row.accountNum ?? '') !== accountFilter.value) {
        return false;
      }
      if (!term) {
        return true;
      }
      const haystack = [
        row.counterpart,
        row.invoice,
        row.cstCode,
        row.curator,
        String(row.dbtKey),
        row.debt.periods.map((p) => p.cnNumEnum).join(' ')
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(term);
    });
  });

  const accountOptions = computed(() => {
    const set = new Set<string>();
    for (const row of portfolioRows.value) {
      if (row.accountNum) {
        set.add(String(row.accountNum));
      }
    }
    return [...set].sort().map((value) => ({ label: value, value }));
  });

  const selectedDebt = computed(() => {
    if (selectedDbtKey.value == null) {
      return null;
    }
    return debts.value.find((d) => d.dbtKey === selectedDbtKey.value) ?? null;
  });

  const selectedRow = computed(() => {
    if (selectedDbtKey.value == null) {
      return null;
    }
    return portfolioRows.value.find((r) => r.dbtKey === selectedDbtKey.value) ?? null;
  });

  /**
   * Загружает список лет и при необходимости выбирает последний.
   */
  async function loadYears(): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      years.value = await getSudzYears();
      if (selectedYr.value == null && years.value.length > 0) {
        selectedYr.value = years.value[years.value.length - 1].yrKey;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось загрузить годы СУДЗ';
    } finally {
      loading.value = false;
    }
  }

  /**
   * Загружает портфель выбранного года.
   */
  async function loadPortfolio(): Promise<void> {
    if (selectedYr.value == null) {
      debts.value = [];
      return;
    }
    loading.value = true;
    error.value = null;
    saveStatus.value = null;
    d644Preview.value = null;
    try {
      debts.value = await getSudzYrDbtChanges(selectedYr.value);
      if (selectedDbtKey.value != null && !debts.value.some((d) => d.dbtKey === selectedDbtKey.value)) {
        selectedDbtKey.value = null;
      }
      if (selectedDbtKey.value == null && debts.value.length > 0) {
        const golden = debts.value.find((d) => d.dbtKey === 82) ?? debts.value[0];
        selectedDbtKey.value = golden.dbtKey;
      }
    } catch (err) {
      debts.value = [];
      error.value = err instanceof Error ? err.message : 'Не удалось загрузить портфель';
    } finally {
      loading.value = false;
    }
  }

  /**
   * Выбирает год и перезагружает портфель.
   *
   * @param yr ключ года
   */
  async function selectYear(yr: number): Promise<void> {
    selectedYr.value = yr;
    await loadPortfolio();
  }

  /**
   * Выбирает долг в master.
   *
   * @param dbtKey ключ долга
   */
  function selectDebt(dbtKey: number): void {
    selectedDbtKey.value = dbtKey;
    saveStatus.value = null;
    d644Preview.value = null;
  }

  /**
   * Сохраняет сбор по выбранному долгу.
   */
  async function saveCollection(payload: {
    curator: string;
    mery: string;
    cstCode: string;
  }): Promise<boolean> {
    if (selectedYr.value == null || selectedDbtKey.value == null) {
      return false;
    }
    saving.value = true;
    error.value = null;
    try {
      const result = await updateSudzDebtCollection({
        yr: selectedYr.value,
        dbtKey: selectedDbtKey.value,
        curator: payload.curator,
        mery: payload.mery,
        cstCode: payload.cstCode
      });
      const idx = debts.value.findIndex((d) => d.dbtKey === result.dbtKey);
      if (idx >= 0) {
        const current = debts.value[idx];
        debts.value[idx] = {
          ...current,
          curator: result.curator,
          mery: result.mery,
          cstCode: result.cstCode,
          cstName: result.cstName
        };
      }
      saveStatus.value = `Записано в группу комментариев ${result.cmmGr}`;
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось сохранить сбор';
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Превью строки D644 для UAT (mery → comment644).
   *
   * @param currUpl текущая выгрузка
   */
  async function loadD644Preview(currUpl: number): Promise<void> {
    if (selectedYr.value == null || selectedDbtKey.value == null) {
      return;
    }
    d644Loading.value = true;
    try {
      const rows = await getSudzD644(selectedYr.value, currUpl);
      d644Preview.value = rows.find((r) => r.dbtKey === selectedDbtKey.value) ?? null;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось загрузить превью D644';
      d644Preview.value = null;
    } finally {
      d644Loading.value = false;
    }
  }

  function resetFilters(): void {
    accountFilter.value = null;
    searchTerm.value = '';
  }

  return {
    years,
    selectedYr,
    selectedYear,
    debts,
    portfolioRows,
    filteredRows,
    accountOptions,
    selectedDbtKey,
    selectedDebt,
    selectedRow,
    loading,
    saving,
    error,
    saveStatus,
    accountFilter,
    searchTerm,
    d644Preview,
    d644Loading,
    loadYears,
    loadPortfolio,
    selectYear,
    selectDebt,
    saveCollection,
    loadD644Preview,
    resetFilters
  };
});
