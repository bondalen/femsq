/**
 * Pinia store экрана «Портфель года» (yr / S51).
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  addSudzPmLink,
  addSudzYearUpl,
  createSudzCmmGr,
  createSudzPmUpl,
  createSudzUpl,
  createSudzYear,
  deleteSudzYear,
  getSudzCmmGrLookups,
  getSudzPmUplLookups,
  getSudzUplLookups,
  getSudzYear,
  getSudzYears,
  getSudzYyyyLookups,
  removeSudzPmLink,
  removeSudzYearUpl,
  updateSudzYear
} from '@/api/sudz-api';
import type {
  CreateSudzCmmGrInput,
  CreateSudzPmUplInput,
  CreateSudzUplInput,
  CreateSudzYearInput,
  SudzCmmGrLookup,
  SudzPmUplLookup,
  SudzUplLookup,
  SudzYear,
  SudzYearDetail,
  SudzYyyyLookup,
  UpdateSudzYearInput
} from '@/types/sudz';

export const useSudzPortfolioStore = defineStore('sudz-portfolio', () => {
  const years = ref<SudzYear[]>([]);
  const selectedYrKey = ref<number | null>(null);
  const detail = ref<SudzYearDetail | null>(null);
  const uplLookups = ref<SudzUplLookup[]>([]);
  const cmmGrLookups = ref<SudzCmmGrLookup[]>([]);
  const yyyyLookups = ref<SudzYyyyLookup[]>([]);
  const pmLookups = ref<SudzPmUplLookup[]>([]);
  const expandedUplKeys = ref<Set<number>>(new Set());
  const loading = ref(false);
  const saving = ref(false);
  const error = ref<string | null>(null);

  const selectedYear = computed(() => detail.value?.year ?? null);
  const yearUpls = computed(() => detail.value?.upls ?? []);

  function isUplExpanded(uplKey: number): boolean {
    return expandedUplKeys.value.has(uplKey);
  }

  function toggleUplExpanded(uplKey: number): void {
    const next = new Set(expandedUplKeys.value);
    if (next.has(uplKey)) {
      next.delete(uplKey);
    } else {
      next.add(uplKey);
    }
    expandedUplKeys.value = next;
  }

  async function loadLookups(): Promise<void> {
    const [upls, cmm, yyyy, pm] = await Promise.all([
      getSudzUplLookups(),
      getSudzCmmGrLookups(),
      getSudzYyyyLookups(),
      getSudzPmUplLookups()
    ]);
    uplLookups.value = upls;
    cmmGrLookups.value = cmm;
    yyyyLookups.value = yyyy;
    pmLookups.value = pm;
  }

  async function loadYears(): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      years.value = await getSudzYears();
      if (selectedYrKey.value == null && years.value.length > 0) {
        selectedYrKey.value = years.value[years.value.length - 1].yrKey;
      }
      if (selectedYrKey.value != null) {
        await loadDetail(selectedYrKey.value);
      }
      await loadLookups();
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось загрузить годы';
    } finally {
      loading.value = false;
    }
  }

  async function loadDetail(yrKey: number): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      selectedYrKey.value = yrKey;
      detail.value = await getSudzYear(yrKey);
    } catch (err) {
      detail.value = null;
      error.value = err instanceof Error ? err.message : 'Не удалось загрузить карточку года';
    } finally {
      loading.value = false;
    }
  }

  async function selectYear(yrKey: number): Promise<void> {
    expandedUplKeys.value = new Set();
    await loadDetail(yrKey);
  }

  async function saveYear(input: UpdateSudzYearInput): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      detail.value = await updateSudzYear(input);
      years.value = await getSudzYears();
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось сохранить год';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function createYear(input: CreateSudzYearInput): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createSudzYear(input);
      years.value = await getSudzYears();
      await loadLookups();
      selectedYrKey.value = created.year.yrKey;
      detail.value = created;
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось создать год';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function removeYear(yrKey: number): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      await deleteSudzYear(yrKey);
      years.value = await getSudzYears();
      if (selectedYrKey.value === yrKey) {
        selectedYrKey.value = years.value[0]?.yrKey ?? null;
        detail.value = null;
        if (selectedYrKey.value != null) {
          await loadDetail(selectedYrKey.value);
        }
      }
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось удалить год';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function addUpl(yrKey: number, uplKey: number): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      await addSudzYearUpl(yrKey, uplKey);
      detail.value = await getSudzYear(yrKey);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось добавить выгрузку';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function createAndAddUpl(yrKey: number, input: CreateSudzUplInput): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      const upl = await createSudzUpl(input);
      await addSudzYearUpl(yrKey, upl.uplKey);
      await loadLookups();
      detail.value = await getSudzYear(yrKey);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось создать выгрузку';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function removeUpl(yrUplPKey: number): Promise<boolean> {
    if (selectedYrKey.value == null) return false;
    saving.value = true;
    error.value = null;
    try {
      await removeSudzYearUpl(yrUplPKey);
      detail.value = await getSudzYear(selectedYrKey.value);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось удалить выгрузку из года';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function linkPm(dbtUplKey: number, pmKey: number): Promise<boolean> {
    if (selectedYrKey.value == null) return false;
    saving.value = true;
    error.value = null;
    try {
      await addSudzPmLink(dbtUplKey, pmKey);
      detail.value = await getSudzYear(selectedYrKey.value);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось связать платёжную выгрузку';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function createAndLinkPm(dbtUplKey: number, input: CreateSudzPmUplInput): Promise<boolean> {
    if (selectedYrKey.value == null) return false;
    saving.value = true;
    error.value = null;
    try {
      const pm = await createSudzPmUpl(input);
      await addSudzPmLink(dbtUplKey, pm.pmKey);
      await loadLookups();
      detail.value = await getSudzYear(selectedYrKey.value);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось создать платёжную выгрузку';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function createCmmGr(input: CreateSudzCmmGrInput): Promise<SudzCmmGrLookup | null> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createSudzCmmGr(input);
      cmmGrLookups.value = await getSudzCmmGrLookups();
      return created;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось создать группу комментариев';
      return null;
    } finally {
      saving.value = false;
    }
  }

  async function unlinkPm(gPKey: number): Promise<boolean> {
    if (selectedYrKey.value == null) return false;
    saving.value = true;
    error.value = null;
    try {
      await removeSudzPmLink(gPKey);
      detail.value = await getSudzYear(selectedYrKey.value);
      return true;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Не удалось удалить связь';
      return false;
    } finally {
      saving.value = false;
    }
  }

  return {
    years,
    selectedYrKey,
    detail,
    selectedYear,
    yearUpls,
    uplLookups,
    cmmGrLookups,
    yyyyLookups,
    pmLookups,
    loading,
    saving,
    error,
    isUplExpanded,
    toggleUplExpanded,
    loadYears,
    selectYear,
    saveYear,
    createYear,
    removeYear,
    createCmmGr,
    addUpl,
    createAndAddUpl,
    removeUpl,
    linkPm,
    createAndLinkPm,
    unlinkPm
  };
});
