<template>
  <QPage class="investment-structure-view q-pa-none" data-test="investment-structure-view">
    <div class="absolute-full q-px-md q-pt-sm q-pb-sm column no-wrap investment-structure-inner">
      <div class="row items-center q-gutter-sm q-mb-xs shrink-0 no-wrap">
        <div class="text-subtitle1 text-weight-medium ellipsis">Структура ИПГ</div>
        <QSpace />
        <QBtn
          flat
          dense
          no-caps
          label="Переименовать"
          :disable="!store.selectedNetwork || store.mutating"
          data-test="investment-structure-rename-net"
          @click="openRenameNetwork"
        />
        <QBtn
          flat
          dense
          no-caps
          label="Клонировать"
          :disable="!store.selectedNetwork || store.mutating"
          data-test="investment-structure-clone-net"
          @click="openCloneNetwork"
        />
        <QBtn
          flat
          dense
          round
          icon="refresh"
          :loading="store.loadingNetworks || store.loadingTree"
          :disable="store.mutating"
          aria-label="Обновить"
          data-test="investment-structure-refresh"
          @click="onRefresh"
        />
      </div>

      <QBanner v-if="store.error" class="bg-negative text-white q-mb-xs shrink-0" rounded>
        {{ store.error }}
      </QBanner>

      <FemsqCardStrip
        class="q-mb-xs shrink-0"
        :items="store.networks"
        item-key="stNetKey"
        :selected-key="store.selectedNetworkKey"
        :loading="store.loadingNetworks"
        :disabled="store.mutating"
        dense
        test-id-prefix="investment-structure-net"
        data-test="investment-structure-networks"
        @update:selected-key="onSelectNetworkKey"
      >
        <template #item="{ item }">
          <div class="text-weight-medium">{{ item.name }}</div>
          <div class="text-caption investment-structure-net-meta">
            stNet={{ item.stNetKey }} · root={{ item.rootKey }}
          </div>
        </template>
        <template #empty>Схемы не найдены</template>
        <template #trailing>
          <QBtn
            flat
            dense
            no-caps
            icon="add"
            label="Создать"
            :disable="store.mutating"
            data-test="investment-structure-create-net"
            @click="openCreateNetwork"
          />
        </template>
      </FemsqCardStrip>

      <QSplitter
        v-model="mainSplit"
        horizontal
        :limits="[25, 80]"
        separator-class="investment-structure-split-sep"
        class="col investment-structure-splitter"
        data-test="investment-structure-splitter"
      >
        <template #before>
          <div class="column fill-pane no-wrap q-pr-xs">
            <div class="row items-center q-mb-sm q-gutter-xs shrink-0">
              <div class="text-subtitle1 q-mr-sm">Структура</div>
              <QSpace />
              <QBtn
                flat
                dense
                no-caps
                icon="add"
                label="Дочерний"
                :disable="!store.selectedNodeKey || store.mutating"
                data-test="investment-structure-add-child"
                @click="openCreateChild"
              />
              <QBtn
                flat
                dense
                no-caps
                label="Переименовать узел"
                :disable="!store.selectedNodeKey || store.mutating"
                data-test="investment-structure-rename-node"
                @click="openRenameNode"
              />
              <QBtn
                flat
                dense
                no-caps
                label="Добавить имя"
                :disable="!store.selectedNodeKey || store.mutating"
                data-test="investment-structure-add-name"
                @click="openAddName"
              />
              <QBtn
                flat
                dense
                no-caps
                label="Привязать sti"
                :disable="!store.selectedNodeKey || store.mutating"
                data-test="investment-structure-attach"
                @click="openAttach"
              />
              <QBtn
                flat
                dense
                no-caps
                label="Перенести к…"
                :disable="!canDetach || store.mutating"
                data-test="investment-structure-move"
                @click="openMove"
              />
              <QBtn
                flat
                dense
                no-caps
                color="warning"
                label="Отсоединить"
                :disable="!canDetach || store.mutating"
                data-test="investment-structure-detach"
                @click="onDetach"
              />
              <QBtn
                flat
                dense
                no-caps
                color="negative"
                label="Удалить узел"
                :disable="!store.selectedNodeKey || store.mutating"
                data-test="investment-structure-delete-node"
                @click="onDeleteNode"
              />
            </div>

            <div
              v-if="store.loadingTree"
              class="text-grey-7 q-pa-md investment-structure-tree col"
              data-test="investment-structure-tree-loading"
            >
              Загрузка дерева…
            </div>
            <FemsqTreeList
              v-else
              class="investment-structure-tree col"
              :nodes="store.treeNodes"
              node-key="key"
              children-key="children"
              leaf-key="leaf"
              :columns="treeColumns"
              expand-on-click
              fill
              v-model:selected-key="selectedKeyModel"
              data-test="investment-structure-tree"
            >
              <template #empty>Нет узлов в схеме</template>
              <template #actions="{ node }">
                <QBtn
                  v-if="store.closedStiKeys.has(Number(node.key))"
                  flat
                  dense
                  round
                  size="sm"
                  icon="add"
                  color="positive"
                  :title="'ПТСФ закрыт для sti=' + node.key"
                  data-test="investment-structure-tree-plus"
                />
              </template>
            </FemsqTreeList>

            <div v-if="store.selectedFlatNode" class="text-caption text-grey-7 q-mt-sm shrink-0">
              Выбран: stiKey={{ store.selectedFlatNode.childKey }}, parent={{
                store.selectedFlatNode.parentKey ?? '—'
              }}, stRel={{ store.selectedFlatNode.stRelKey ?? '—' }}
              <div v-if="store.loadingNames" class="q-mt-xs">Имена…</div>
              <div v-else-if="store.selectedNodeNames.length" class="q-mt-xs">
                Имена:
                <span
                  v-for="(nm, idx) in store.selectedNodeNames"
                  :key="nm.stinKey"
                >{{ idx ? '; ' : '' }}{{ nm.name }}</span>
              </div>
            </div>
          </div>
        </template>

        <template #after>
          <div class="column fill-pane no-wrap q-pt-sm">
            <div class="text-subtitle1 q-mb-sm shrink-0">Сверка Excel (ПТСФ)</div>
            <div class="row q-col-gutter-sm items-end q-mb-sm shrink-0">
              <div class="col-12 col-md-3">
                <QSelect
                  v-model="ipgModel"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="ИП (ipg)"
                  :options="ipgSelectOptions"
                  :loading="store.loadingLoads"
                  data-test="investment-structure-ipg"
                />
              </div>
              <div class="col-12 col-md-3">
                <QSelect
                  v-model="loadModel"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="Сессия load"
                  :options="loadSelectOptions"
                  :disable="store.selectedIpgKey == null"
                  data-test="investment-structure-load"
                />
              </div>
              <div class="col-12 col-md-3">
                <QInput
                  v-model="store.excelFilePath"
                  dense
                  outlined
                  label="Путь к Excel"
                  data-test="investment-structure-excel-path"
                />
              </div>
              <div class="col-12 col-md-4 row q-gutter-xs items-center">
                <QBtn
                  unelevated
                  color="primary"
                  no-caps
                  label="Разобрать"
                  :loading="store.reconciling"
                  :disable="!canParse || store.mutating"
                  data-test="investment-structure-parse"
                  @click="onParseExcel"
                />
                <QBtn
                  outline
                  color="primary"
                  no-caps
                  label="Сверить"
                  :loading="store.reconciling"
                  :disable="!canReconcile || store.mutating"
                  data-test="investment-structure-reconcile"
                  @click="onReconcile"
                />
              </div>
            </div>
            <div class="text-caption text-grey-7 q-mb-xs shrink-0">
              Apply пунктов — экран «Инвестпрограммы» → вкладка «Загрузка пунктов».
            </div>
            <div
              v-if="store.reconcileResult"
              class="text-caption text-grey-7 q-mb-sm shrink-0"
              data-test="investment-structure-reconcile-summary"
            >
              Закрыто {{ store.reconcileResult.matched }} · открыто {{ store.reconcileResult.open }}
              (load={{ store.reconcileResult.loadKey }}, stNet={{ store.reconcileResult.stNetKey }})
            </div>

            <QTabs
              v-model="bottomTab"
              dense
              class="text-primary shrink-0"
              data-test="investment-structure-bottom-tabs"
            >
              <QTab
                name="unmatched"
                :label="'не сопоставлено (' + store.unmatchedRows.length + ')'"
                data-test="investment-structure-tab-unmatched"
              />
              <QTab
                name="log"
                label="Ход загрузки"
                data-test="investment-structure-tab-log"
              />
            </QTabs>
            <QTabPanels v-model="bottomTab" animated class="bg-transparent col">
              <QTabPanel name="unmatched" class="q-pa-none column fill-pane no-wrap">
                <QTable
                  flat
                  dense
                  bordered
                  class="col investment-structure-unmatched-table"
                  row-key="rowId"
                  :rows="store.unmatchedRows"
                  :columns="unmatchedColumns"
                  :pagination="{ rowsPerPage: 0 }"
                  no-data-label="Нет открытых строк ПТСФ (или сверка ещё не запускалась)"
                  data-test="investment-structure-unmatched-table"
                >
                  <template #body-cell-actions="props">
                    <QTd :props="props">
                      <QBtn
                        v-if="
                          props.row.stiKey != null
                            && !props.row.nameInPool
                            && (props.row.status === 'NEEDS_ALIAS' || props.row.status === 'MANUAL')
                        "
                        flat
                        dense
                        no-caps
                        size="sm"
                        label="alias"
                        :disable="store.mutating"
                        data-test="investment-structure-unmatched-alias"
                        @click="onAddAlias(props.row)"
                      />
                      <QBtn
                        flat
                        dense
                        no-caps
                        size="sm"
                        label="map"
                        :disable="store.mutating"
                        data-test="investment-structure-unmatched-map"
                        @click="openMapRow(props.row)"
                      />
                    </QTd>
                  </template>
                </QTable>
              </QTabPanel>
              <QTabPanel name="log" class="q-pa-none column fill-pane no-wrap">
                <div class="col scroll investment-structure-load-log" data-test="investment-structure-load-log">
                  <div class="audit-log-surface">
                    <div
                      v-if="store.loadLogHtml"
                      class="audit-log-html"
                      v-html="store.loadLogHtml"
                    />
                    <div v-else class="audit-log-empty text-body2">
                      Журнал загрузки появится после «Разобрать» или «Сверить» для выбранной сессии.
                    </div>
                  </div>
                </div>
              </QTabPanel>
            </QTabPanels>
          </div>
        </template>
      </QSplitter>
    </div>

    <QDialog v-model="dialogOpen" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-h6">{{ dialogTitle }}</QCardSection>
        <QCardSection>
          <QInput
            v-if="dialogMode !== 'attach' && dialogMode !== 'move' && dialogMode !== 'map-row'"
            v-model="dialogName"
            dense
            autofocus
            :label="dialogNameLabel"
            data-test="investment-structure-dialog-name"
            @keyup.enter="submitDialog"
          />
          <QSelect
            v-if="dialogMode === 'create-net'"
            v-model="dialogRootKey"
            class="q-mt-md"
            dense
            outlined
            emit-value
            map-options
            use-input
            fill-input
            hide-selected
            input-debounce="0"
            label="Корень схемы (имя · id)"
            :options="filteredNodeOptions"
            data-test="investment-structure-dialog-root"
            @filter="filterNodeOptions"
          />
          <QSelect
            v-if="dialogMode === 'attach'"
            v-model="dialogChildKey"
            dense
            outlined
            autofocus
            emit-value
            map-options
            use-input
            fill-input
            hide-selected
            input-debounce="0"
            label="Существующий узел (имя · id)"
            :options="filteredNodeOptions"
            data-test="investment-structure-dialog-child"
            @filter="filterNodeOptions"
          />
          <QSelect
            v-if="dialogMode === 'move'"
            v-model="dialogToParentKey"
            dense
            outlined
            autofocus
            emit-value
            map-options
            use-input
            fill-input
            hide-selected
            input-debounce="0"
            label="Новый родитель (имя · id)"
            :options="filteredNodeOptions"
            data-test="investment-structure-dialog-to-parent"
            @filter="filterNodeOptions"
          />
          <QSelect
            v-if="dialogMode === 'map-row'"
            v-model="dialogChildKey"
            dense
            outlined
            autofocus
            emit-value
            map-options
            use-input
            fill-input
            hide-selected
            input-debounce="0"
            label="Узел структуры для строки ПТСФ (имя · id)"
            :options="filteredNodeOptions"
            data-test="investment-structure-dialog-map-sti"
            @filter="filterNodeOptions"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="store.mutating" />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="OK"
            :loading="store.mutating"
            data-test="investment-structure-dialog-ok"
            @click="submitDialog"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
/**
 * Экран Structure ИПГ: полоса схем (FemsqCardStrip) + колоночное дерево (FemsqTreeList).
 */
import { computed, onMounted, ref } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QPage,
  QSelect,
  QSpace,
  QSplitter,
  QTab,
  QTable,
  QTabPanel,
  QTabPanels,
  QTabs,
  QTd,
  useQuasar,
  type QTableColumn
} from 'quasar';
import {
  FemsqCardStrip,
  FemsqTreeList,
  type FemsqTreeKey,
  type FemsqTreeListColumn
} from 'fequlib';

import type { ImpIpgReconcileRowDto } from '@/api/imp-ipg-load-api';
import {
  useStIpgStructureStore,
  type StIpgStructureTreeNode
} from '@/stores/st-ipg-structure';

const store = useStIpgStructureStore();
const $q = useQuasar();
const bottomTab = ref('unmatched');
/** Доля верхней панели (дерево), % высоты сплиттера. */
const mainSplit = ref(58);

const treeColumns: FemsqTreeListColumn<StIpgStructureTreeNode>[] = [
  { name: 'label', label: 'Раздел', field: 'label' },
  { name: 'stNum', label: '№', field: 'stNum', width: '140px' },
  { name: 'sti', label: 'sti', field: 'key', width: '72px', align: 'right' },
  { name: 'parent', label: 'parent', field: 'parentKey', width: '72px', align: 'right' },
  { name: 'stpnN', label: 'stpnN', field: 'stpnNum', width: '64px', align: 'right' },
  { name: 'pnL', label: 'ур.', field: 'pnLevel', width: '56px', align: 'right' }
];

const dialogOpen = ref(false);
const dialogMode = ref<
  | 'create-net'
  | 'rename-net'
  | 'clone-net'
  | 'create-child'
  | 'rename-node'
  | 'add-name'
  | 'attach'
  | 'move'
  | 'map-row'
>('create-net');
const dialogName = ref('');
const dialogRootKey = ref(1);
const dialogChildKey = ref<number | null>(null);
const dialogToParentKey = ref<number | null>(null);
const mapRowId = ref<number | null>(null);
/** Кандидаты сверки — поднимаем в начало списка комбобокса map. */
const mapCandidateKeys = ref<number[]>([]);
const nodeOptionsFilter = ref('');

interface NodeSelectOption {
  label: string;
  value: number;
  name: string;
}

/**
 * Опции узлов текущей схемы: «Имя · id=N» (id для омонимов).
 * Для map-row кандидаты сверки идут первыми.
 */
const nodeSelectOptions = computed((): NodeSelectOption[] => {
  const byKey = new Map<number, NodeSelectOption>();
  for (const node of store.flatTree) {
    const name = (node.name ?? '').trim() || `sti ${node.childKey}`;
    byKey.set(node.childKey, {
      value: node.childKey,
      name,
      label: `${name} · id=${node.childKey}`
    });
  }
  if (byKey.size === 0) {
    byKey.set(1, { value: 1, name: 'Вся инвестпрограмма', label: 'Вся инвестпрограмма · id=1' });
  }
  const preferred: NodeSelectOption[] = [];
  for (const key of mapCandidateKeys.value) {
    const opt = byKey.get(key);
    if (opt) {
      preferred.push({ ...opt, label: `★ ${opt.label}` });
      byKey.delete(key);
    }
  }
  const rest = [...byKey.values()].sort((a, b) =>
    a.name.localeCompare(b.name, 'ru', { sensitivity: 'base' })
  );
  return preferred.length > 0 ? [...preferred, ...rest] : rest;
});

const filteredNodeOptions = ref<NodeSelectOption[]>([]);

function filterNodeOptions(val: string, update: (fn: () => void) => void): void {
  update(() => {
    const needle = val.trim().toLowerCase();
    nodeOptionsFilter.value = needle;
    if (!needle) {
      filteredNodeOptions.value = nodeSelectOptions.value;
      return;
    }
    filteredNodeOptions.value = nodeSelectOptions.value.filter((opt) => {
      const hay = `${opt.label} ${opt.value}`.toLowerCase();
      return hay.includes(needle);
    });
  });
}

const ipgSelectOptions = computed(() =>
  store.ipgOptions.map((item) => ({
    label: `${item.ipgKey}: ${item.name}`,
    value: item.ipgKey
  }))
);
const loadSelectOptions = computed(() =>
  store.loads.map((item) => ({
    label: `${item.id}: ${item.name}`,
    value: item.id
  }))
);
const ipgModel = computed({
  get: () => store.selectedIpgKey,
  set: (value: number | null) => {
    void store.selectIpg(value);
  }
});
const loadModel = computed({
  get: () => store.selectedLoadKey,
  set: (value: number | null) => {
    store.selectLoad(value);
  }
});
const canParse = computed(
  () => store.selectedIpgKey != null && store.excelFilePath.trim().length > 0
);
const canReconcile = computed(
  () => store.selectedLoadKey != null && store.selectedNetworkKey != null
);

const unmatchedColumns: QTableColumn[] = [
  { name: 'rowNo', label: 'стр.', field: 'rowNo', align: 'right', style: 'width: 56px' },
  { name: 'text', label: 'Раздел Excel', field: 'text', align: 'left' },
  { name: 'status', label: 'статус', field: 'status', align: 'left', style: 'width: 140px' },
  {
    name: 'stiKey',
    label: 'sti',
    field: 'stiKey',
    align: 'right',
    style: 'width: 72px',
    format: (v: number | null | undefined) => (v == null ? '—' : String(v))
  },
  {
    name: 'candidates',
    label: 'кандидаты',
    field: 'candidateStiKeys',
    align: 'left',
    style: 'width: 120px',
    format: (v: number[]) => (v?.length ? v.join(', ') : '—')
  },
  { name: 'actions', label: '', field: 'rowId', align: 'right', style: 'width: 140px' }
];

const selectedKeyModel = computed({
  get: () => store.selectedNodeKey,
  set: (value: FemsqTreeKey | null) => {
    if (value == null) {
      store.selectNode(null);
      return;
    }
    store.selectNode(Number(value));
  }
});

const canDetach = computed(
  () => store.selectedFlatNode != null && store.selectedFlatNode.parentKey != null
);

const dialogTitle = computed(() => {
  switch (dialogMode.value) {
    case 'create-net':
      return 'Новая схема ИПГ';
    case 'rename-net':
      return 'Переименовать схему';
    case 'clone-net':
      return 'Клонировать схему';
    case 'create-child':
      return 'Дочерний узел';
    case 'rename-node':
      return 'Переименовать узел';
    case 'add-name':
      return 'Добавить имя (alias)';
    case 'attach':
      return 'Привязать существующий узел';
    case 'move':
      return 'Перенести узел к другому родителю';
    case 'map-row':
      return 'Ручной map ПТСФ → узел структуры';
    default:
      return '';
  }
});

const dialogNameLabel = computed(() => {
  if (dialogMode.value === 'create-child' || dialogMode.value === 'rename-node') {
    return 'Наименование узла';
  }
  if (dialogMode.value === 'add-name') {
    return 'Дополнительное имя (для ловли из Excel)';
  }
  return 'Наименование схемы';
});

async function onRefresh(): Promise<void> {
  await store.fetchNetworks(store.selectedNetworkKey);
}

/**
 * Выбор схемы из полосы карточек.
 *
 * @param key stNetKey или null
 */
async function onSelectNetworkKey(key: FemsqTreeKey | null): Promise<void> {
  if (key == null) {
    return;
  }
  await store.selectNetwork(Number(key));
}

function openCreateNetwork(): void {
  dialogMode.value = 'create-net';
  dialogName.value = '';
  mapCandidateKeys.value = [];
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogRootKey.value = store.selectedNetwork?.rootKey ?? 1;
  dialogOpen.value = true;
}

function openRenameNetwork(): void {
  if (!store.selectedNetwork) {
    return;
  }
  dialogMode.value = 'rename-net';
  dialogName.value = store.selectedNetwork.name;
  dialogOpen.value = true;
}

function openCloneNetwork(): void {
  if (!store.selectedNetwork) {
    return;
  }
  dialogMode.value = 'clone-net';
  dialogName.value = `${store.selectedNetwork.name} (копия)`;
  dialogOpen.value = true;
}

function openCreateChild(): void {
  if (store.selectedNodeKey == null) {
    return;
  }
  dialogMode.value = 'create-child';
  dialogName.value = '';
  dialogOpen.value = true;
}

function openRenameNode(): void {
  if (!store.selectedFlatNode) {
    return;
  }
  dialogMode.value = 'rename-node';
  dialogName.value = store.selectedFlatNode.name ?? '';
  dialogOpen.value = true;
}

function openAddName(): void {
  if (store.selectedNodeKey == null) {
    return;
  }
  dialogMode.value = 'add-name';
  dialogName.value = '';
  dialogOpen.value = true;
}

function openAttach(): void {
  if (store.selectedNodeKey == null) {
    return;
  }
  dialogMode.value = 'attach';
  mapCandidateKeys.value = [];
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogChildKey.value = null;
  dialogOpen.value = true;
}

function openMove(): void {
  if (!canDetach.value) {
    return;
  }
  dialogMode.value = 'move';
  mapCandidateKeys.value = [];
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogToParentKey.value = null;
  dialogOpen.value = true;
}

function openMapRow(row: ImpIpgReconcileRowDto): void {
  dialogMode.value = 'map-row';
  mapRowId.value = row.rowId;
  mapCandidateKeys.value = [...(row.candidateStiKeys ?? [])];
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogChildKey.value = row.stiKey ?? row.candidateStiKeys[0] ?? store.selectedNodeKey;
  dialogOpen.value = true;
}

async function onParseExcel(): Promise<void> {
  const run = async () => {
    try {
      await store.parseSelectedLoad();
      $q.notify({ type: 'positive', message: 'Excel разобран в staging' });
    } catch (err) {
      $q.notify({
        type: 'negative',
        message: err instanceof Error ? err.message : String(err)
      });
    }
  };
  if (store.selectedLoadKey != null) {
    $q.dialog({
      title: 'Перезаписать staging?',
      message: 'Текущие строки impIpg сессии будут удалены и заменены разбором Excel.',
      cancel: true,
      persistent: true
    }).onOk(() => {
      void run();
    });
    return;
  }
  await run();
}

async function onReconcile(): Promise<void> {
  try {
    const result = await store.reconcileSelected();
    $q.notify({
      type: 'positive',
      message: `Сверка: закрыто ${result.matched}, открыто ${result.open}`
    });
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

async function onAddAlias(row: ImpIpgReconcileRowDto): Promise<void> {
  try {
    await store.addAliasFromRow(row);
    $q.notify({ type: 'positive', message: 'Имя добавлено в stIpgNm' });
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

async function submitDialog(): Promise<void> {
  try {
    if (dialogMode.value === 'map-row') {
      const sti = Number(dialogChildKey.value);
      if (!Number.isFinite(sti) || sti <= 0 || mapRowId.value == null) {
        $q.notify({ type: 'warning', message: 'Выберите узел структуры' });
        return;
      }
      await store.mapUnmatchedRow(mapRowId.value, sti);
      dialogOpen.value = false;
      $q.notify({ type: 'positive', message: 'Узел записан, сверка обновлена' });
      return;
    }
    if (dialogMode.value === 'attach') {
      const childKey = Number(dialogChildKey.value);
      if (!Number.isFinite(childKey) || childKey <= 0) {
        $q.notify({ type: 'warning', message: 'Выберите существующий узел' });
        return;
      }
      if (store.selectedNodeKey != null) {
        await store.attachExistingChild(store.selectedNodeKey, childKey);
      }
      dialogOpen.value = false;
      $q.notify({ type: 'positive', message: 'Узел привязан' });
      return;
    }
    if (dialogMode.value === 'move') {
      const toParent = Number(dialogToParentKey.value);
      if (!Number.isFinite(toParent) || toParent <= 0) {
        $q.notify({ type: 'warning', message: 'Выберите нового родителя' });
        return;
      }
      await store.moveSelectedToParent(toParent);
      dialogOpen.value = false;
      $q.notify({ type: 'positive', message: 'Узел перенесён' });
      return;
    }
    const name = dialogName.value.trim();
    if (!name) {
      $q.notify({ type: 'warning', message: 'Укажите наименование' });
      return;
    }
    switch (dialogMode.value) {
      case 'create-net':
        await store.createNetwork(name, Number(dialogRootKey.value));
        break;
      case 'rename-net':
        if (store.selectedNetworkKey != null) {
          await store.renameNetwork(store.selectedNetworkKey, name);
        }
        break;
      case 'clone-net':
        if (store.selectedNetworkKey != null) {
          await store.cloneNetwork(store.selectedNetworkKey, name);
        }
        break;
      case 'create-child':
        if (store.selectedNodeKey != null) {
          await store.createChild(store.selectedNodeKey, name);
        }
        break;
      case 'add-name':
        if (store.selectedNodeKey != null) {
          await store.addNodeName(store.selectedNodeKey, name);
        }
        break;
      case 'rename-node':
        if (store.selectedNodeKey != null) {
          await store.renameNode(store.selectedNodeKey, name);
        }
        break;
    }
    dialogOpen.value = false;
    $q.notify({ type: 'positive', message: 'Сохранено' });
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

async function onDetach(): Promise<void> {
  try {
    await store.detachSelectedEdge();
    $q.notify({ type: 'positive', message: 'Ребро отсоединено от схемы' });
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

async function onDeleteNode(): Promise<void> {
  $q.dialog({
    title: 'Удалить узел?',
    message:
      'Строгое удаление: запрещено при детях, ipgStPn или участии в других схемах. Продолжить?',
    cancel: true,
    persistent: true
  }).onOk(async () => {
    try {
      await store.deleteSelectedNode();
      $q.notify({ type: 'positive', message: 'Узел удалён' });
    } catch (err) {
      $q.notify({
        type: 'negative',
        message: err instanceof Error ? err.message : String(err)
      });
    }
  });
}

onMounted(() => {
  void store.fetchNetworks();
  void store.fetchIpgOptions();
});
</script>

<style scoped>
.investment-structure-inner {
  min-height: 0;
}

.investment-structure-splitter {
  min-height: 0;
}

.investment-structure-load-log {
  min-height: 0;
  overflow: auto;
  padding: 4px;
}

.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.investment-structure-tree {
  min-height: 120px;
  border: 1px solid rgba(0, 0, 0, 0.12);
  border-radius: 4px;
  overflow: hidden;
}

.investment-structure-unmatched-table {
  min-height: 0;
  overflow: auto;
}

.investment-structure-net-meta {
  color: var(--femsq-text-muted, rgba(0, 0, 0, 0.54));
}

:deep(.investment-structure-split-sep) {
  background: rgba(0, 0, 0, 0.08);
}

:deep(.investment-structure-split-sep:hover),
:deep(.investment-structure-split-sep:active) {
  background: rgba(25, 118, 210, 0.35);
}
</style>
