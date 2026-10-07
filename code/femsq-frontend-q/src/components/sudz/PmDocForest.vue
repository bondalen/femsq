<template>
  <div class="column no-wrap pm-doc-forest" data-test="sudz-pm-doc-forest">
    <div class="text-caption text-grey-7 q-mb-xs" data-test="sudz-pm-doc-forest-caption">
      {{ caption }}
    </div>
    <div v-if="loading" class="text-grey-6">Загрузка документов…</div>
    <div v-else-if="errorText" class="text-negative">{{ errorText }}</div>
    <FemsqWalkTree
      v-else-if="viewForest && viewForest.links.length"
      class="col"
      :spec="spec"
      :root-id="null"
      :roots-token="token"
      :fetch-node="fetchNode"
      :fetch-expand="fetchExpand"
      :fetch-query="fetchQuery"
      :fetch-roots="fetchRoots"
      data-test="sudz-pm-doc-forest-tree"
      root-class="sudz-pm-doc-forest-walk"
      @action="onAction"
    />
  </div>
</template>

<script setup lang="ts">
/**
 * Лес платёжных документов: корни по кодам строки очереди / выбранной белой строки / СФ.
 */
import { computed, ref, watch } from 'vue';
import { FemsqWalkTree, type FemsqWalkActionContext, type FemsqWalkFetchRow, type FemsqWalkTreeSpec } from 'fequlib';

import { getSudzPmDocForestByCius, getSudzPmDocForestByInv } from '@/api/sudz-api';
import {
  filterPmDocForestByDocCode,
  normalizePmDocCode,
  pmDocInvKeyFromNode,
  pmDocQueryRows,
  pmDocRootRows,
  pmDocRootsToken
} from '@/sudz/pm-doc-forest';
import type { SudzPmDocForest } from '@/types/sudz';
import * as specJson from '@/trees/pm-doc-forest.tree.json';

const props = defineProps<{
  ciusKey?: number | null;
  invKey?: number | null;
  /**
   * Фокус на одной белой строке кейса (pmt): фильтр леса по «№ докум.».
   * false — весь кейс очереди.
   */
  docFocus?: boolean;
  /** Код «№ докум.» выбранной белой строки; пусто/null при docFocus — «нет кода». */
  docCode?: string | null;
}>();

const emit = defineEmits<{
  openInv: [invKey: number];
}>();

const spec = specJson as FemsqWalkTreeSpec;
const forest = ref<SudzPmDocForest | null>(null);
const loading = ref(false);
const errorText = ref('');

/** Лес с учётом фокуса на одном коде документа. */
const viewForest = computed((): SudzPmDocForest | null => {
  const data = forest.value;
  if (!data) {
    return null;
  }
  if (!props.docFocus || props.invKey != null) {
    return data;
  }
  return filterPmDocForestByDocCode(data, props.docCode);
});

const token = computed(() => {
  const focus = props.docFocus ? normalizePmDocCode(props.docCode) ?? '' : '';
  return `${pmDocRootsToken(viewForest.value)}|focus:${focus}`;
});

const caption = computed(() => {
  if (loading.value) {
    return 'Платёжные документы…';
  }
  if (props.invKey != null) {
    const data = forest.value;
    if (!data) {
      return 'Платёжные документы';
    }
    return data.links.length
      ? `Платёжные документы этой СФ: ${data.matchedDocs}`
      : 'У этой счёт-фактуры нет платёжных документов в базе.';
  }
  if (props.docFocus) {
    const code = normalizePmDocCode(props.docCode);
    if (!code) {
      return 'В строке нет кода «№ докум.».';
    }
    const data = viewForest.value;
    if (!data || !data.links.length) {
      return `Документ ${code}: совпадающих платежей в базе нет.`;
    }
    return `Документ ${code}: с платежами в базе ${data.matchedDocs}.`;
  }
  const data = forest.value;
  if (!data) {
    return 'Платёжные документы';
  }
  if (data.fileCodes === 0) {
    return 'В строке нет кода «№ докум.».';
  }
  if (!data.links.length) {
    return `Кодов в файле ${data.fileCodes}. Совпадающих документов в базе нет.`;
  }
  return `Кодов в файле ${data.fileCodes}, с платежами в базе ${data.matchedDocs}.`;
});

watch(
  () => [props.ciusKey, props.invKey] as const,
  () => {
    void load();
  },
  { immediate: true }
);

/**
 * Грузит лес по тому входу, который задан.
 */
async function load(): Promise<void> {
  errorText.value = '';
  if (props.ciusKey == null && props.invKey == null) {
    forest.value = null;
    return;
  }
  loading.value = true;
  try {
    forest.value = props.ciusKey != null
      ? await getSudzPmDocForestByCius(props.ciusKey)
      : await getSudzPmDocForestByInv(props.invKey as number);
  } catch (error) {
    forest.value = null;
    errorText.value = error instanceof Error ? error.message : 'Не удалось прочитать документы';
  } finally {
    loading.value = false;
  }
}

/** Корни леса. */
async function fetchRoots(): Promise<FemsqWalkFetchRow[]> {
  return viewForest.value ? pmDocRootRows(viewForest.value) : [];
}

/** Узел по ключу обходчику не нужен: лес строится запросами. */
async function fetchNode(): Promise<null> {
  return null;
}

/** Рёбра каталога не используются. */
async function fetchExpand(): Promise<FemsqWalkFetchRow[]> {
  return [];
}

/**
 * Платежи документа или привязка платежа.
 */
async function fetchQuery(queryId: string, fromId: number): Promise<FemsqWalkFetchRow[]> {
  if (!viewForest.value) {
    return [];
  }
  return pmDocQueryRows(queryId, fromId, viewForest.value, viewForest.value.currentUplKey);
}

/**
 * Кнопка «Открыть дерево СФ» сообщает ключ счёта-фактуры родителю.
 */
function onAction(context: FemsqWalkActionContext): void {
  if (context.actionId !== 'pm.doc.openInv' || !viewForest.value) {
    return;
  }
  const invKey = pmDocInvKeyFromNode(context.node.rowKey, viewForest.value);
  if (invKey != null) {
    emit('openInv', invKey);
  }
}
</script>

<style scoped>
.pm-doc-forest {
  min-height: 0;
  height: 100%;
  flex: 1 1 auto;
  overflow: auto;
}
</style>
