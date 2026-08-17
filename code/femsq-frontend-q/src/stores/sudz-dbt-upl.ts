/**
 * Pinia store экрана C «Загрузка свода» (0069 / S61 этап 6–7).
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createSudzUpl,
  getSudzDbtUplLauncher,
  getSudzUplLookups,
  runSudzDbtUplFunnel,
  updateSudzDbtUplFile
} from '@/api/sudz-api';
import type {
  CreateSudzUplInput,
  SudzCnInvUplSfDouble,
  SudzDbtUplFile,
  SudzDbtUplFileSh,
  SudzDbtUplFunnelResult,
  SudzDbtUplInvDouble,
  SudzDbtUplLauncher,
  SudzUplLookup,
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

export const useSudzDbtUplStore = defineStore('sudz-dbt-upl', () => {
  const upls = ref<SudzUplLookup[]>([]);
  const selectedUplKey = ref<number | null>(null);
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

  const file = computed<SudzDbtUplFile | null>(() => launcher.value?.file ?? null);
  const sheets = computed<SudzDbtUplFileSh[]>(() => launcher.value?.sheets ?? []);
  const invDoubles = computed<SudzDbtUplInvDouble[]>(() => launcher.value?.invDoubles ?? []);
  const sfDoubles = computed<SudzCnInvUplSfDouble[]>(() => launcher.value?.sfDoubles ?? []);

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
          launcher.value = null;
        }
      }
      if (selectedUplKey.value == null && upls.value.length > 0) {
        await selectUpl(upls.value[0].uplKey);
      } else if (selectedUplKey.value != null) {
        await loadLauncher(selectedUplKey.value);
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
  async function selectUpl(uplKey: number): Promise<void> {
    selectedUplKey.value = uplKey;
    loading.value = true;
    error.value = null;
    try {
      await loadLauncher(uplKey);
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

  /**
   * Прогон воронки (excelToTbl читает cidufPath из БД; прочие — stub).
   */
  async function runFunnel(steps: string[], flLoad: boolean): Promise<SudzDbtUplFunnelResult | null> {
    if (selectedUplKey.value == null) {
      return null;
    }
    funnelRunning.value = true;
    error.value = null;
    try {
      const result = await runSudzDbtUplFunnel({
        uplKey: selectedUplKey.value,
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
    loadUpls,
    selectUpl,
    createUpl,
    saveFile,
    patchFileFlags,
    runFunnel,
    runFunnelStub
  };
});
