/**
 * Pinia store экрана C «Загрузка свода» (0069 / S61 этап 6–7).
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createSudzUpl,
  createSudzDbtUplFileSh,
  deleteSudzDbtUplFileSh,
  getSudzDbtUplLauncher,
  getSudzUplLookups,
  getSudzYearKeysForUpl,
  getSudzYears,
  runSudzDbtUplFunnel,
  seedSudzDbtUplStandardSheets,
  updateSudzDbtUplFile,
  updateSudzDbtUplFileSh,
} from '@/api/sudz-api';
import type {
  CreateSudzUplInput,
  SudzCnInvUplInvDbtDouble,
  SudzCnInvUplSfDouble,
  SudzDbtUplFile,
  SudzDbtUplFileSh,
  SudzDbtUplFunnelResult,
  SudzDbtUplInvDouble,
  SudzDbtUplLauncher,
  SudzUplLookup,
  SudzYear,
  UpdateSudzDbtUplFileInput
} from '@/types/sudz';

function compareUplDateDesc(a: SudzUplLookup, b: SudzUplLookup): number {
  const da = a.uplDate ?? '';
  const db = b.uplDate ?? '';
  if (da !== db) {
    return db.localeCompare(da);
  }
  return b.uplKey - a.uplKey;
}

/**
 * Предпочитает портфель, где upl — квартальный срез (не база года).
 * Для 31.12-выгрузки в двух портфелях это даёт yr Y (Q4), а не yr Y+1 (self-base).
 */
function suggestFunnelYrKey(
  uplKey: number,
  yearKeys: number[],
  years: SudzYear[],
  preferredYrKey: number | null
): number | null {
  if (yearKeys.length === 0) {
    return null;
  }
  if (preferredYrKey != null && yearKeys.includes(preferredYrKey)) {
    return preferredYrKey;
  }
  const candidates = yearKeys
    .map((yk) => years.find((y) => y.yrKey === yk))
    .filter((y): y is SudzYear => y != null);
  const nonBase = candidates.find((y) => y.baseUpl !== uplKey);
  if (nonBase) {
    return nonBase.yrKey;
  }
  return yearKeys[0];
}

export const useSudzDbtUplStore = defineStore('sudz-dbt-upl', () => {
  const upls = ref<SudzUplLookup[]>([]);
  const selectedUplKey = ref<number | null>(null);
  const selectedYrKey = ref<number | null>(null);
  const yearKeysForUpl = ref<number[]>([]);
  const years = ref<SudzYear[]>([]);
  const launcher = ref<SudzDbtUplLauncher | null>(null);
  const loading = ref(false);
  const saving = ref(false);
  const funnelRunning = ref(false);
  const error = ref<string | null>(null);

  const selectedUpl = computed(() => {
    if (selectedUplKey.value == null) {
      return null;
    }
    return upls.value.find((u) => u.uplKey === selectedUplKey.value) ?? launcher.value?.upl ?? null;
  });

  const yrContextOptions = computed(() =>
    yearKeysForUpl.value.map((yrKey) => {
      const year = years.value.find((y) => y.yrKey === yrKey);
      const base = year?.baseUpl;
      const isBase = base === selectedUplKey.value;
      const label = year
        ? `yr ${yrKey}${year.yyyyValue != null ? ` (${year.yyyyValue})` : ''}`
            + (isBase ? ' — база года' : ` — base upl ${base ?? '?'}`)
        : `yr ${yrKey}`;
      return { label, value: yrKey };
    })
  );

  const file = computed<SudzDbtUplFile | null>(() => launcher.value?.file ?? null);
  const sheets = computed<SudzDbtUplFileSh[]>(() => launcher.value?.sheets ?? []);
  const invDoubles = computed<SudzDbtUplInvDouble[]>(() => launcher.value?.invDoubles ?? []);
  const sfDoubles = computed<SudzCnInvUplSfDouble[]>(() => launcher.value?.sfDoubles ?? []);
  const invDbtDoubles = computed<SudzCnInvUplInvDbtDouble[]>(
    () => launcher.value?.invDbtDoubles ?? []
  );
  const sfDoublesOpenCount = computed(
    () => sfDoubles.value.filter((r) => r.ciusStatus === 'open').length
  );
  const invDbtDoublesOpenCount = computed(
    () => invDbtDoubles.value.filter((r) => r.ciudStatus === 'open').length
  );

  /**
   * Загружает справочник годов (кэш).
   */
  async function ensureYearsLoaded(): Promise<void> {
    if (years.value.length > 0) {
      return;
    }
    years.value = await getSudzYears();
  }

  /**
   * Обновляет список портфелей для upl и выбирает контекст yr.
   */
  async function resolveYrContext(uplKey: number, preferredYrKey: number | null = null): Promise<void> {
    await ensureYearsLoaded();
    yearKeysForUpl.value = await getSudzYearKeysForUpl(uplKey);
    selectedYrKey.value = suggestFunnelYrKey(
      uplKey,
      yearKeysForUpl.value,
      years.value,
      preferredYrKey ?? selectedYrKey.value
    );
  }

  /**
   * Явная установка контекста портфеля (из экрана «Портфель года»).
   */
  function setPreferredYrKey(yrKey: number | null): void {
    if (yrKey == null || selectedUplKey.value == null) {
      return;
    }
    if (yearKeysForUpl.value.includes(yrKey)) {
      selectedYrKey.value = yrKey;
    }
  }

  /**
   * Загружает список выгрузок (новые сверху).
   */
  async function loadUpls(): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      const list = await getSudzUplLookups();
      upls.value = [...list].sort(compareUplDateDesc);
      if (selectedUplKey.value != null) {
        const still = upls.value.some((u) => u.uplKey === selectedUplKey.value);
        if (!still) {
          selectedUplKey.value = null;
          selectedYrKey.value = null;
          yearKeysForUpl.value = [];
          launcher.value = null;
        }
      }
      if (selectedUplKey.value == null && upls.value.length > 0) {
        await selectUpl(upls.value[0].uplKey);
      } else if (selectedUplKey.value != null) {
        await loadLauncher(selectedUplKey.value);
        await resolveYrContext(selectedUplKey.value);
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Загружает карточку лаунчера.
   */
  async function loadLauncher(uplKey: number): Promise<void> {
    try {
      launcher.value = await getSudzDbtUplLauncher(uplKey);
    } catch (e) {
      launcher.value = null;
      error.value = e instanceof Error ? e.message : String(e);
    }
  }

  /**
   * Выбор выгрузки в списке.
   */
  async function selectUpl(uplKey: number, preferredYrKey: number | null = null): Promise<void> {
    selectedUplKey.value = uplKey;
    loading.value = true;
    error.value = null;
    try {
      await loadLauncher(uplKey);
      await resolveYrContext(uplKey, preferredYrKey);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Создаёт выгрузку ДЗ и выбирает её.
   */
  async function createUpl(input: CreateSudzUplInput): Promise<SudzUplLookup | null> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createSudzUpl(input);
      await loadUpls();
      await selectUpl(created.uplKey);
      return created;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return null;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Сохраняет флаги/путь шапки File (upsert).
   */
  async function saveFile(input: Omit<UpdateSudzDbtUplFileInput, 'uplKey'>): Promise<boolean> {
    if (selectedUplKey.value == null) {
      return false;
    }
    saving.value = true;
    error.value = null;
    try {
      const updated = await updateSudzDbtUplFile({
        uplKey: selectedUplKey.value,
        ...input
      });
      if (launcher.value) {
        launcher.value = {
          ...launcher.value,
          file: updated,
          sheets: launcher.value.sheets,
          invDoubles: launcher.value.invDoubles
        };
      } else {
        await loadLauncher(selectedUplKey.value);
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
  async function patchFileFlags(input: Omit<UpdateSudzDbtUplFileInput, 'uplKey'>): Promise<boolean> {
    return saveFile(input);
  }

  async function refreshLauncher(): Promise<void> {
    if (selectedUplKey.value == null) {
      return;
    }
    await loadLauncher(selectedUplKey.value);
  }

  /**
   * Добавляет 6 стандартных листов (если список пуст).
   */
  async function seedStandardSheets(): Promise<SudzDbtUplFileSh[]> {
    if (selectedUplKey.value == null) {
      return [];
    }
    saving.value = true;
    error.value = null;
    try {
      const sheets = await seedSudzDbtUplStandardSheets(selectedUplKey.value);
      await refreshLauncher();
      return sheets;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return [];
    } finally {
      saving.value = false;
    }
  }

  /**
   * Создаёт лист Excel.
   */
  async function addSheet(sheet: string, accountNum: number, test: boolean): Promise<boolean> {
    if (selectedUplKey.value == null) {
      return false;
    }
    saving.value = true;
    error.value = null;
    try {
      await createSudzDbtUplFileSh({
        uplKey: selectedUplKey.value,
        sheet,
        accountNum,
        test
      });
      await refreshLauncher();
      return true;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Обновляет лист Excel.
   */
  async function editSheet(
    cidufsKey: number,
    sheet: string,
    accountNum: number,
    test: boolean
  ): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      await updateSudzDbtUplFileSh({
        cidufsKey,
        sheet,
        accountNum,
        test
      });
      await refreshLauncher();
      return true;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Удаляет лист Excel.
   */
  async function removeSheet(cidufsKey: number): Promise<boolean> {
    saving.value = true;
    error.value = null;
    try {
      await deleteSudzDbtUplFileSh(cidufsKey);
      await refreshLauncher();
      return true;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Прогон воронки (excelToTbl читает cidufPath из БД; dbtValueLoad — diff в контексте yrKey).
   */
  async function runFunnel(steps: string[], flLoad: boolean): Promise<SudzDbtUplFunnelResult | null> {
    if (selectedUplKey.value == null) {
      return null;
    }
    if (selectedYrKey.value == null) {
      error.value = 'Выберите портфель года (yr) для контекста загрузки';
      return null;
    }
    funnelRunning.value = true;
    error.value = null;
    try {
      const result = await runSudzDbtUplFunnel({
        uplKey: selectedUplKey.value,
        yrKey: selectedYrKey.value,
        steps,
        flLoad
      });
      launcher.value = result.launcher;
      return result;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      return null;
    } finally {
      funnelRunning.value = false;
    }
  }

  /**
   * Алиас runFunnel с flLoad из File.
   */
  async function runFunnelStub(steps: string[]): Promise<(SudzDbtUplFunnelResult & { ok: boolean; message: string }) | null> {
    const flLoad = file.value?.cidufFlLoad ?? false;
    const result = await runFunnel(steps, flLoad);
    if (!result) {
      return null;
    }
    const wroteExcel = result.ranSteps.includes('excelToTbl');
    const wroteOrg = result.ranSteps.includes('orgNotInBuirg');
    const extras = [
      wroteExcel ? 'Excel→Tbl' : '',
      wroteOrg ? 'новые орг.' : ''
    ].filter(Boolean).join(', ');
    const suffix = extras ? `; ${extras}` : '';
    const message = result.stub
      ? `Воронка: ${result.ranSteps.length} шаг(ов)${suffix}; часть шагов ещё STUB`
      : `Воронка: ${result.ranSteps.length} шаг(ов)${suffix}`;
    return { ...result, ok: true, message };
  }

  return {
    upls,
    selectedUplKey,
    selectedYrKey,
    yearKeysForUpl,
    years,
    yrContextOptions,
    launcher,
    loading,
    saving,
    funnelRunning,
    error,
    selectedUpl,
    file,
    sheets,
    invDoubles,
    sfDoubles,
    invDbtDoubles,
    sfDoublesOpenCount,
    invDbtDoublesOpenCount,
    loadUpls,
    loadLauncher,
    selectUpl,
    setPreferredYrKey,
    resolveYrContext,
    createUpl,
    saveFile,
    patchFileFlags,
    seedStandardSheets,
    addSheet,
    editSheet,
    removeSheet,
    refreshLauncher,
    runFunnel,
    runFunnelStub
  };
});
