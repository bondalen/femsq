<template>
  <QPage class="cost-structure-view q-pa-none" data-test="cost-structure-view">
    <div class="absolute-full q-px-md q-pt-sm q-pb-sm column no-wrap cost-structure-inner">
      <div class="row items-center q-gutter-sm q-mb-xs shrink-0 no-wrap">
        <div class="text-subtitle1 text-weight-medium ellipsis">Структура затрат</div>
        <QSpace />
        <QBtn
          flat
          dense
          no-caps
          label="Переименовать"
          :disable="!store.selectedNetwork || store.mutating"
          data-test="cost-structure-rename-net"
          @click="openRenameNetwork"
        />
        <QBtn
          flat
          dense
          no-caps
          label="Клонировать"
          :disable="!store.selectedNetwork || store.mutating"
          data-test="cost-structure-clone-net"
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
          data-test="cost-structure-refresh"
          @click="onRefresh"
        />
      </div>

      <QBanner v-if="store.error" class="bg-negative text-white q-mb-xs shrink-0" rounded>
        {{ store.error }}
      </QBanner>

      <QBanner
        dense
        rounded
        class="q-mb-xs shrink-0"
        :class="store.canon.satisfied ? 'bg-positive text-white' : 'bg-warning text-dark'"
        data-test="cost-structure-canon-banner"
      >
        {{ store.canon.summary }}
        <span class="q-ml-sm text-caption">
          (минимум: 212 и ≥1 из 195/172/187; полная тройка не обязательна)
        </span>
      </QBanner>

      <FemsqCardStrip
        class="q-mb-xs shrink-0"
        :items="store.networks"
        item-key="stNetKey"
        :selected-key="store.selectedNetworkKey"
        :loading="store.loadingNetworks"
        :disabled="store.mutating"
        dense
        test-id-prefix="cost-structure-net"
        data-test="cost-structure-networks"
        @update:selected-key="onSelectNetworkKey"
      >
        <template #item="{ item }">
          <div class="text-weight-medium">{{ item.name }}</div>
          <div class="text-caption cost-structure-net-meta">
            stNet={{ item.stNetKey }} · root={{ item.rootKey }}
          </div>
        </template>
        <template #empty>Схемы затрат не найдены</template>
        <template #trailing>
          <QBtn
            flat
            dense
            no-caps
            icon="add"
            label="Создать"
            :disable="store.mutating"
            data-test="cost-structure-create-net"
            @click="openCreateNetwork"
          />
        </template>
      </FemsqCardStrip>

      <div class="column col no-wrap cost-structure-tree-pane">
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
            data-test="cost-structure-add-child"
            @click="openCreateChild"
          />
          <QBtn
            flat
            dense
            no-caps
            label="Переименовать узел"
            :disable="!store.selectedNodeKey || store.mutating"
            data-test="cost-structure-rename-node"
            @click="openRenameNode"
          />
          <QBtn
            flat
            dense
            no-caps
            label="Добавить имя"
            :disable="!store.selectedNodeKey || store.mutating"
            data-test="cost-structure-add-name"
            @click="openAddName"
          />
          <QBtn
            flat
            dense
            no-caps
            label="Привязать stc"
            :disable="!store.selectedNodeKey || store.mutating"
            data-test="cost-structure-attach"
            @click="openAttach"
          />
          <QBtn
            flat
            dense
            no-caps
            label="Перенести к…"
            :disable="!canDetach || store.mutating"
            data-test="cost-structure-move"
            @click="openMove"
          />
          <QBtn
            flat
            dense
            no-caps
            color="warning"
            label="Отсоединить"
            :disable="!canDetach || store.mutating"
            data-test="cost-structure-detach"
            @click="onDetach"
          />
          <QBtn
            flat
            dense
            no-caps
            color="negative"
            label="Удалить узел"
            :disable="!store.selectedNodeKey || store.mutating"
            data-test="cost-structure-delete-node"
            @click="onDeleteNode"
          />
        </div>

        <div
          v-if="store.loadingTree"
          class="text-grey-7 q-pa-md cost-structure-tree col"
          data-test="cost-structure-tree-loading"
        >
          Загрузка дерева…
        </div>
        <FemsqTreeList
          v-else
          class="cost-structure-tree col"
          :nodes="store.treeNodes"
          node-key="key"
          children-key="children"
          leaf-key="leaf"
          :columns="treeColumns"
          expand-on-click
          fill
          v-model:selected-key="selectedKeyModel"
          data-test="cost-structure-tree"
        >
          <template #empty>Нет узлов в схеме</template>
        </FemsqTreeList>

        <div v-if="store.selectedFlatNode" class="text-caption text-grey-7 q-mt-sm shrink-0">
          Выбран: stcKey={{ store.selectedFlatNode.childKey }}, parent={{
            store.selectedFlatNode.parentKey ?? '—'
          }}, stRel={{ store.selectedFlatNode.stRelKey ?? '—' }}
          <div v-if="store.loadingNames" class="q-mt-xs">Имена…</div>
          <div v-else-if="store.selectedNodeNames.length" class="q-mt-xs">
            Имена:
            <span
              v-for="(nm, idx) in store.selectedNodeNames"
              :key="nm.stcnKey"
            >{{ idx ? '; ' : '' }}{{ nm.name }}</span>
          </div>
        </div>
      </div>
    </div>

    <QDialog v-model="dialogOpen" persistent>
      <QCard style="min-width: 360px">
        <QCardSection>
          <div class="text-h6">{{ dialogTitle }}</div>
        </QCardSection>
        <QCardSection class="q-gutter-md">
          <QInput
            v-if="showNameField"
            v-model="dialogName"
            dense
            outlined
            :label="dialogNameLabel"
            data-test="cost-structure-dialog-name"
          />
          <QSelect
            v-if="dialogMode === 'create-net'"
            v-model="dialogRootKey"
            dense
            outlined
            emit-value
            map-options
            use-input
            input-debounce="0"
            label="Корневой узел (stcKey)"
            :options="filteredNodeOptions"
            @filter="filterNodeOptions"
            data-test="cost-structure-dialog-root"
          />
          <QSelect
            v-if="dialogMode === 'attach'"
            v-model="dialogChildKey"
            dense
            outlined
            emit-value
            map-options
            use-input
            input-debounce="0"
            label="Существующий узел (stcKey)"
            :options="filteredNodeOptions"
            @filter="filterNodeOptions"
            data-test="cost-structure-dialog-child"
          />
          <QSelect
            v-if="dialogMode === 'move'"
            v-model="dialogToParentKey"
            dense
            outlined
            emit-value
            map-options
            use-input
            input-debounce="0"
            label="Новый родитель"
            :options="filteredNodeOptions"
            @filter="filterNodeOptions"
            data-test="cost-structure-dialog-to-parent"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="OK"
            :loading="store.mutating"
            data-test="cost-structure-dialog-ok"
            @click="submitDialog"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
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
  useQuasar
} from 'quasar';
import { FemsqCardStrip, FemsqTreeList, type FemsqTreeKey, type FemsqTreeListColumn } from 'fequlib';

import {
  evaluateCostCanonAfterDelete,
  evaluateCostCanonAfterDetach,
  evaluateCostCanonAfterMove,
  touchesCostCanon
} from '@/domain/cost-structure-canon';
import {
  useStCostStructureStore,
  type StCostStructureTreeNode
} from '@/stores/st-cost-structure';

const store = useStCostStructureStore();
const $q = useQuasar();

const treeColumns: FemsqTreeListColumn<StCostStructureTreeNode>[] = [
  { name: 'label', label: 'Раздел', field: 'label' },
  { name: 'stNum', label: '№', field: 'stNum', width: '140px' },
  { name: 'stc', label: 'stc', field: 'key', width: '72px', align: 'right' },
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
>('create-net');
const dialogName = ref('');
const dialogRootKey = ref(214);
const dialogChildKey = ref<number | null>(null);
const dialogToParentKey = ref<number | null>(null);

interface NodeSelectOption {
  label: string;
  value: number;
  name: string;
}

const nodeSelectOptions = computed((): NodeSelectOption[] => {
  const byKey = new Map<number, NodeSelectOption>();
  for (const node of store.flatTree) {
    const name = (node.name ?? '').trim() || `stc ${node.childKey}`;
    byKey.set(node.childKey, {
      value: node.childKey,
      name,
      label: `${name} · id=${node.childKey}`
    });
  }
  if (byKey.size === 0) {
    byKey.set(214, {
      value: 214,
      name: 'Реализация инвестпроекта',
      label: 'Реализация инвестпроекта · id=214'
    });
  }
  return [...byKey.values()].sort((a, b) =>
    a.name.localeCompare(b.name, 'ru', { sensitivity: 'base' })
  );
});

const filteredNodeOptions = ref<NodeSelectOption[]>([]);

function filterNodeOptions(val: string, update: (fn: () => void) => void): void {
  update(() => {
    const needle = val.trim().toLowerCase();
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
      return 'Новая схема затрат';
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
    default:
      return '';
  }
});

const showNameField = computed(
  () =>
    dialogMode.value !== 'attach' &&
    dialogMode.value !== 'move'
);

const dialogNameLabel = computed(() => {
  if (dialogMode.value === 'create-child' || dialogMode.value === 'rename-node') {
    return 'Наименование узла';
  }
  if (dialogMode.value === 'add-name') {
    return 'Дополнительное имя';
  }
  return 'Наименование схемы';
});

/**
 * Подтверждение опасной правки канона (лог + dialog).
 *
 * @param touches затронут ли канон
 * @param willBreak сломается ли минимум после операции
 * @param detail текст для оператора
 */
function confirmCanonGuard(
  touches: boolean,
  willBreak: boolean,
  detail: string
): Promise<boolean> {
  if (!touches && !willBreak) {
    return Promise.resolve(true);
  }
  const title = willBreak ? 'Канон будет нарушен' : 'Правка канона 212/195/172/187';
  const message = willBreak
    ? `${detail}\n\nМинимум: 212 и ≥1 составляющая (195/172/187). Продолжить?`
    : `${detail}\n\nОперация затрагивает канон оси C. Минимум допускает одну составляющую. Продолжить?`;
  console.warn('[cost-structure] canon guard', { willBreak, detail, canon: store.canon });
  return new Promise((resolve) => {
    $q.dialog({
      title,
      message,
      cancel: true,
      persistent: true
    })
      .onOk(() => resolve(true))
      .onCancel(() => resolve(false));
  });
}

async function onRefresh(): Promise<void> {
  await store.fetchNetworks(store.selectedNetworkKey);
}

async function onSelectNetworkKey(key: FemsqTreeKey | null): Promise<void> {
  if (key == null) {
    return;
  }
  await store.selectNetwork(Number(key));
}

function openCreateNetwork(): void {
  dialogMode.value = 'create-net';
  dialogName.value = '';
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogRootKey.value = store.selectedNetwork?.rootKey ?? 214;
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
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogChildKey.value = null;
  dialogOpen.value = true;
}

function openMove(): void {
  if (!canDetach.value) {
    return;
  }
  dialogMode.value = 'move';
  filteredNodeOptions.value = nodeSelectOptions.value;
  dialogToParentKey.value = null;
  dialogOpen.value = true;
}

async function submitDialog(): Promise<void> {
  try {
    if (dialogMode.value === 'attach') {
      const childKey = Number(dialogChildKey.value);
      if (!Number.isFinite(childKey) || childKey <= 0 || store.selectedNodeKey == null) {
        $q.notify({ type: 'warning', message: 'Выберите существующий узел' });
        return;
      }
      const parentKey = store.selectedNodeKey;
      const touches = touchesCostCanon([childKey], parentKey);
      const ok = await confirmCanonGuard(
        touches,
        false,
        `Привязка ${childKey} под ${parentKey}. Сейчас: ${store.canon.summary}`
      );
      if (!ok) {
        return;
      }
      await store.attachExistingChild(parentKey, childKey);
      dialogOpen.value = false;
      $q.notify({ type: 'positive', message: 'Узел привязан' });
      return;
    }
    if (dialogMode.value === 'move') {
      const toParent = Number(dialogToParentKey.value);
      const node = store.selectedFlatNode;
      if (!Number.isFinite(toParent) || toParent <= 0 || node?.parentKey == null) {
        $q.notify({ type: 'warning', message: 'Выберите нового родителя' });
        return;
      }
      const after = evaluateCostCanonAfterMove(
        store.flatTree,
        node.childKey,
        node.parentKey,
        toParent
      );
      const touches = touchesCostCanon([node.childKey, toParent], node.parentKey);
      const ok = await confirmCanonGuard(
        touches,
        store.canon.satisfied && !after.satisfied,
        `Перенос ${node.childKey}: ${node.parentKey} → ${toParent}. После: ${after.summary}`
      );
      if (!ok) {
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
          const parentKey = store.selectedNodeKey;
          const touches = touchesCostCanon([], parentKey);
          const ok = await confirmCanonGuard(
            touches,
            false,
            `Новый дочерний под ${parentKey}. Сейчас: ${store.canon.summary}`
          );
          if (!ok) {
            return;
          }
          await store.createChild(parentKey, name);
        }
        break;
      case 'add-name':
        if (store.selectedNodeKey != null) {
          await store.addNodeName(store.selectedNodeKey, name);
        }
        break;
      case 'rename-node':
        if (store.selectedNodeKey != null) {
          const touches = touchesCostCanon([store.selectedNodeKey]);
          const ok = await confirmCanonGuard(
            touches,
            false,
            `Переименование узла ${store.selectedNodeKey}`
          );
          if (!ok) {
            return;
          }
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
  const node = store.selectedFlatNode;
  if (node?.parentKey == null) {
    return;
  }
  const after = evaluateCostCanonAfterDetach(store.flatTree, node.parentKey, node.childKey);
  const touches = touchesCostCanon([node.childKey], node.parentKey);
  const ok = await confirmCanonGuard(
    touches,
    store.canon.satisfied && !after.satisfied,
    `Отсоединить ${node.parentKey}→${node.childKey}. После: ${after.summary}`
  );
  if (!ok) {
    return;
  }
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
  const node = store.selectedFlatNode;
  if (node == null) {
    return;
  }
  const after = evaluateCostCanonAfterDelete(store.flatTree, node.childKey);
  const touches = touchesCostCanon([node.childKey], node.parentKey);
  const ok = await confirmCanonGuard(
    true,
    (touches && store.canon.satisfied && !after.satisfied) || !after.satisfied,
    `Удалить stc=${node.childKey}. Запрещено при детях / lim-UtPl / других схемах. После: ${after.summary}`
  );
  if (!ok) {
    return;
  }
  try {
    await store.deleteSelectedNode();
    $q.notify({ type: 'positive', message: 'Узел удалён' });
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

onMounted(() => {
  void store.fetchNetworks();
});
</script>

<style scoped>
.cost-structure-inner {
  min-height: 0;
}

.cost-structure-tree-pane {
  min-height: 0;
}

.cost-structure-tree {
  min-height: 0;
  overflow: auto;
}

.cost-structure-net-meta {
  opacity: 0.8;
}
</style>
