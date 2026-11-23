/**
 * Стор экрана Structure ИПГ (C2 §2.5.1): схемы, дерево fnSt, CRUD.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

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

  const selectedNetwork = computed(() =>
    networks.value.find((item) => item.stNetKey === selectedNetworkKey.value) ?? null
  );

  const treeNodes = computed(() => buildStructureTree(flatTree.value));

  const selectedFlatNode = computed(() =>
    flatTree.value.find((item) => item.childKey === selectedNodeKey.value) ?? null
  );

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
    deleteSelectedNode
  };
});
