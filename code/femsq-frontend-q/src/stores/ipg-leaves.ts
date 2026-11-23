/**
 * Стор Leaves §2.5.2: ИП, дерево пунктов (корень ipgPn), Structure; Планы/Лимиты — stub.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

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

/** Вид узла FemsqTree Leaves. */
export type LeavesTreeKind =
  | 'pn'
  | 'folderStruct'
  | 'folderPlans'
  | 'folderLimits'
  | 'stBind'
  | 'stub';

/** Узел дерева пунктов. */
export interface LeavesTreeNode {
  key: string;
  kind: LeavesTreeKind;
  label: string;
  ipgpKey?: number;
  ipgspKey?: number;
  stiKey?: number;
  leaf?: boolean;
  children?: LeavesTreeNode[];
}

const STUB_LATER = 'Загрузка в этапе 1.3 (UtPl / stCost)';

/**
 * Собирает дерево: корень = ipgPn, папки Structure/Планы/Лимиты.
 */
export function buildLeavesTree(
  points: IpgPnDto[],
  structureByPn: Record<number, IpgStPnDto[]>,
  filter: string
): LeavesTreeNode[] {
  const q = filter.trim().toLowerCase();
  const filtered = q
    ? points.filter((pn) => {
        const hay = [
          String(pn.ipgpKey),
          String(pn.ipgpNum ?? ''),
          pn.cstAgPnCode ?? '',
          pn.ipgpTskCms ?? '',
          pn.ipgpShName ?? ''
        ]
          .join(' ')
          .toLowerCase();
        return hay.includes(q);
      })
    : points;

  return filtered.map((pn) => {
    const binds = structureByPn[pn.ipgpKey] ?? [];
    const structChildren: LeavesTreeNode[] =
      binds.length === 0
        ? [
            {
              key: `stub-struct-${pn.ipgpKey}`,
              kind: 'stub',
              label: 'Нет привязок — добавьте stiKey',
              ipgpKey: pn.ipgpKey,
              leaf: true
            }
          ]
        : binds.map((b) => ({
            key: `st:${b.ipgspKey}`,
            kind: 'stBind' as const,
            label: `${b.stName?.trim() || 'узел'} · stiKey=${b.ipgspSt}`,
            ipgpKey: pn.ipgpKey,
            ipgspKey: b.ipgspKey,
            stiKey: b.ipgspSt,
            leaf: true
          }));

    const code = pn.cstAgPnCode?.trim() || `cstAgPn=${pn.ipgpCstAgPn}`;
    const num = pn.ipgpNum != null ? `#${pn.ipgpNum}` : '';
    return {
      key: `pn:${pn.ipgpKey}`,
      kind: 'pn' as const,
      label: `${num} ${code}`.trim(),
      ipgpKey: pn.ipgpKey,
      leaf: false,
      children: [
        {
          key: `folder:${pn.ipgpKey}:struct`,
          kind: 'folderStruct' as const,
          label: 'Структура ИПГ',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: structChildren
        },
        {
          key: `folder:${pn.ipgpKey}:plans`,
          kind: 'folderPlans' as const,
          label: 'Планы',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: [
            {
              key: `stub-plans-${pn.ipgpKey}`,
              kind: 'stub' as const,
              label: STUB_LATER,
              ipgpKey: pn.ipgpKey,
              leaf: true
            }
          ]
        },
        {
          key: `folder:${pn.ipgpKey}:limits`,
          kind: 'folderLimits' as const,
          label: 'Лимиты',
          ipgpKey: pn.ipgpKey,
          leaf: false,
          children: [
            {
              key: `stub-limits-${pn.ipgpKey}`,
              kind: 'stub' as const,
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
  const pointFilter = ref('');
  const selectedTreeKey = ref<string | null>(null);
  const selectedIpgpKey = ref<number | null>(null);

  const yearFilter = ref<number | null>(null);
  const nameFilter = ref('');

  const loadingPrograms = ref(false);
  const loadingPoints = ref(false);
  const loadingStructure = ref(false);
  const mutating = ref(false);
  const error = ref<string | null>(null);

  const selectedProgram = computed(
    () => programs.value.find((p) => p.ipgKey === selectedIpgKey.value) ?? null
  );

  const selectedPoint = computed(
    () => points.value.find((p) => p.ipgpKey === selectedIpgpKey.value) ?? null
  );

  const treeNodes = computed(() =>
    buildLeavesTree(points.value, structureByPn.value, pointFilter.value)
  );

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
   * Выбрать ИП и загрузить пункты.
   */
  async function selectProgram(ipgKey: number): Promise<void> {
    selectedIpgKey.value = ipgKey;
    selectedIpgpKey.value = null;
    selectedTreeKey.value = null;
    await fetchPoints(ipgKey);
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
    pointFilter,
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
    fetchPrograms,
    fetchPoints,
    selectProgram,
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
