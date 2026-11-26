/**
 * Стор Leaves §2.5.2: ИП, дерево пунктов (корень ipgPn), Structure; Планы/Лимиты — stub.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  applyImpIpgPoints,
  getImpIpgLoads,
  type ImpIpgLoadDto,
  type ImpIpgPointsApplyResultDto
} from '@/api/imp-ipg-load-api';
import {
  addIpgPnStructure,
  createIpgPn,
  createInvestmentProgram,
  deleteIpgPn,
  getIpgPnStructure,
  getIpgSchemes,
  getInvestmentProgramPoints,
  getInvestmentProgramsFull,
  removeIpgPnStructure,
  updateIpgPn,
  updateInvestmentProgram,
  type CreateIpgInput,
  type CreateIpgPnInput,
  type IpgFullDto,
  type IpgPnDto,
  type IpgShDto,
  type IpgStPnDto,
  type UpdateIpgInput,
  type UpdateIpgPnInput
} from '@/api/ipg-leaves-api';

/**
 * Доменный вид узла Leaves (не путать с FemsqTreeList `kind` record/folder).
 */
export type LeavesTreeKind =
  | 'pn'
  | 'folderStruct'
  | 'folderPlans'
  | 'folderLimits'
  | 'stBind'
  | 'stub';

/** Уровень columnSets FemsqTreeList (§3.2.8.4). */
export type LeavesTreeLevel = 'pn' | 'axis' | 'bind' | 'stub';

/** Узел колоночного дерева пунктов. */
export interface LeavesTreeNode {
  key: string;
  /** FemsqTreeList: запись / папка. */
  kind: 'record' | 'folder';
  /** Комплект колонок. */
  level: LeavesTreeLevel;
  /** Доменная семантика (selection / CRUD). */
  domainKind: LeavesTreeKind;
  label: string;
  ipgpKey?: number;
  ipgspKey?: number;
  stiKey?: number;
  num?: number | null;
  code?: string | null;
  shName?: string | null;
  smTtl?: number | null;
  smWrk?: number | null;
  smEqu?: number | null;
  smOth?: number | null;
  smAgFee?: number | null;
  costAdjust?: number | null;
  smReserv?: number | null;
  cstName?: string | null;
  ogName?: string | null;
  note?: string | null;
  leaf?: boolean;
  children?: LeavesTreeNode[];
}

const STUB_LATER = 'Загрузка в этапе 1.3 (UtPl / stCost)';

/**
 * Дерево пунктов (корни ipgPn, оси Structure/Планы/Лимиты).
 * Фильтрация корней — в FemsqTreeList (L6 / §3.2.9), не здесь.
 */
export function buildLeavesTree(
  points: IpgPnDto[],
  structureByPn: Record<number, IpgStPnDto[]>
): LeavesTreeNode[] {
  return points.map((pn) => {
    const binds = structureByPn[pn.ipgpKey] ?? [];
    const structChildren: LeavesTreeNode[] =
      binds.length === 0
        ? [
            {
              key: `stub-struct-${pn.ipgpKey}`,
              kind: 'record',
              level: 'stub',
              domainKind: 'stub',
              label: 'Нет привязок — добавьте stiKey',
              ipgpKey: pn.ipgpKey,
              leaf: true
            }
          ]
        : binds.map((b) => ({
            key: `st:${b.ipgspKey}`,
            kind: 'record' as const,
            level: 'bind' as const,
            domainKind: 'stBind' as const,
            label: b.stName?.trim() || `sti=${b.ipgspSt}`,
            ipgpKey: pn.ipgpKey,
            ipgspKey: b.ipgspKey,
            stiKey: b.ipgspSt,
            leaf: true
          }));

    const code = pn.cstAgPnCode?.trim() || `cstAgPn=${pn.ipgpCstAgPn}`;
    return {
      key: `pn:${pn.ipgpKey}`,
      kind: 'record' as const,
      level: 'pn' as const,
      domainKind: 'pn' as const,
      label: code,
      ipgpKey: pn.ipgpKey,
      num: pn.ipgpNum,
      code,
      cstName: pn.cstAgPnCstName,
      ogName: pn.cstAgPnOgName,
      shName: pn.ipgpShName,
      smTtl: pn.ipgpSmTtl,
      smWrk: pn.ipgpSmWrk,
      smEqu: pn.ipgpSmEqu,
      smOth: pn.ipgpSmOth,
      smAgFee: pn.ipgpSmAgFee,
      costAdjust: pn.ipgpCostAdjust,
      smReserv: pn.ipgpSmReserv,
      note: pn.ipgpTskCms,
      leaf: false,
      children: [
        {
          key: `folder:${pn.ipgpKey}:struct`,
          kind: 'folder' as const,
          level: 'axis' as const,
          domainKind: 'folderStruct' as const,
          label: 'Структура ИПГ',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: structChildren
        },
        {
          key: `folder:${pn.ipgpKey}:plans`,
          kind: 'folder' as const,
          level: 'axis' as const,
          domainKind: 'folderPlans' as const,
          label: 'Планы',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: [
            {
              key: `stub-plans-${pn.ipgpKey}`,
              kind: 'record' as const,
              level: 'stub' as const,
              domainKind: 'stub' as const,
              label: STUB_LATER,
              ipgpKey: pn.ipgpKey,
              leaf: true
            }
          ]
        },
        {
          key: `folder:${pn.ipgpKey}:limits`,
          kind: 'folder' as const,
          level: 'axis' as const,
          domainKind: 'folderLimits' as const,
          label: 'Лимиты',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: [
            {
              key: `stub-limits-${pn.ipgpKey}`,
              kind: 'record' as const,
              level: 'stub' as const,
              domainKind: 'stub' as const,
              label: STUB_LATER,
              ipgpKey: pn.ipgpKey,
              leaf: true
            }
          ]
        }
      ]
    };
  });
}

export const useIpgLeavesStore = defineStore('ipgLeaves', () => {
  const programs = ref<IpgFullDto[]>([]);
  const selectedIpgKey = ref<number | null>(null);
  const points = ref<IpgPnDto[]>([]);
  const structureByPn = ref<Record<number, IpgStPnDto[]>>({});
  const schemes = ref<IpgShDto[]>([]);
  const selectedTreeKey = ref<string | null>(null);
  const selectedIpgpKey = ref<number | null>(null);

  const yearFilter = ref<number | null>(null);
  const nameFilter = ref('');

  const loadingPrograms = ref(false);
  const loadingPoints = ref(false);
  const loadingStructure = ref(false);
  const mutating = ref(false);
  const error = ref<string | null>(null);

  /** Сессии load текущей ИП — вкладка «Загрузка пунктов» (§3.2.8.3). */
  const loads = ref<ImpIpgLoadDto[]>([]);
  const selectedLoadKey = ref<number | null>(null);
  const previousIpgKeyForApply = ref<number | null>(null);
  const applyResult = ref<ImpIpgPointsApplyResultDto | null>(null);
  const loadingLoads = ref(false);
  const applyingPoints = ref(false);

  const selectedProgram = computed(
    () => programs.value.find((p) => p.ipgKey === selectedIpgKey.value) ?? null
  );

  const selectedLoad = computed(
    () => loads.value.find((item) => item.id === selectedLoadKey.value) ?? null
  );

  /**
   * HTML «Ход загрузки» (C2 §3.5.4): последний ответ apply (в т.ч. dry-run) либо сохранённый
   * {@code iilResults} выбранной сессии.
   */
  const loadLogHtml = computed(
    () => applyResult.value?.logHtml ?? selectedLoad.value?.logHtml ?? null
  );

  const selectedPoint = computed(
    () => points.value.find((p) => p.ipgpKey === selectedIpgpKey.value) ?? null
  );

  const treeNodes = computed(() => buildLeavesTree(points.value, structureByPn.value));

  /**
   * Загружает список ИП.
   */
  async function fetchPrograms(preferKey?: number | null): Promise<void> {
    loadingPrograms.value = true;
    error.value = null;
    try {
      programs.value = await getInvestmentProgramsFull({
        year: yearFilter.value,
        name: nameFilter.value.trim() || null
      });
      const prefer = preferKey ?? selectedIpgKey.value;
      if (prefer != null && programs.value.some((p) => p.ipgKey === prefer)) {
        selectedIpgKey.value = prefer;
      } else if (programs.value.length > 0) {
        selectedIpgKey.value = programs.value[0].ipgKey;
      } else {
        selectedIpgKey.value = null;
        points.value = [];
        structureByPn.value = {};
        selectedIpgpKey.value = null;
        selectedTreeKey.value = null;
      }
      if (selectedIpgKey.value != null) {
        await fetchPoints(selectedIpgKey.value);
        await fetchLoads(selectedIpgKey.value);
      } else {
        loads.value = [];
        selectedLoadKey.value = null;
        applyResult.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      console.error('[ipg-leaves] fetchPrograms failed', err);
    } finally {
      loadingPrograms.value = false;
    }
  }

  /**
   * Загружает пункты выбранной ИП (без UtPl).
   */
  async function fetchPoints(ipgKey: number): Promise<void> {
    loadingPoints.value = true;
    error.value = null;
    try {
      points.value = await getInvestmentProgramPoints(ipgKey);
      structureByPn.value = {};
      if (
        selectedIpgpKey.value != null &&
        !points.value.some((p) => p.ipgpKey === selectedIpgpKey.value)
      ) {
        selectedIpgpKey.value = null;
        selectedTreeKey.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      points.value = [];
      console.error('[ipg-leaves] fetchPoints failed', err);
    } finally {
      loadingPoints.value = false;
    }
  }

  /**
   * Выбрать ИП и загрузить пункты + сессии load.
   */
  async function selectProgram(ipgKey: number): Promise<void> {
    selectedIpgKey.value = ipgKey;
    selectedIpgpKey.value = null;
    selectedTreeKey.value = null;
    applyResult.value = null;
    await fetchPoints(ipgKey);
    await fetchLoads(ipgKey);
  }

  /**
   * Сессии load выбранной ИП (parse — на Structure; apply — здесь).
   */
  async function fetchLoads(ipgKey: number): Promise<void> {
    loadingLoads.value = true;
    try {
      loads.value = await getImpIpgLoads(ipgKey);
      if (loads.value.length > 0) {
        const keep = selectedLoadKey.value;
        selectedLoadKey.value =
          keep != null && loads.value.some((l) => l.id === keep)
            ? keep
            : loads.value[0].id;
      } else {
        selectedLoadKey.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      loads.value = [];
      selectedLoadKey.value = null;
      console.error('[ipg-leaves] fetchLoads failed', err);
    } finally {
      loadingLoads.value = false;
    }
  }

  /**
   * Выбор сессии load для apply.
   */
  function selectLoad(loadKey: number | null): void {
    selectedLoadKey.value = loadKey;
    applyResult.value = null;
  }

  /**
   * Apply пунктов из staging (§3.2.8.3): Проверить=dryRun / Загрузить=commit.
   *
   * @param dryRun true — превью без записи
   */
  async function applySelectedPoints(dryRun: boolean): Promise<ImpIpgPointsApplyResultDto> {
    const loadKey = selectedLoadKey.value;
    if (loadKey == null) {
      throw new Error('Выберите сессию загрузки');
    }
    applyingPoints.value = true;
    error.value = null;
    try {
      const result = await applyImpIpgPoints(
        loadKey,
        previousIpgKeyForApply.value,
        dryRun
      );
      applyResult.value = result;
      if (!dryRun && result.logHtml != null) {
        // commit сохранил лог в сессии — синхронизируем кэш сессий
        loads.value = loads.value.map((item) =>
          item.id === loadKey ? { ...item, logHtml: result.logHtml } : item
        );
      }
      console.info('[ipg-leaves] applyPoints', result);
      if (!dryRun && result.appliedCount > 0 && selectedIpgKey.value != null) {
        await fetchPoints(selectedIpgKey.value);
      }
      return result;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      applyingPoints.value = false;
    }
  }

  /**
   * Подгрузить привязки Structure для пункта (lazy).
   */
  async function ensureStructure(ipgpKey: number): Promise<void> {
    if (structureByPn.value[ipgpKey]) {
      return;
    }
    loadingStructure.value = true;
    try {
      const rows = await getIpgPnStructure(ipgpKey);
      structureByPn.value = { ...structureByPn.value, [ipgpKey]: rows };
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      loadingStructure.value = false;
    }
  }

  function selectTreeNode(key: string | null): void {
    selectedTreeKey.value = key;
    if (key == null) {
      selectedIpgpKey.value = null;
      return;
    }
    const pnMatch = /^pn:(\d+)$/.exec(key);
    const folderMatch = /^folder:(\d+):/.exec(key);
    const stMatch = /^st:(\d+)$/.exec(key);
    const stubMatch = /^(?:stub-\w+-)?(\d+)$/.exec(key);
    if (pnMatch) {
      selectedIpgpKey.value = Number(pnMatch[1]);
      void ensureStructure(selectedIpgpKey.value);
      return;
    }
    if (folderMatch) {
      selectedIpgpKey.value = Number(folderMatch[1]);
      void ensureStructure(selectedIpgpKey.value);
      return;
    }
    if (stMatch) {
      const bind = Object.values(structureByPn.value)
        .flat()
        .find((b) => b.ipgspKey === Number(stMatch[1]));
      selectedIpgpKey.value = bind?.ipgspPn ?? selectedIpgpKey.value;
      return;
    }
    if (stubMatch && key.includes('-')) {
      const parts = key.split('-');
      const last = parts[parts.length - 1];
      if (/^\d+$/.test(last)) {
        selectedIpgpKey.value = Number(last);
      }
    }
  }

  async function loadSchemes(): Promise<void> {
    try {
      schemes.value = await getIpgSchemes();
    } catch (err) {
      console.warn('[ipg-leaves] loadSchemes', err);
    }
  }

  async function createProgram(input: CreateIpgInput): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createInvestmentProgram(input);
      await fetchPrograms(created.ipgKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function saveProgram(id: number, input: UpdateIpgInput): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await updateInvestmentProgram(id, input);
      await fetchPrograms(id);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function createPoint(input: CreateIpgPnInput): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createIpgPn(input);
      await fetchPoints(input.ipgpIpg);
      selectedIpgpKey.value = created.ipgpKey;
      selectedTreeKey.value = `pn:${created.ipgpKey}`;
      await ensureStructure(created.ipgpKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function savePoint(id: number, input: UpdateIpgPnInput): Promise<void> {
    const ipgKey = selectedIpgKey.value;
    if (ipgKey == null) {
      throw new Error('ИП не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      await updateIpgPn(id, input);
      await fetchPoints(ipgKey);
      selectedIpgpKey.value = id;
      selectedTreeKey.value = `pn:${id}`;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function removePoint(id: number): Promise<void> {
    const ipgKey = selectedIpgKey.value;
    if (ipgKey == null) {
      throw new Error('ИП не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      await deleteIpgPn(id);
      selectedIpgpKey.value = null;
      selectedTreeKey.value = null;
      await fetchPoints(ipgKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function addStructureBind(ipgpKey: number, stiKey: number): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await addIpgPnStructure(ipgpKey, stiKey);
      const rows = await getIpgPnStructure(ipgpKey);
      structureByPn.value = { ...structureByPn.value, [ipgpKey]: rows };
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function removeStructureBind(ipgspKey: number, ipgpKey: number): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await removeIpgPnStructure(ipgspKey);
      const rows = await getIpgPnStructure(ipgpKey);
      structureByPn.value = { ...structureByPn.value, [ipgpKey]: rows };
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  return {
    programs,
    selectedIpgKey,
    selectedProgram,
    points,
    structureByPn,
    schemes,
    selectedTreeKey,
    selectedIpgpKey,
    selectedPoint,
    treeNodes,
    yearFilter,
    nameFilter,
    loadingPrograms,
    loadingPoints,
    loadingStructure,
    mutating,
    error,
    loads,
    selectedLoadKey,
    selectedLoad,
    loadLogHtml,
    previousIpgKeyForApply,
    applyResult,
    loadingLoads,
    applyingPoints,
    fetchPrograms,
    fetchPoints,
    selectProgram,
    fetchLoads,
    selectLoad,
    applySelectedPoints,
    ensureStructure,
    selectTreeNode,
    loadSchemes,
    createProgram,
    saveProgram,
    createPoint,
    savePoint,
    removePoint,
    addStructureBind,
    removeStructureBind
  };
});
