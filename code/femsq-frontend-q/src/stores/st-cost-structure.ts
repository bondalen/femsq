/**
 * Стор экрана Structure затрат (C2 O2 §4.0.2): схемы stnType=2, дерево fnSt, CRUD.
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  addStCostNodeName,
  attachStCostEdge,
  cloneStCostNetwork,
  createStCostChildNode,
  createStCostNetwork,
  deleteStCostNode,
  detachStCostEdge,
  getStCostNetworkTree,
  getStCostNetworks,
  getStCostNodeNames,
  moveStCostEdge,
  renameStCostNetwork,
  renameStCostNode,
  type StCostNetworkDto,
  type StCostNmDto,
  type StCostTreeNodeDto
} from '@/api/st-cost-structure-api';
import { evaluateCostCanon } from '@/domain/cost-structure-canon';
import { buildStructureTree, type StIpgStructureTreeNode } from '@/stores/st-ipg-structure';

/** Узел дерева затрат — тот же shape, что у Structure ИПГ. */
export type StCostStructureTreeNode = StIpgStructureTreeNode;

export const useStCostStructureStore = defineStore('stCostStructure', () => {
  const networks = ref<StCostNetworkDto[]>([]);
  const selectedNetworkKey = ref<number | null>(null);
  const flatTree = ref<StCostTreeNodeDto[]>([]);
  const selectedNodeKey = ref<number | null>(null);
  const selectedNodeNames = ref<StCostNmDto[]>([]);
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

  /** Статус канона 212/195/172/187 в текущем дереве. */
  const canon = computed(() => evaluateCostCanon(flatTree.value));

  /**
   * Загружает список схем; при необходимости выбирает первую (часто net=3).
   */
  async function fetchNetworks(preferKey?: number | null): Promise<void> {
    loadingNetworks.value = true;
    error.value = null;
    try {
      console.info('[st-cost-structure] fetchNetworks');
      networks.value = await getStCostNetworks();
      const prefer = preferKey ?? selectedNetworkKey.value;
      if (prefer != null && networks.value.some((item) => item.stNetKey === prefer)) {
        selectedNetworkKey.value = prefer;
      } else if (networks.value.length > 0) {
        const standard = networks.value.find((item) => item.stNetKey === 3);
        selectedNetworkKey.value = (standard ?? networks.value[0]).stNetKey;
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
      console.error('[st-cost-structure] fetchNetworks failed', err);
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
      console.info('[st-cost-structure] fetchTree', stNetKey);
      flatTree.value = await getStCostNetworkTree(stNetKey);
      if (
        selectedNodeKey.value != null &&
        !flatTree.value.some((item) => item.childKey === selectedNodeKey.value)
      ) {
        selectedNodeKey.value = null;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      console.error('[st-cost-structure] fetchTree failed', err);
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
  async function fetchNodeNames(stcKey: number): Promise<void> {
    loadingNames.value = true;
    try {
      selectedNodeNames.value = await getStCostNodeNames(stcKey);
    } catch (err) {
      console.error('[st-cost-structure] fetchNodeNames failed', err);
      selectedNodeNames.value = [];
    } finally {
      loadingNames.value = false;
    }
  }

  async function createNetwork(name: string, rootKey: number): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      const created = await createStCostNetwork(name, rootKey);
      console.info('[st-cost-structure] created network', created.stNetKey);
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
      await renameStCostNetwork(id, name);
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
      const cloned = await cloneStCostNetwork(sourceId, newName);
      console.info('[st-cost-structure] cloned network', sourceId, '→', cloned.stNetKey);
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
      const created = await createStCostChildNode({ stNetKey: netKey, parentKey, name });
      await fetchTree(netKey);
      selectedNodeKey.value = created.childKey;
      await fetchNodeNames(created.childKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function renameNode(stcKey: number, name: string): Promise<void> {
    const netKey = selectedNetworkKey.value;
    if (netKey == null) {
      throw new Error('Схема не выбрана');
    }
    mutating.value = true;
    error.value = null;
    try {
      await renameStCostNode(stcKey, name);
      await fetchTree(netKey);
      selectedNodeKey.value = stcKey;
      await fetchNodeNames(stcKey);
    } catch (err) {
      error.value = err instanceof Error ? err.message : String(err);
      throw err;
    } finally {
      mutating.value = false;
    }
  }

  async function addNodeName(stcKey: number, name: string): Promise<void> {
    mutating.value = true;
    error.value = null;
    try {
      await addStCostNodeName(stcKey, name);
      await fetchNodeNames(stcKey);
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
      await attachStCostEdge({ stNetKey: netKey, parentKey, childKey });
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
      await moveStCostEdge({
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
      await detachStCostEdge(netKey, node.parentKey, node.childKey);
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
      await deleteStCostNode(netKey, node.childKey);
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
    flatTree,
    selectedNodeKey,
    selectedNodeNames,
    loadingNetworks,
    loadingTree,
    loadingNames,
    mutating,
    error,
    selectedNetwork,
    treeNodes,
    selectedFlatNode,
    canon,
    fetchNetworks,
    fetchTree,
    selectNetwork,
    selectNode,
    fetchNodeNames,
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
