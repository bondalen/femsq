/**
 * Стор экрана Structure ИПГ (C2 §2.5.1): схемы, дерево fnSt, CRUD.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createImpIpgLoad,
  getImpIpgLoads,
  mapImpIpgRowSti,
  parseImpIpgLoad,
  reconcileImpIpgStructure,
  type ImpIpgLoadDto,
  type ImpIpgReconcileResultDto,
  type ImpIpgReconcileRowDto
} from '@/api/imp-ipg-load-api';
import { getInvestmentProgramsLookup, type InvestmentProgramLookupDto } from '@/api/lookups-api';
import {
  addStIpgNodeName,
  attachStIpgEdge,
  cloneStIpgNetwork,
  createStIpgChildNode,
  createStIpgNetwork,
  deleteStIpgNode,
  detachStIpgEdge,
  getStIpgNetworkTree,
  getStIpgNetworks,
  getStIpgNodeNames,
  moveStIpgEdge,
  renameStIpgNetwork,
  renameStIpgNode,
  type StIpgNetworkDto,
  type StIpgNmDto,
  type StIpgTreeNodeDto
} from '@/api/st-ipg-structure-api';

/** Узел FemsqTree / FemsqTreeList, собранный из плоского fnSt. */
export interface StIpgStructureTreeNode {
  key: number;
  label: string;
  stNum: string | null;
  parentKey: number | null;
  stpnNum: number | null;
  pnLevel: number | null;
  stRelKey: number | null;
  stNetPnKey: number | null;
  leaf?: boolean;
  children?: StIpgStructureTreeNode[];
}

/**
 * Строит вложенное дерево из плоских строк fnSt.
 *
 * @param flat строки обхода
 */
export function buildStructureTree(flat: StIpgTreeNodeDto[]): StIpgStructureTreeNode[] {
  const byKey = new Map<number, StIpgStructureTreeNode>();
  for (const row of flat) {
    byKey.set(row.childKey, {
      key: row.childKey,
      label: row.name?.trim() || `узел ${row.childKey}`,
      stNum: row.stNum,
      parentKey: row.parentKey,
      stpnNum: row.stpnNum,
      pnLevel: row.pnLevel,
      stRelKey: row.stRelKey,
      stNetPnKey: row.stNetPnKey,
      children: []
    });
  }
  const roots: StIpgStructureTreeNode[] = [];
  for (const row of flat) {
    const node = byKey.get(row.childKey);
    if (!node) {
      continue;
    }
    if (row.parentKey == null || !byKey.has(row.parentKey)) {
      roots.push(node);
      continue;
    }
    const parent = byKey.get(row.parentKey);
    parent?.children?.push(node);
  }
  const markLeaves = (nodes: StIpgStructureTreeNode[]): void => {
    for (const node of nodes) {
      const kids = node.children ?? [];
      if (kids.length === 0) {
        node.leaf = true;
        delete node.children;
      } else {
        node.leaf = false;
        markLeaves(kids);
      }
    }
  };
  markLeaves(roots);
  return roots;
}

export const useStIpgStructureStore = defineStore('stIpgStructure', () => {
  const networks = ref<StIpgNetworkDto[]>([]);
  const selectedNetworkKey = ref<number | null>(null);
  const flatTree = ref<StIpgTreeNodeDto[]>([]);
  const selectedNodeKey = ref<number | null>(null);
  const selectedNodeNames = ref<StIpgNmDto[]>([]);
  const loadingNetworks = ref(false);
  const loadingTree = ref(false);
  const loadingNames = ref(false);
  const mutating = ref(false);
  const error = ref<string | null>(null);

  /** Сверка Excel / ПТСФ (§3.1.6.3). */
  const ipgOptions = ref<InvestmentProgramLookupDto[]>([]);
  const selectedIpgKey = ref<number | null>(null);
  const loads = ref<ImpIpgLoadDto[]>([]);
  const selectedLoadKey = ref<number | null>(null);
  const excelFilePath = ref('');
  const reconcileResult = ref<ImpIpgReconcileResultDto | null>(null);
  const loadingLoads = ref(false);
  const reconciling = ref(false);

  const selectedNetwork = computed(() =>
    networks.value.find((item) => item.stNetKey === selectedNetworkKey.value) ?? null
  );

  const treeNodes = computed(() => buildStructureTree(flatTree.value));

  const selectedFlatNode = computed(() =>
    flatTree.value.find((item) => item.childKey === selectedNodeKey.value) ?? null
  );

  const selectedLoad = computed(
    () => loads.value.find((item) => item.id === selectedLoadKey.value) ?? null
  );

  /** Открытые строки ПТСФ для вкладки «не сопоставлено». */
  const unmatchedRows = computed(() =>
    (reconcileResult.value?.rows ?? []).filter((row) => !row.closed)
  );

  /** stiKey закрытых строк — для «+» на узлах дерева. */
  const closedStiKeys = computed(() => {
    const keys = new Set<number>();
    for (const row of reconcileResult.value?.rows ?? []) {
      if (row.closed && row.stiKey != null) {
        keys.add(row.stiKey);
      }
    }
    return keys;
  });

  /**
   * Загружает список схем; при необходимости выбирает первую.
   */
  async function fetchNetworks(preferKey?: number | null): Promise<void> {
    loadingNetworks.value = true;
    error.value = null;
    try {
      console.info('[st-ipg-structure] fetchNetworks');
      networks.value = await getStIpgNetworks();
      const prefer = preferKey ?? selectedNetworkKey.value;
      if (prefer != null && networks.value.some((item) => item.stNetKey === prefer)) {
        selectedNetworkKey.value = prefer;
      } else if (networks.value.length > 0) {
        selectedNetworkKey.value = networks.value[0].stNetKey;
      } else {
        selectedNetworkKey.value = null;
        flatTree.value = [];
        selectedNodeKey.value = null;
      }
      if (selectedNetworkKey.value != null) {
        await fetchTree(selectedNetworkKey.value);
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      console.error('[st-ipg-structure] fetchNetworks failed', err);
    } finally {
      loadingNetworks.value = false;
    }
  }

  /**
   * Загружает дерево выбранной схемы.
   */
  async function fetchTree(stNetKey: number): Promise<void> {
    loadingTree.value = true;
    error.value = null;
    try {
      console.info('[st-ipg-structure] fetchTree', stNetKey);
      flatTree.value = await getStIpgNetworkTree(stNetKey);
      if (
        selectedNodeKey.value != null &&
        !flatTree.value.some((item) => item.childKey === selectedNodeKey.value)
      ) {
        selectedNodeKey.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      console.error('[st-ipg-structure] fetchTree failed', err);
      flatTree.value = [];
    } finally {
      loadingTree.value = false;
    }
  }

  /**
   * Выбрать схему и загрузить дерево.
   */
  async function selectNetwork(stNetKey: number): Promise<void> {
    selectedNetworkKey.value = stNetKey;
    selectedNodeKey.value = null;
    await fetchTree(stNetKey);
  }

  function selectNode(key: number | null): void {
    selectedNodeKey.value = key;
    selectedNodeNames.value = [];
    if (key != null) {
      void fetchNodeNames(key);
    }
  }

  /**
   * Загружает aliases выбранного узла.
   */
  async function fetchNodeNames(stiKey: number): Promise<void> {
    loadingNames.value = true;
    try {
      selectedNodeNames.value = await getStIpgNodeNames(stiKey);
    } catch (err) {
      console.error('[st-ipg-structure] fetchNodeNames failed', err);
      selectedNodeNames.value = [];
    } finally {
      loadingNames.value = false;
    }
  }

  async function createNetwork(name: string, rootKey: number): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createStIpgNetwork(name, rootKey);
      await fetchNetworks(created.stNetKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function renameNetwork(id: number, name: string): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await renameStIpgNetwork(id, name);
      await fetchNetworks(id);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function cloneNetwork(sourceId: number, newName: string): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      const cloned = await cloneStIpgNetwork(sourceId, newName);
      await fetchNetworks(cloned.stNetKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function createChild(parentKey: number, name: string): Promise<void> {
    const netKey = selectedNetworkKey.value;
    if (netKey == null) {
      throw new Error('Схема не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      const created = await createStIpgChildNode({ stNetKey: netKey, parentKey, name });
      await fetchTree(netKey);
      selectedNodeKey.value = created.childKey;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function renameNode(stiKey: number, name: string): Promise<void> {
    const netKey = selectedNetworkKey.value;
    if (netKey == null) {
      throw new Error('Схема не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      await renameStIpgNode(stiKey, name);
      await fetchTree(netKey);
      selectedNodeKey.value = stiKey;
      await fetchNodeNames(stiKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function addNodeName(stiKey: number, name: string): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await addStIpgNodeName(stiKey, name);
      await fetchNodeNames(stiKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function attachExistingChild(parentKey: number, childKey: number): Promise<void> {
    const netKey = selectedNetworkKey.value;
    if (netKey == null) {
      throw new Error('Схема не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      await attachStIpgEdge({ stNetKey: netKey, parentKey, childKey });
      await fetchTree(netKey);
      selectedNodeKey.value = childKey;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function moveSelectedToParent(toParentKey: number): Promise<void> {
    const netKey = selectedNetworkKey.value;
    const node = selectedFlatNode.value;
    if (netKey == null || node == null || node.parentKey == null) {
      throw new Error('Нужен выбранный дочерний узел с родителем');
    }
    mutating.value = true;
    error.value = null;
    try {
      await moveStIpgEdge({
        stNetKey: netKey,
        childKey: node.childKey,
        fromParentKey: node.parentKey,
        toParentKey
      });
      await fetchTree(netKey);
      selectedNodeKey.value = node.childKey;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function detachSelectedEdge(): Promise<void> {
    const netKey = selectedNetworkKey.value;
    const node = selectedFlatNode.value;
    if (netKey == null || node == null || node.parentKey == null) {
      throw new Error('Нужен выбранный дочерний узел с родителем');
    }
    mutating.value = true;
    error.value = null;
    try {
      await detachStIpgEdge(netKey, node.parentKey, node.childKey);
      selectedNodeKey.value = null;
      await fetchTree(netKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function deleteSelectedNode(): Promise<void> {
    const netKey = selectedNetworkKey.value;
    const node = selectedFlatNode.value;
    if (netKey == null || node == null) {
      throw new Error('Узел не выбран');
    }
    mutating.value = true;
    error.value = null;
    try {
      await deleteStIpgNode(netKey, node.childKey);
      selectedNodeKey.value = null;
      await fetchTree(netKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function fetchIpgOptions(): Promise<void> {
    try {
      ipgOptions.value = await getInvestmentProgramsLookup();
    } catch (err) {
      console.error('[st-ipg-structure] fetchIpgOptions failed', err);
      ipgOptions.value = [];
    }
  }

  async function selectIpg(ipgKey: number | null): Promise<void> {
    selectedIpgKey.value = ipgKey;
    selectedLoadKey.value = null;
    loads.value = [];
    reconcileResult.value = null;
    if (ipgKey == null) {
      return;
    }
    loadingLoads.value = true;
    try {
      loads.value = await getImpIpgLoads(ipgKey);
      if (loads.value.length > 0) {
        selectedLoadKey.value = loads.value[0].id;
        excelFilePath.value = loads.value[0].filePath ?? '';
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      loadingLoads.value = false;
    }
  }

  function selectLoad(loadKey: number | null): void {
    selectedLoadKey.value = loadKey;
    reconcileResult.value = null;
    const load = loads.value.find((item) => item.id === loadKey);
    if (load?.filePath) {
      excelFilePath.value = load.filePath;
    }
  }

  /**
   * Создать сессию загрузки под выбранной ИП.
   */
  async function ensureLoad(name: string): Promise<ImpIpgLoadDto> {
    const ipgKey = selectedIpgKey.value;
    if (ipgKey == null) {
      throw new Error('Выберите ИП');
    }
    mutating.value = true;
    try {
      const created = await createImpIpgLoad({
        ipgKey,
        name,
        filePath: excelFilePath.value || null,
        note: null
      });
      loads.value = await getImpIpgLoads(ipgKey);
      selectedLoadKey.value = created.id;
      return created;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Разобрать Excel в staging выбранной сессии.
   */
  async function parseSelectedLoad(): Promise<void> {
    let loadKey = selectedLoadKey.value;
    if (loadKey == null) {
      const created = await ensureLoad(`Загрузка ${new Date().toISOString().slice(0, 16)}`);
      loadKey = created.id;
    }
    mutating.value = true;
    reconciling.value = true;
    error.value = null;
    try {
      const parsed = await parseImpIpgLoad(loadKey, excelFilePath.value || null);
      console.info('[st-ipg-structure] parse', parsed);
      if (selectedIpgKey.value != null) {
        loads.value = await getImpIpgLoads(selectedIpgKey.value);
      }
      reconcileResult.value = null;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
      reconciling.value = false;
    }
  }

  /**
   * Сверить ПТСФ с текущей схемой CardStrip.
   */
  async function reconcileSelected(): Promise<ImpIpgReconcileResultDto> {
    const loadKey = selectedLoadKey.value;
    const stNetKey = selectedNetworkKey.value;
    if (loadKey == null) {
      throw new Error('Выберите сессию загрузки');
    }
    if (stNetKey == null) {
      throw new Error('Выберите схему');
    }
    reconciling.value = true;
    error.value = null;
    try {
      const result = await reconcileImpIpgStructure(loadKey, stNetKey, true);
      reconcileResult.value = result;
      return result;
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      reconciling.value = false;
    }
  }

  /**
   * Ручной map строки ПТСФ → stiKey, затем повторная сверка.
   */
  async function mapUnmatchedRow(rowId: number, stiKey: number): Promise<void> {
    mutating.value = true;
    try {
      await mapImpIpgRowSti(rowId, stiKey, false);
      await reconcileSelected();
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  /**
   * Добавить сырое имя Excel как alias к stiKey строки и пересверить.
   */
  async function addAliasFromRow(row: ImpIpgReconcileRowDto): Promise<void> {
    if (row.stiKey == null || !row.text?.trim()) {
      throw new Error('Нужны stiKey и текст строки');
    }
    mutating.value = true;
    try {
      await addStIpgNodeName(row.stiKey, row.text.trim());
      await reconcileSelected();
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  return {
    networks,
    selectedNetworkKey,
    selectedNetwork,
    flatTree,
    treeNodes,
    selectedNodeKey,
    selectedFlatNode,
    selectedNodeNames,
    loadingNetworks,
    loadingTree,
    loadingNames,
    mutating,
    error,
    fetchNetworks,
    fetchTree,
    fetchNodeNames,
    selectNetwork,
    selectNode,
    createNetwork,
    renameNetwork,
    cloneNetwork,
    createChild,
    renameNode,
    addNodeName,
    attachExistingChild,
    moveSelectedToParent,
    detachSelectedEdge,
    deleteSelectedNode,
    ipgOptions,
    selectedIpgKey,
    loads,
    selectedLoadKey,
    selectedLoad,
    excelFilePath,
    reconcileResult,
    unmatchedRows,
    closedStiKeys,
    loadingLoads,
    reconciling,
    fetchIpgOptions,
    selectIpg,
    selectLoad,
    ensureLoad,
    parseSelectedLoad,
    reconcileSelected,
    mapUnmatchedRow,
    addAliasFromRow
  };
});
