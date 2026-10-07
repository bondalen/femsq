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
  getSudzPmtUplCstMatch,
  getSudzPmtUplCstNew,
  getSudzPmtUplInvNot,
  getSudzPmtUplSfDoubles,
  getSudzPmtUplTabBadges,
  getSudzPmtUplTwoLoad,
  rebuildSudzPmtUplSfDouble,
  runSudzPmtUplFunnel,
  updateSudzPmUplFile
} from '@/api/sudz-api';
import type {
  CreateSudzPmUplInput,
  SudzCnInvUplSfDouble,
  SudzPmUplLookup,
  SudzPmtUplCstMatch,
  SudzPmtUplCstNew,
  SudzPmtUplFile,
  SudzPmtUplFunnelResult,
  SudzPmtUplInvNot,
  SudzPmtUplLauncher,
  SudzPmtUplTabBadges,
  SudzPmtUplTwoLoad,
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
  const cstNew = ref<SudzPmtUplCstNew[]>([]);
  const cstNewLoading = ref(false);
  const invNot = ref<SudzPmtUplInvNot[]>([]);
  const invNotLoading = ref(false);
  const twoLoad = ref<SudzPmtUplTwoLoad[]>([]);
  const twoLoadLoading = ref(false);
  const sfDoubles = ref<SudzCnInvUplSfDouble[]>([]);
  const sfDoublesLoading = ref(false);
  const badges = ref<SudzPmtUplTabBadges | null>(null);
  const badgesLoading = ref(false);
  const cstMatch = ref<SudzPmtUplCstMatch[]>([]);
  const cstMatchSuffix = ref<string | null>(null);
  const cstMatchLoading = ref(false);

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
          clearQueues();
        }
      }
      if (selectedPmKey.value == null && upls.value.length > 0) {
        await selectUpl(upls.value[0].pmKey);
      } else if (selectedPmKey.value != null) {
        await loadLauncher(selectedPmKey.value);
        await refreshQueues();
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
    const queues = refreshQueues();
    try {
      await loadLauncher(pmKey);
    } finally {
      loading.value = false;
    }
    await queues;
  }

  /**
   * Сбрасывает гриды очередей и бейджи.
   */
  function clearQueues(): void {
    cstNew.value = [];
    invNot.value = [];
    twoLoad.value = [];
    sfDoubles.value = [];
    badges.value = null;
    cstNewLoading.value = false;
    invNotLoading.value = false;
    twoLoadLoading.value = false;
    sfDoublesLoading.value = false;
    badgesLoading.value = false;
    clearCstMatch();
  }

  /**
   * Сбрасывает дерево строек выбранной строки очереди.
   */
  function clearCstMatch(): void {
    cstMatch.value = [];
    cstMatchSuffix.value = null;
    cstMatchLoading.value = false;
  }

  /**
   * Стройки каталога с тем же хвостом из 6 символов, что у выбранной строки очереди.
   * Ответ устаревшего хвоста отбрасывается. Пустой список — такого хвоста нет.
   *
   * @param codeSuffix sh строки очереди
   */
  async function loadCstMatch(codeSuffix: string): Promise<void> {
    const suffix = codeSuffix.trim();
    cstMatchSuffix.value = suffix;
    if (suffix.length !== 6) {
      cstMatch.value = [];
      cstMatchLoading.value = false;
      return;
    }
    cstMatchLoading.value = true;
    try {
      const rows = await getSudzPmtUplCstMatch(suffix);
      if (cstMatchSuffix.value === suffix) {
        cstMatch.value = rows;
      }
    } catch (e) {
      if (cstMatchSuffix.value === suffix) {
        cstMatch.value = [];
        error.value = e instanceof Error ? e.message : String(e);
      }
    } finally {
      if (cstMatchSuffix.value === suffix) {
        cstMatchLoading.value = false;
      }
    }
  }

  /**
   * Очереди вкладок D и бейджи для выбранного пакета.
   * Ответ устаревшего pmKey отбрасывается.
   */
  async function refreshQueues(): Promise<void> {
    const pmKey = selectedPmKey.value;
    if (pmKey == null) {
      clearQueues();
      return;
    }
    cstNew.value = [];
    invNot.value = [];
    twoLoad.value = [];
    sfDoubles.value = [];
    badges.value = null;
    cstNewLoading.value = true;
    invNotLoading.value = true;
    twoLoadLoading.value = true;
    sfDoublesLoading.value = true;
    badgesLoading.value = true;
    const rebuildTask = (async () => {
      try {
        let rows = await getSudzPmtUplSfDoubles(pmKey);
        // Пустая очередь при живом хвосте — один sync; не пересобирать, если уже есть строки
        // (иначе сбросятся status created/deferred после разбора в КСДСФ).
        if (rows.length === 0) {
          await rebuildSudzPmtUplSfDouble(pmKey);
          rows = await getSudzPmtUplSfDoubles(pmKey);
        }
        if (selectedPmKey.value === pmKey) {
          sfDoubles.value = rows;
        }
      } catch (e: unknown) {
        if (selectedPmKey.value === pmKey) {
          sfDoubles.value = [];
          error.value = e instanceof Error ? e.message : String(e);
        }
      } finally {
        if (selectedPmKey.value === pmKey) {
          sfDoublesLoading.value = false;
        }
      }
    })();
    const cstTask = getSudzPmtUplCstNew(pmKey)
      .then((rows) => {
        if (selectedPmKey.value === pmKey) {
          cstNew.value = rows;
        }
      })
      .catch((e: unknown) => {
        if (selectedPmKey.value === pmKey) {
          cstNew.value = [];
          error.value = e instanceof Error ? e.message : String(e);
        }
      })
      .finally(() => {
        if (selectedPmKey.value === pmKey) {
          cstNewLoading.value = false;
        }
      });
    const invNotTask = getSudzPmtUplInvNot(pmKey)
      .then((rows) => {
        if (selectedPmKey.value === pmKey) {
          invNot.value = rows;
        }
      })
      .catch((e: unknown) => {
        if (selectedPmKey.value === pmKey) {
          invNot.value = [];
          error.value = e instanceof Error ? e.message : String(e);
        }
      })
      .finally(() => {
        if (selectedPmKey.value === pmKey) {
          invNotLoading.value = false;
        }
      });
    const twoLoadTask = getSudzPmtUplTwoLoad(pmKey)
      .then((rows) => {
        if (selectedPmKey.value === pmKey) {
          twoLoad.value = rows;
        }
      })
      .catch((e: unknown) => {
        if (selectedPmKey.value === pmKey) {
          twoLoad.value = [];
          error.value = e instanceof Error ? e.message : String(e);
        }
      })
      .finally(() => {
        if (selectedPmKey.value === pmKey) {
          twoLoadLoading.value = false;
        }
      });
    const badgeTask = getSudzPmtUplTabBadges(pmKey)
      .then((value) => {
        if (selectedPmKey.value === pmKey) {
          badges.value = value;
        }
      })
      .catch((e: unknown) => {
        if (selectedPmKey.value === pmKey) {
          badges.value = null;
          error.value = e instanceof Error ? e.message : String(e);
        }
      })
      .finally(() => {
        if (selectedPmKey.value === pmKey) {
          badgesLoading.value = false;
        }
      });
    await Promise.all([cstTask, invNotTask, twoLoadTask, badgeTask, rebuildTask]);
  }

  /**
   * Перечитывает очередь КСДСФ пакета без rebuild (после разбора на экране КСДСФ).
   */
  async function refreshSfDoubles(): Promise<void> {
    const pmKey = selectedPmKey.value;
    if (pmKey == null) {
      sfDoubles.value = [];
      return;
    }
    sfDoublesLoading.value = true;
    try {
      const rows = await getSudzPmtUplSfDoubles(pmKey);
      if (selectedPmKey.value === pmKey) {
        sfDoubles.value = rows;
      }
    } catch (e: unknown) {
      if (selectedPmKey.value === pmKey) {
        error.value = e instanceof Error ? e.message : String(e);
      }
    } finally {
      if (selectedPmKey.value === pmKey) {
        sfDoublesLoading.value = false;
      }
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
   * L1: пока идёт mutation, опрашиваем launcher — mid Progress в UI.
   */
  async function runFunnel(steps: string[], flLoad: boolean): Promise<SudzPmtUplFunnelResult | null> {
    if (selectedPmKey.value == null) {
      return null;
    }
    const pmKey = selectedPmKey.value;
    funnelRunning.value = true;
    error.value = null;
    const pollMs = 2000;
    const pollTimer = window.setInterval(() => {
      void loadLauncher(pmKey).catch(() => {
        /* mid-poll: не ронять воронку */
      });
    }, pollMs);
    try {
      const result = await runSudzPmtUplFunnel({
        pmKey,
        steps,
        flLoad
      });
      await loadLauncher(pmKey);
      await refreshQueues();
      return result;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      try {
        await loadLauncher(pmKey);
        await refreshQueues();
      } catch {
        // progress мог обновиться на сервере до ошибки ответа
      }
      return null;
    } finally {
      window.clearInterval(pollTimer);
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
    cstNew,
    cstNewLoading,
    invNot,
    invNotLoading,
    twoLoad,
    twoLoadLoading,
    sfDoubles,
    sfDoublesLoading,
    badges,
    badgesLoading,
    cstMatch,
    cstMatchSuffix,
    cstMatchLoading,
    loadCstMatch,
    clearCstMatch,
    refreshQueues,
    refreshSfDoubles,
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
