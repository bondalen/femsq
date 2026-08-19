<template>
  <div v-if="rootId == null" class="text-grey-6">Нет ключа корня.</div>
  <div v-else-if="error" class="text-negative">{{ error }}</div>
  <FemsqTree
    v-else
    class="col"
    :nodes="nodes"
    node-key="id"
    :lazy="true"
    :expand-on-click="false"
    v-model:expanded-keys="expandedKeys"
    v-model:selected-key="selectedKey"
    v-model:loading-keys="loadingKeys"
    :data-test="dataTest"
    :root-class="rootClass"
    @load="onLoad"
  >
    <template #header="{ node }">
      <div class="row items-center no-wrap full-width q-gutter-xs">
        <span class="relation-tree-title col">{{ node.title }}</span>
        <QBtn
          v-for="action in node.actions ?? []"
          :key="action.id"
          flat
          dense
          no-caps
          size="sm"
          color="primary"
          :icon="action.icon"
          :label="action.label"
          @click.stop="onActionClick(node, action)"
        />
      </div>
    </template>
    <template #detail="{ node }">
      <QMarkupTable v-if="node.fields?.length" dense flat bordered>
        <tbody>
          <tr v-for="field in node.fields" :key="field.label">
            <td class="text-grey-6" style="width: 40%">{{ field.label }}</td>
            <td>{{ field.value }}</td>
          </tr>
        </tbody>
      </QMarkupTable>
    </template>
    <template #empty>пока нет дочерних узлов</template>
  </FemsqTree>
</template>

<script setup lang="ts">
/**
 * Обёртка FemsqTree: JSON экземпляра + колбэки fetch хоста. Без Excel/очереди.
 */
import { ref, watch } from 'vue';

import { FemsqTree, type FemsqTreeKey, type FemsqTreeLoadPayload } from 'fequlib';
import { QBtn, QMarkupTable } from 'quasar';

import {
  buildRecordNode,
  childrenAfterFolderLoad,
  childrenAfterRecordLoad,
  createActionContext,
  fieldMapOf,
  patchRelationChildren,
  relationRootToken,
  type RelationTreeActionContext,
  type RelationTreeActionSpec,
  type RelationFetchExpand,
  type RelationFetchNode,
  type RelationTreeNode,
  type RelationTreeSpec
} from '@/trees/relation-tree';

const props = withDefaults(
  defineProps<{
    spec: RelationTreeSpec;
    rootId: number | null;
    fetchNode: RelationFetchNode;
    fetchExpand: RelationFetchExpand;
    dataTest?: string;
    rootClass?: string;
  }>(),
  {
    dataTest: 'relation-tree',
    rootClass: 'relation-tree'
  }
);

const emit = defineEmits<{
  action: [context: RelationTreeActionContext];
}>();

const nodes = ref<RelationTreeNode[]>([]);
const expandedKeys = ref<FemsqTreeKey[]>([]);
const selectedKey = ref<FemsqTreeKey | null>(null);
const loadingKeys = ref<FemsqTreeKey[]>([]);
const error = ref<string | null>(null);
const token = ref('');

watch(
  () => relationRootToken(props.spec.root.table, props.rootId),
  async (next) => {
    token.value = next;
    expandedKeys.value = [];
    selectedKey.value = null;
    loadingKeys.value = [];
    error.value = null;
    const id = props.rootId;
    if (!next || id == null) {
      nodes.value = [];
      return;
    }
    try {
      const row = await props.fetchNode(props.spec.root.table, id);
      if (!row) {
        nodes.value = [];
        return;
      }
      const root = buildRecordNode(props.spec.root.table, row.key, fieldMapOf(row.fields), {
        title: props.spec.title,
        detail: props.spec.detail,
        children: props.spec.children
      });
      nodes.value = [root];
      selectedKey.value = root.id;
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
      nodes.value = [];
    }
  },
  { immediate: true }
);

/**
 * Lazy @load: запись тянет N:1 рёбра и ставит папки 1:N; папка тянет строки.
 *
 * @param payload узел FemsqTree
 */
async function onLoad(payload: FemsqTreeLoadPayload<RelationTreeNode>): Promise<void> {
  const node = payload.node;
  const key = String(payload.key);
  loadingKeys.value = [...loadingKeys.value, key];
  try {
    let children: RelationTreeNode[] = [];
    if (node.kind === 'folder' && node.fromId != null && node.edge) {
      const rows = await props.fetchExpand(node.edge, node.fromId);
      children = childrenAfterFolderLoad(
        node,
        rows.map((row) => ({ key: row.key, fields: fieldMapOf(row.fields) }))
      );
    } else if (node.kind === 'record' && node.rowKey != null) {
      const loaded: Record<string, Array<{ key: number; fields: Record<string, string | null> }>> = {};
      for (const spec of node.childSpecs ?? []) {
        if (spec.card === '1:N') {
          continue;
        }
        const rows = await props.fetchExpand(spec.edge, node.rowKey);
        loaded[spec.edge] = rows.map((row) => ({ key: row.key, fields: fieldMapOf(row.fields) }));
      }
      children = childrenAfterRecordLoad(node, loaded);
    }
    nodes.value = patchRelationChildren(nodes.value, node.id, children);
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    loadingKeys.value = loadingKeys.value.filter((item) => item !== key);
  }
}

/**
 * Делегирует action хосту, не зная экранов и GraphQL.
 *
 * @param node узел дерева
 * @param action описание действия
 */
function onActionClick(node: RelationTreeNode, action: RelationTreeActionSpec): void {
  emit('action', createActionContext(props.spec.root.table, props.rootId, node, action));
}
</script>

<style scoped>
.relation-tree-title {
  font-size: var(--femsq-content-body-size);
}
</style>
