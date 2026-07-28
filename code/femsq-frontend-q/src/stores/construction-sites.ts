/**
 * Pinia store для экрана «Стройки» (форма cst + дерево агенты→САК→филиал).
 */

import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { RequestError } from '@/api/http';
import {
  createConstructionSite,
  createCstAgent,
  createCstAgPoint,
  createCstAgPnBranch,
  createRaReport,
  createRaSumm,
  createRalpRa,
  createRalpRaAu,
  deleteConstructionSite,
  deleteCstAgent,
  deleteCstAgPoint,
  deleteCstAgPnBranch,
  deleteRaReport,
  deleteRaSumm,
  deleteRalpRa,
  deleteRalpRaAu,
  getConstructionSites,
  getConstructionSite,
  getConstructionSiteReport,
  getCstAgents,
  getCstAgPoints,
  getCstAgPnBranches,
  getCstAgPnCodes,
  getCstAgPnLookupsForSite,
  getCstRaList,
  getCstRalpRaList,
  getOgAgCsLookups,
  getRaPeriodLookups,
  getRaSums,
  getRalpRa,
  getRalpRaAus,
  getRalpRaAuStatusLookups,
  updateConstructionSite,
  updateCstAgent,
  updateCstAgPoint,
  updateCstAgPnBranch,
  updateRaReport,
  updateRaSumm,
  updateRalpRa,
  updateRalpRaAu
} from '@/api/construction-sites-api';
import { getOrganizationsLookup } from '@/api/organizations-api';
import type {
  ConstructionSiteDto,
  CstAgCreateRequest,
  CstAgPnBranchCreateRequest,
  CstAgPnBranchDto,
  CstAgPnBranchUpdateRequest,
  CstAgPnCodeDto,
  CstAgPnCreateRequest,
  CstAgPnSiteLookupDto,
  CstAgPointDto,
  CstAgPnUpdateRequest,
  CstAgUpdateRequest,
  CstAgentDto,
  CstCreateRequest,
  CstRaListEntryDto,
  CstUpdateRequest,
  OgAgCsLookupDto,
  RaPeriodLookupDto,
  RaReportCreateRequest,
  RaReportDto,
  RaReportUpdateRequest,
  RaSummCreateRequest,
  RaSummDto,
  RaSummUpdateRequest,
  RalpRaAuCreateRequest,
  RalpRaAuDto,
  RalpRaAuStatusLookupDto,
  RalpRaAuUpdateRequest,
  RalpRaCreateRequest,
  RalpRaCstListEntryDto,
  RalpRaDto,
  RalpRaUpdateRequest
} from '@/types/construction-sites';
import type { OrganizationLookupDto } from '@/types/files';

function toErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof RequestError) {
    return error.message || fallback;
  }
  if (error instanceof Error) {
    return error.message || fallback;
  }
  return fallback;
}

export const useConstructionSitesStore = defineStore('construction-sites', () => {
  const sites = ref<ConstructionSiteDto[]>([]);
  const selectedCstKey = ref<number | null>(null);
  const agents = ref<CstAgentDto[]>([]);
  /** Кэш САК по cstaKey — несколько веток раскрыты одновременно. */
  const pointsByCsta = reactive<Record<number, CstAgPointDto[]>>({});
  /** Кэш филиалов по cstapKey. */
  const branchesByCstap = reactive<Record<number, CstAgPnBranchDto[]>>({});
  const expandedAgents = ref<Set<number>>(new Set());
  const expandedPoints = ref<Set<number>>(new Set());
  const loadingChildren = reactive<Record<string, boolean>>({});

  const agentLookups = ref<OgAgCsLookupDto[]>([]);
  const organizationLookups = ref<OrganizationLookupDto[]>([]);
  const codeEntries = ref<CstAgPnCodeDto[]>([]);
  const selectedCodeKey = ref<number | null>(null);
  const loadingCodes = ref(false);

  const raList = ref<CstRaListEntryDto[]>([]);
  const selectedRaKey = ref<number | null>(null);
  const selectedReport = ref<RaReportDto | null>(null);
  const raSums = ref<RaSummDto[]>([]);
  const raPeriodLookups = ref<RaPeriodLookupDto[]>([]);
  const sitePnLookups = ref<CstAgPnSiteLookupDto[]>([]);
  const loadingRaList = ref(false);
  const loadingReport = ref(false);
  const loadingRaSums = ref(false);

  const ralpRaList = ref<RalpRaCstListEntryDto[]>([]);
  const selectedRalpRaKey = ref<number | null>(null);
  const selectedRalpRa = ref<RalpRaDto | null>(null);
  const ralpRaAus = ref<RalpRaAuDto[]>([]);
  const ralpRaAuStatusLookups = ref<RalpRaAuStatusLookupDto[]>([]);
  const loadingRalpRaList = ref(false);
  const loadingRalpRa = ref(false);
  const loadingRalpRaAus = ref(false);

  const loadingSites = ref(false);
  const loadingAgents = ref(false);
  const saving = ref(false);
  const error = ref<string | null>(null);

  const selectedSite = computed(() =>
    sites.value.find((site) => site.cstKey === selectedCstKey.value) ?? null
  );
  const selectedCode = computed(() =>
    codeEntries.value.find((entry) => entry.cstapKey === selectedCodeKey.value) ?? null
  );
  const selectedRaListRow = computed(() => {
    if (selectedRaKey.value == null) {
      return null;
    }
    return (
      raList.value.find((row) => row.raKey === selectedRaKey.value && row.raChKey == null) ?? null
    );
  });

  /**
   * Загружает список строек и lookup-словари.
   */
  async function loadSites(): Promise<void> {
    loadingSites.value = true;
    error.value = null;
    try {
      const [siteList, lookups, orgs] = await Promise.all([
        getConstructionSites(),
        getOgAgCsLookups(),
        getOrganizationsLookup()
      ]);
      sites.value = siteList;
      agentLookups.value = lookups;
      organizationLookups.value = orgs;
      if (selectedCstKey.value == null && siteList.length > 0) {
        await selectSite(siteList[0].cstKey);
      } else if (selectedCstKey.value != null) {
        const stillExists = siteList.some((site) => site.cstKey === selectedCstKey.value);
        if (stillExists) {
          await selectSite(selectedCstKey.value);
        } else if (siteList.length > 0) {
          await selectSite(siteList[0].cstKey);
        } else {
          clearDetail();
        }
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить стройки');
      sites.value = [];
      clearDetail();
    } finally {
      loadingSites.value = false;
    }
  }

  function clearTreeCaches(): void {
    Object.keys(pointsByCsta).forEach((key) => {
      delete pointsByCsta[Number(key)];
    });
    Object.keys(branchesByCstap).forEach((key) => {
      delete branchesByCstap[Number(key)];
    });
    Object.keys(loadingChildren).forEach((key) => {
      delete loadingChildren[key];
    });
    expandedAgents.value = new Set();
    expandedPoints.value = new Set();
  }

  /**
   * Загружает список кодов САК (форма Access cstAgPn).
   */
  async function loadCodes(codeFilter?: string | null): Promise<void> {
    loadingCodes.value = true;
    error.value = null;
    try {
      if (agentLookups.value.length === 0 || organizationLookups.value.length === 0) {
        const [lookups, orgs] = await Promise.all([getOgAgCsLookups(), getOrganizationsLookup()]);
        agentLookups.value = lookups;
        organizationLookups.value = orgs;
      }
      codeEntries.value = await getCstAgPnCodes(codeFilter);
      if (selectedCodeKey.value != null) {
        const still = codeEntries.value.some((entry) => entry.cstapKey === selectedCodeKey.value);
        if (!still) {
          selectedCodeKey.value = null;
        }
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить список САК');
      codeEntries.value = [];
    } finally {
      loadingCodes.value = false;
    }
  }

  /**
   * Выбирает код САК и открывает связанную стройку с раскрытием ветки до этого САК.
   */
  async function selectCode(entry: CstAgPnCodeDto): Promise<void> {
    selectedCodeKey.value = entry.cstapKey;
    error.value = null;
    try {
      if (!sites.value.some((site) => site.cstKey === entry.cstaCst)) {
        const site = await getConstructionSite(entry.cstaCst);
        if (site != null) {
          sites.value = [...sites.value, site];
        } else {
          sites.value = [
            ...sites.value,
            { cstKey: entry.cstaCst, cstName: entry.cstName || `cstKey=${entry.cstaCst}` }
          ];
        }
      }
      await selectSite(entry.cstaCst);
      expandedAgents.value = new Set([entry.cstapCsta]);
      await ensurePoints(entry.cstapCsta);
      expandedPoints.value = new Set([entry.cstapKey]);
      await ensureBranches(entry.cstapKey);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось открыть стройку по коду САК');
    }
  }

  function clearDetail(): void {
    selectedCstKey.value = null;
    agents.value = [];
    clearTreeCaches();
    clearReports();
    clearRentReports();
  }

  function clearReports(): void {
    raList.value = [];
    selectedRaKey.value = null;
    selectedReport.value = null;
    raSums.value = [];
    sitePnLookups.value = [];
  }

  function clearRentReports(): void {
    ralpRaList.value = [];
    selectedRalpRaKey.value = null;
    selectedRalpRa.value = null;
    ralpRaAus.value = [];
  }

  /**
   * Выбирает стройку и загружает агентов (аналог Form_cst.Form_Current → Requery списков).
   * Порядок: сначала очистка, потом смена ключа — иначе watch не сработает при том же cstKey,
   * а clearReports опустошит уже загруженный перечень отчётов.
   */
  async function selectSite(cstKey: number): Promise<void> {
    const sameKey = selectedCstKey.value === cstKey;
    clearTreeCaches();
    clearReports();
    clearRentReports();
    selectedCstKey.value = cstKey;
    await loadAgents(cstKey);
    // watch на selectedCstKey не сработает при повторном выборе той же стройки
    if (sameKey) {
      await loadRaList(cstKey);
      await loadRalpRaList(cstKey);
    }
  }

  /**
   * Загружает перечень отчётов стройки (вкладка «отчёты»).
   */
  async function loadRaList(cstKey?: number | null): Promise<void> {
    const key = cstKey ?? selectedCstKey.value;
    if (key == null) {
      clearReports();
      return;
    }
    loadingRaList.value = true;
    error.value = null;
    try {
      if (raPeriodLookups.value.length === 0) {
        raPeriodLookups.value = await getRaPeriodLookups();
      }
      const [list, pnLookups] = await Promise.all([
        getCstRaList(key),
        getCstAgPnLookupsForSite(key)
      ]);
      raList.value = list;
      sitePnLookups.value = pnLookups;
      if (selectedRaKey.value != null) {
        const still = list.some((row) => row.raKey === selectedRaKey.value && row.raChKey == null);
        if (still) {
          await selectRa(selectedRaKey.value);
        } else {
          selectedRaKey.value = null;
          selectedReport.value = null;
          raSums.value = [];
        }
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить перечень отчётов');
      raList.value = [];
    } finally {
      loadingRaList.value = false;
    }
  }

  /**
   * Выбирает базовый отчёт и загружает карточку + суммы.
   * Строки изменений ({@code raChKey != null}) игнорируются.
   */
  async function selectRa(raKey: number): Promise<void> {
    selectedRaKey.value = raKey;
    loadingReport.value = true;
    loadingRaSums.value = true;
    error.value = null;
    try {
      const [report, sums] = await Promise.all([
        getConstructionSiteReport(raKey),
        getRaSums(raKey)
      ]);
      selectedReport.value = report;
      raSums.value = sums;
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить отчёт');
      selectedReport.value = null;
      raSums.value = [];
    } finally {
      loadingReport.value = false;
      loadingRaSums.value = false;
    }
  }

  async function saveReport(input: RaReportCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        const created = await createRaReport(input);
        await loadRaList();
        await selectRa(created.raKey);
      } else {
        const update: RaReportUpdateRequest = input;
        await updateRaReport(id, update);
        await loadRaList();
        await selectRa(id);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить отчёт');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeReport(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteRaReport(id);
      if (selectedRaKey.value === id) {
        selectedRaKey.value = null;
        selectedReport.value = null;
        raSums.value = [];
      }
      await loadRaList();
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить отчёт');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveSumm(input: RaSummCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createRaSumm(input);
      } else {
        const update: RaSummUpdateRequest = input;
        await updateRaSumm(id, update);
      }
      await loadRaList();
      if (selectedRaKey.value != null) {
        await selectRa(selectedRaKey.value);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить суммы');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeSumm(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteRaSumm(id);
      await loadRaList();
      if (selectedRaKey.value != null) {
        await selectRa(selectedRaKey.value);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить суммы');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Загружает перечень отчётов аренды стройки (вкладка «отчёты, аренда»).
   */
  async function loadRalpRaList(cstKey?: number | null): Promise<void> {
    const key = cstKey ?? selectedCstKey.value;
    if (key == null) {
      clearRentReports();
      return;
    }
    loadingRalpRaList.value = true;
    error.value = null;
    try {
      if (ralpRaAuStatusLookups.value.length === 0) {
        ralpRaAuStatusLookups.value = await getRalpRaAuStatusLookups();
      }
      const [list, pnLookups] = await Promise.all([
        getCstRalpRaList(key),
        getCstAgPnLookupsForSite(key)
      ]);
      ralpRaList.value = list;
      sitePnLookups.value = pnLookups;
      if (selectedRalpRaKey.value != null) {
        const still = list.some((row) => row.ralprKey === selectedRalpRaKey.value);
        if (still) {
          await selectRalpRa(selectedRalpRaKey.value);
        } else {
          selectedRalpRaKey.value = null;
          selectedRalpRa.value = null;
          ralpRaAus.value = [];
        }
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить отчёты аренды');
      ralpRaList.value = [];
    } finally {
      loadingRalpRaList.value = false;
    }
  }

  /**
   * Выбирает отчёт аренды и загружает карточку + строки Au.
   */
  async function selectRalpRa(ralprKey: number): Promise<void> {
    selectedRalpRaKey.value = ralprKey;
    loadingRalpRa.value = true;
    loadingRalpRaAus.value = true;
    error.value = null;
    try {
      const [report, aus] = await Promise.all([getRalpRa(ralprKey), getRalpRaAus(ralprKey)]);
      selectedRalpRa.value = report;
      ralpRaAus.value = aus;
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить отчёт аренды');
      selectedRalpRa.value = null;
      ralpRaAus.value = [];
    } finally {
      loadingRalpRa.value = false;
      loadingRalpRaAus.value = false;
    }
  }

  async function saveRalpRa(input: RalpRaCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        const created = await createRalpRa(input);
        await loadRalpRaList();
        await selectRalpRa(created.ralprKey);
      } else {
        const update: RalpRaUpdateRequest = input;
        await updateRalpRa(id, update);
        await loadRalpRaList();
        await selectRalpRa(id);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить отчёт аренды');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeRalpRa(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteRalpRa(id);
      if (selectedRalpRaKey.value === id) {
        selectedRalpRaKey.value = null;
        selectedRalpRa.value = null;
        ralpRaAus.value = [];
      }
      await loadRalpRaList();
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить отчёт аренды');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveRalpRaAu(input: RalpRaAuCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createRalpRaAu(input);
      } else {
        const update: RalpRaAuUpdateRequest = input;
        await updateRalpRaAu(id, update);
      }
      if (selectedRalpRaKey.value != null) {
        await selectRalpRa(selectedRalpRaKey.value);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить строку Au');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeRalpRaAu(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteRalpRaAu(id);
      if (selectedRalpRaKey.value != null) {
        await selectRalpRa(selectedRalpRaKey.value);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить строку Au');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Загружает агентов выбранной стройки.
   */
  async function loadAgents(cstKey: number): Promise<void> {
    loadingAgents.value = true;
    error.value = null;
    try {
      agents.value = await getCstAgents(cstKey);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить агентов стройки');
      agents.value = [];
    } finally {
      loadingAgents.value = false;
    }
  }

  /**
   * Раскрывает/сворачивает агента; при раскрытии подгружает САК.
   */
  async function toggleAgent(cstaKey: number): Promise<void> {
    const next = new Set(expandedAgents.value);
    if (next.has(cstaKey)) {
      next.delete(cstaKey);
      expandedAgents.value = next;
      return;
    }
    next.add(cstaKey);
    expandedAgents.value = next;
    await ensurePoints(cstaKey);
  }

  /**
   * Раскрывает/сворачивает САК; при раскрытии подгружает филиалы.
   */
  async function togglePoint(cstapKey: number): Promise<void> {
    const next = new Set(expandedPoints.value);
    if (next.has(cstapKey)) {
      next.delete(cstapKey);
      expandedPoints.value = next;
      return;
    }
    next.add(cstapKey);
    expandedPoints.value = next;
    await ensureBranches(cstapKey);
  }

  async function ensurePoints(cstaKey: number, force = false): Promise<void> {
    if (!force && pointsByCsta[cstaKey] != null) {
      return;
    }
    const loadKey = `p:${cstaKey}`;
    loadingChildren[loadKey] = true;
    error.value = null;
    try {
      pointsByCsta[cstaKey] = await getCstAgPoints(cstaKey);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить САК');
      pointsByCsta[cstaKey] = [];
    } finally {
      loadingChildren[loadKey] = false;
    }
  }

  async function ensureBranches(cstapKey: number, force = false): Promise<void> {
    if (!force && branchesByCstap[cstapKey] != null) {
      return;
    }
    const loadKey = `b:${cstapKey}`;
    loadingChildren[loadKey] = true;
    error.value = null;
    try {
      branchesByCstap[cstapKey] = await getCstAgPnBranches(cstapKey);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось загрузить филиалы САК');
      branchesByCstap[cstapKey] = [];
    } finally {
      loadingChildren[loadKey] = false;
    }
  }

  function isAgentExpanded(cstaKey: number): boolean {
    return expandedAgents.value.has(cstaKey);
  }

  function isPointExpanded(cstapKey: number): boolean {
    return expandedPoints.value.has(cstapKey);
  }

  function isLoadingPoints(cstaKey: number): boolean {
    return Boolean(loadingChildren[`p:${cstaKey}`]);
  }

  function isLoadingBranches(cstapKey: number): boolean {
    return Boolean(loadingChildren[`b:${cstapKey}`]);
  }

  async function saveSite(input: CstCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        const created = await createConstructionSite(input);
        await loadSites();
        await selectSite(created.cstKey);
      } else {
        const update: CstUpdateRequest = input;
        await updateConstructionSite(id, update);
        await loadSites();
        await selectSite(id);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить стройку');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeSite(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteConstructionSite(id);
      await loadSites();
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить стройку');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveAgent(input: CstAgCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        const created = await createCstAgent(input);
        await loadAgents(input.cstaCst);
        expandedAgents.value = new Set(expandedAgents.value).add(created.cstaKey);
        await ensurePoints(created.cstaKey, true);
      } else {
        const update: CstAgUpdateRequest = input;
        await updateCstAgent(id, update);
        await loadAgents(input.cstaCst);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить агента');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeAgent(id: number, cstKey: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCstAgent(id);
      delete pointsByCsta[id];
      const next = new Set(expandedAgents.value);
      next.delete(id);
      expandedAgents.value = next;
      await loadAgents(cstKey);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить агента');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function savePoint(input: CstAgPnCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        const created = await createCstAgPoint(input);
        await ensurePoints(input.cstapCsta, true);
        expandedAgents.value = new Set(expandedAgents.value).add(input.cstapCsta);
        expandedPoints.value = new Set(expandedPoints.value).add(created.cstapKey);
        await ensureBranches(created.cstapKey, true);
      } else {
        const update: CstAgPnUpdateRequest = input;
        await updateCstAgPoint(id, update);
        await ensurePoints(input.cstapCsta, true);
      }
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить САК');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removePoint(id: number, cstaKey: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCstAgPoint(id);
      delete branchesByCstap[id];
      const next = new Set(expandedPoints.value);
      next.delete(id);
      expandedPoints.value = next;
      await ensurePoints(cstaKey, true);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить САК');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveBranch(input: CstAgPnBranchCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createCstAgPnBranch(input);
      } else {
        const update: CstAgPnBranchUpdateRequest = input;
        await updateCstAgPnBranch(id, update);
      }
      expandedPoints.value = new Set(expandedPoints.value).add(input.cstapbCstAgPn);
      await ensureBranches(input.cstapbCstAgPn, true);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось сохранить филиал');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeBranch(id: number, cstapKey: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCstAgPnBranch(id);
      await ensureBranches(cstapKey, true);
    } catch (err) {
      error.value = toErrorMessage(err, 'Не удалось удалить филиал');
      throw err;
    } finally {
      saving.value = false;
    }
  }

  return {
    sites,
    selectedCstKey,
    agents,
    pointsByCsta,
    branchesByCstap,
    agentLookups,
    organizationLookups,
    codeEntries,
    selectedCodeKey,
    loadingCodes,
    raList,
    selectedRaKey,
    selectedReport,
    raSums,
    raPeriodLookups,
    sitePnLookups,
    loadingRaList,
    loadingReport,
    loadingRaSums,
    ralpRaList,
    selectedRalpRaKey,
    selectedRalpRa,
    ralpRaAus,
    ralpRaAuStatusLookups,
    loadingRalpRaList,
    loadingRalpRa,
    loadingRalpRaAus,
    loadingSites,
    loadingAgents,
    saving,
    error,
    selectedSite,
    selectedCode,
    selectedRaListRow,
    loadSites,
    loadCodes,
    selectSite,
    selectCode,
    loadRaList,
    selectRa,
    saveReport,
    removeReport,
    saveSumm,
    removeSumm,
    loadRalpRaList,
    selectRalpRa,
    saveRalpRa,
    removeRalpRa,
    saveRalpRaAu,
    removeRalpRaAu,
    toggleAgent,
    togglePoint,
    isAgentExpanded,
    isPointExpanded,
    isLoadingPoints,
    isLoadingBranches,
    saveSite,
    removeSite,
    saveAgent,
    removeAgent,
    savePoint,
    removePoint,
    saveBranch,
    removeBranch
  };
});
