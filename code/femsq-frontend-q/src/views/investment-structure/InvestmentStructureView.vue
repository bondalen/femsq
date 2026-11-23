<template>
  <QPage class="investment-structure-view q-pa-lg" data-test="investment-structure-view">
    <div class="row items-center q-gutter-md q-mb-md">
      <div>
        <div class="text-h5">Структура ИПГ</div>
        <div class="text-caption text-grey-7">
          Схемы stNet (type=1) и дерево разделов через fnSt
        </div>
      </div>
      <QSpace />
      <QBtn
        flat
        round
        icon="refresh"
        :loading="store.loadingNetworks || store.loadingTree"
        :disable="store.mutating"
        aria-label="Обновить"
        data-test="investment-structure-refresh"
        @click="onRefresh"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-md" rounded>
      {{ store.error }}
    </QBanner>

    <div class="row items-center q-mb-sm">
      <div class="text-subtitle1">Схемы</div>
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
    </div>

    <FemsqCardStrip
      class="q-mb-md"
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
        <div class="text-caption text-grey-7">
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

    <div class="row items-center q-mb-sm q-gutter-xs">
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
      class="text-grey-7 q-pa-md investment-structure-tree"
      data-test="investment-structure-tree-loading"
    >
      Загрузка дерева…
    </div>
    <FemsqTreeList
      v-else
      class="investment-structure-tree"
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
    </FemsqTreeList>

    <div v-if="store.selectedFlatNode" class="text-caption text-grey-7 q-mt-md">
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

    <QDialog v-model="dialogOpen" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-h6">{{ dialogTitle }}</QCardSection>
        <QCardSection>
          <QInput
            v-if="dialogMode !== 'attach' && dialogMode !== 'move'"
            v-model="dialogName"
            dense
            autofocus
            :label="dialogNameLabel"
            data-test="investment-structure-dialog-name"
            @keyup.enter="submitDialog"
          />
          <QInput
            v-if="dialogMode === 'create-net'"
            v-model.number="dialogRootKey"
            class="q-mt-md"
            dense
            type="number"
            label="rootKey (stiKey корня)"
            data-test="investment-structure-dialog-root"
          />
          <QInput
            v-if="dialogMode === 'attach'"
            v-model.number="dialogChildKey"
            dense
            autofocus
            type="number"
            label="stiKey существующего узла"
            data-test="investment-structure-dialog-child"
            @keyup.enter="submitDialog"
          />
          <QInput
            v-if="dialogMode === 'move'"
            v-model.number="dialogToParentKey"
            dense
            autofocus
            type="number"
            label="stiKey нового родителя"
            data-test="investment-structure-dialog-to-parent"
            @keyup.enter="submitDialog"
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
  QSpace,
  useQuasar
} from 'quasar';
import {
  FemsqCardStrip,
  FemsqTreeList,
  type FemsqTreeKey,
  type FemsqTreeListColumn
} from 'fequlib';

import {
  useStIpgStructureStore,
  type StIpgStructureTreeNode
} from '@/stores/st-ipg-structure';

const store = useStIpgStructureStore();
const $q = useQuasar();

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
>('create-net');
const dialogName = ref('');
const dialogRootKey = ref(1);
const dialogChildKey = ref<number | null>(null);
const dialogToParentKey = ref<number | null>(null);

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
  dialogChildKey.value = null;
  dialogOpen.value = true;
}

function openMove(): void {
  if (!canDetach.value) {
    return;
  }
  dialogMode.value = 'move';
  dialogToParentKey.value = null;
  dialogOpen.value = true;
}

async function submitDialog(): Promise<void> {
  try {
    if (dialogMode.value === 'attach') {
      const childKey = Number(dialogChildKey.value);
      if (!Number.isFinite(childKey) || childKey <= 0) {
        $q.notify({ type: 'warning', message: 'Укажите stiKey ребёнка' });
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
        $q.notify({ type: 'warning', message: 'Укажите stiKey нового родителя' });
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
});
</script>

<style scoped>
.investment-structure-tree {
  min-height: 420px;
  height: calc(100vh - 320px);
  border: 1px solid rgba(0, 0, 0, 0.12);
  border-radius: 4px;
  overflow: hidden;
}
</style>
