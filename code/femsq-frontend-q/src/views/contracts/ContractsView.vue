<template>
  <QPage class="contracts-view q-pa-md column no-wrap" data-test="contracts-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Договоры</div>
        <div class="femsq-page-subtitle">
          Access <code>cnNum</code> → <code>cn</code> → стороны
        </div>
      </div>
      <QBtn
        flat
        dense
        no-caps
        color="primary"
        icon="add"
        label="Договор"
        data-test="cn-create-btn"
        @click="openCreateDialog"
      />
      <QBtn
        flat
        dense
        icon="refresh"
        :loading="store.loadingList"
        aria-label="Обновить"
        @click="store.loadCnNums()"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>
      {{ store.error }}
    </QBanner>

    <QSplitter
      v-model="masterSplit"
      :limits="[22, 55]"
      separator-class="cn-split-sep"
      class="cn-main-splitter"
      data-test="cn-main-splitter"
    >
      <template #before>
        <section class="master-block fill-pane" data-test="cn-master">
          <FemsqTable
            class="master-table"
            root-class="master-table"
            row-key="cnnKey"
            :rows="store.cnNums"
            :columns="masterColumns"
            :loading="store.loadingList"
            :show-filter="true"
            v-model:pagination="cnNumPagination"
            selection="single"
            v-model:selected="selectedRows"
            @row-click="onCnNumRowClick"
          />
        </section>
      </template>

      <template #after>
        <section class="detail-block fill-pane column no-wrap" data-test="cn-detail">
          <div v-if="store.loadingDetail" class="text-caption text-grey-7 q-pa-sm">Загрузка…</div>
          <template v-else-if="store.selectedCn">
            <div class="cn-card-bar row items-center q-gutter-sm q-mb-xs q-px-xs">
              <span class="text-caption text-grey-8">
                cn_key={{ store.selectedCn.cnKey }}
                · {{ store.selectedCn.cnNumber || '—' }}
                · cn_date={{ store.selectedCn.cnDate || '—' }}
              </span>
              <QBtn
                flat
                dense
                no-caps
                size="sm"
                color="primary"
                icon="edit"
                label="cn_date"
                data-test="cn-edit-btn"
                @click="openEditCnDialog"
              />
            </div>
            <QTabs v-model="detailTab" dense class="shrink-0 q-mb-xs" active-color="primary">
              <QTab name="parties" label="Стороны" no-caps />
              <QTab name="sf" label="Счета-фактуры" no-caps />
            </QTabs>
            <QSplitter
              v-model="detailSplit"
              horizontal
              :limits="[20, 70]"
              separator-class="cn-split-sep"
              class="cn-detail-splitter col"
            >
              <template #before>
                <FemsqTable
                  class="nested-table"
                  root-class="nested-table"
                  row-key="cnnKey"
                  :rows="store.cnNumsForCn"
                  :columns="detailColumns"
                  :loading="store.loadingDetail"
                  :show-filter="false"
                  v-model:pagination="nestedPagination"
                  selection="single"
                  v-model:selected="nestedSelectedRows"
                  @row-click="onNestedCnNumClick"
                />
              </template>
              <template #after>
                <QTabPanels v-model="detailTab" animated class="fit">
                  <QTabPanel name="parties" class="q-pa-none fit">
                    <ContractPartiesPanel />
                  </QTabPanel>
                  <QTabPanel name="sf" class="q-pa-xs fit">
                    <div class="column fill-pane no-wrap">
                      <div class="text-caption text-grey-7 q-pb-sm">
                        Дерево договора и его связей; action на папке `cn.cnInv` открывает ту же `RecordModal`.
                      </div>
                      <RelationTree
                        v-if="store.selectedCn"
                        :key="relationTreeKey"
                        class="col"
                        :spec="cnRelationSpec"
                        :root-id="store.selectedCn.cnKey"
                        :fetch-node="fetchRelationNode"
                        :fetch-expand="fetchRelationExpand"
                        @action="onRelationAction"
                        root-class="contracts-relation-tree"
                      />
                    </div>
                  </QTabPanel>
                </QTabPanels>
              </template>
            </QSplitter>
          </template>
          <div v-else class="text-grey-7 q-pa-sm">Выберите номер договора слева</div>
        </section>
      </template>
    </QSplitter>

    <QDialog v-model="createDialog.open" persistent>
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">Новый договор</QCardSection>
        <QCardSection class="text-caption text-grey-7">
          Создаёт <code>cn</code> + номер. Обязателен только тип номера (<code>cnnType</code> NOT NULL в БД).
          Дата из свода пишется в <code>csoCnDate</code> исполнителя; <code>cn_date</code> при создании
          остаётся пустым (правка отдельно на карточке). Без исполнителя дату стороны добавить позже.
          Коллизию номера система не разрешает автоматически.
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="createDialog.cnnNum" label="Номер" hint="Можно пусто (NULL в БД)" dense autofocus />
          <QInput
            v-model="createDialog.csoCnDate"
            label="Дата для стороны (csoCnDate)"
            hint="Из Excel/свода → cn_s_org; пусто = дата отсутствует. Только при выборе исполнителя."
            dense
          />
          <QSelect
            v-model="createDialog.cnnType"
            :options="numTypeOptions"
            emit-value
            map-options
            label="Тип номера *"
            dense
            options-dense
          />
          <QSelect
            v-model="createDialog.csosOrgId"
            :options="orgIdOptions"
            emit-value
            map-options
            use-input
            clearable
            input-debounce="200"
            @filter="filterOrgIds"
            label="Исполнитель (org_id / БУиРГ)"
            hint="Необязательно; можно добавить smpl позже"
            dense
            options-dense
          />
          <QBanner v-if="createDialog.duplicateHint" class="bg-warning text-dark" rounded dense>
            {{ createDialog.duplicateHint }}
          </QBanner>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn
            flat
            dense
            no-caps
            color="primary"
            label="Создать"
            :loading="store.saving"
            @click="saveCreate"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="editCnDialog.open" persistent>
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">Карточка договора (cn)</QCardSection>
        <QCardSection class="text-caption text-grey-7">
          Справочная дата <code>cn_date</code> — не путать с <code>csoCnDate</code> в сторонах.
          Пустое значение допустимо (как у большинства договоров в БД).
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput
            v-model="editCnDialog.cnDate"
            label="cn_date"
            hint="ДД.ММ.ГГГГ или ГГГГ-ММ-ДД; пусто = NULL"
            dense
            autofocus
          />
          <QInput
            v-model="editCnDialog.cnNote"
            label="cn_note"
            type="textarea"
            autogrow
            dense
          />
          <QInput
            v-model.number="editCnDialog.cnMark"
            label="cnMark"
            type="number"
            clearable
            dense
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn
            flat
            dense
            no-caps
            color="primary"
            label="Сохранить"
            :loading="store.saving"
            @click="saveEditCn"
          />
        </QCardActions>
      </QCard>
    </QDialog>
    <RecordModal
      v-if="linkForm"
      v-model="linkModalOpen"
      :form="linkForm"
      :fetch-node="fetchRelationNode"
      :fetch-expand="fetchRelationExpand"
      @picker-select="onPickerSelect"
      @picker-search="onPickerSearch"
      @save="onLinkSave"
    />
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue';
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
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { createCnInv } from '@/api/contracts-api';
import { fetchRelationExpand, fetchRelationNode } from '@/api/relation-api';
import RecordModal from '@/components/relation/RecordModal.vue';
import RelationTree from '@/components/relation/RelationTree.vue';
import * as cnPickerSpecJson from '@/trees/cn-picker.tree.json';
import * as contractsInvSpecJson from '@/trees/contracts-inv.tree.json';
import { buildCnInvLinkForm, type RelationPickerCandidateRow } from '@/trees/relation-form-registry';
import type { RelationFormState } from '@/trees/relation-forms';
import type { RelationTreeActionContext, RelationTreeSpec } from '@/trees/relation-tree';
import ContractPartiesPanel from '@/views/contracts/ContractPartiesPanel.vue';
import { useContractsStore } from '@/stores/contracts';
import type { CnNumDto } from '@/types/contracts';
import { parseFlexibleDate } from '@/utils/flexible-date';

const store = useContractsStore();
const $q = useQuasar();
const cnRelationSpec = cnPickerSpecJson as RelationTreeSpec;
const contractsInvSpec = contractsInvSpecJson as RelationTreeSpec;
/** Доля ширины левой панели (список cnNum), как Access. */
const masterSplit = ref(36);
/** Доля высоты блока номеров над сторонами. */
const detailSplit = ref(32);
const detailTab = ref<'parties' | 'sf'>('parties');
const cnNumPagination = ref({ page: 1, rowsPerPage: 25 });
const nestedPagination = ref({ page: 1, rowsPerPage: 10 });
const orgIdFilter = ref('');
const relationTreeKey = ref(0);
const relationAction = ref<RelationTreeActionContext | null>(null);
const linkModalOpen = ref(false);

const createDialog = reactive({
  open: false,
  cnnNum: '',
  csoCnDate: '',
  cnnType: 1,
  csosOrgId: null as number | null,
  duplicateHint: '' as string
});

const editCnDialog = reactive({
  open: false,
  cnDate: '',
  cnNote: '',
  cnMark: null as number | null
});

const masterColumns: FemsqTableColumn<CnNumDto>[] = [
  {
    name: 'cnnNum',
    label: 'Номер',
    field: 'cnnNum',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.cnnNum ?? ''
  },
  {
    name: 'cnnTypeName',
    label: 'Тип',
    field: 'cnnTypeName',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.cnnTypeName ?? ''
  }
];

const detailColumns: FemsqTableColumn<CnNumDto>[] = [
  ...masterColumns,
  {
    name: 'cnnKey',
    label: 'cnnKey',
    field: 'cnnKey',
    sortable: true,
    align: 'right'
  },
  {
    name: 'cnnCn',
    label: 'cn_key',
    field: 'cnnCn',
    sortable: true,
    align: 'right'
  }
];

const pickerColumns: FemsqTableColumn<RelationPickerCandidateRow>[] = [
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  { name: 'cnNum', label: 'договор', field: 'cnNum', align: 'left' },
  { name: 'invKey', label: 'inv', field: 'invKey', align: 'right' },
  { name: 'invNum', label: 'СФ', field: 'invNum', align: 'left' }
];

const numTypeOptions = computed(() =>
  store.numTypes.map((row) => ({
    label: row.cnntName || String(row.cnntKey),
    value: row.cnntKey
  }))
);

const orgIdOptions = computed(() => {
  const q = orgIdFilter.value.trim().toLowerCase();
  return store.orgIdLookups
    .filter((row) => !q || row.label.toLowerCase().includes(q) || String(row.orgIdKey).includes(q))
    .map((row) => ({ label: row.label, value: row.orgIdKey }));
});

const selectedRows = computed({
  get: () => {
    const row = store.selectedCnNum;
    return row ? [row] : [];
  },
  set: (rows: CnNumDto[]) => {
    const first = rows[0];
    if (first) {
      void store.selectCnNum(first.cnnKey);
    }
  }
});

const nestedSelectedRows = computed({
  get: () => {
    const key = store.selectedCnnKey;
    const row = store.cnNumsForCn.find((item) => item.cnnKey === key);
    return row ? [row] : [];
  },
  set: (rows: CnNumDto[]) => {
    const first = rows[0];
    if (first) {
      void store.selectCnNum(first.cnnKey);
    }
  }
});

const selectedCnCandidate = computed<RelationPickerCandidateRow | null>(() => {
  const cn = store.selectedCn;
  if (!cn) {
    return null;
  }
  return {
    rowKey: String(cn.cnKey),
    cnKey: cn.cnKey,
    cnNum: store.selectedCnNum?.cnnNum ?? cn.cnNumber,
    invKey: null,
    invNum: null
  };
});

const linkForm = computed<RelationFormState | null>(() => {
  const action = relationAction.value;
  const cnCandidate = selectedCnCandidate.value;
  if (!linkModalOpen.value || action == null || cnCandidate == null) {
    return null;
  }
  return buildCnInvLinkForm({
    context: action,
    domain: null,
    cnCandidates: [cnCandidate],
    invCandidates: store.cnInvLookupRows as RelationPickerCandidateRow[],
    selectedCnCandidate: cnCandidate,
    selectedInvCandidate: store.selectedCnInvLookup as RelationPickerCandidateRow | null,
    cnPickerSpec: cnRelationSpec,
    invPickerSpec: contractsInvSpec,
    pickerColumns,
    invSearchValue: store.cnInvLookupQuery,
    invSearchLoading: store.cnInvLookupLoading,
    invSearchStatus: store.cnInvLookupStatus
  });
});

function onCnNumRowClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

function onNestedCnNumClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

/**
 * Contract-side action открывает тот же flow `cnInv.link`.
 */
function onRelationAction(context: RelationTreeActionContext): void {
  if (context.actionId !== 'cnInv.link.create' || context.node.edge !== 'cn.cnInv') {
    return;
  }
  relationAction.value = context;
  linkModalOpen.value = true;
}

function onPickerSelect(pickerId: string, rowKey: string | null): void {
  if (pickerId !== 'inv') {
    return;
  }
  store.selectCnInvLookup(rowKey);
}

async function onPickerSearch(pickerId: string, value: string): Promise<void> {
  if (pickerId !== 'inv') {
    return;
  }
  try {
    await store.searchCnInvLookup(value);
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: error instanceof Error ? error.message : 'Ошибка поиска СФ'
    });
  }
}

async function onLinkSave(): Promise<void> {
  const cnKey = selectedCnCandidate.value?.cnKey;
  const invKey = store.selectedCnInvLookup?.invKey;
  if (cnKey == null || invKey == null) {
    $q.notify({ type: 'warning', message: 'Выберите СФ для привязки к договору.' });
    return;
  }
  try {
    await createCnInv({ ciInv: invKey, ciCn: cnKey });
    linkModalOpen.value = false;
    relationAction.value = null;
    relationTreeKey.value += 1;
    $q.notify({ type: 'positive', message: 'Связь cnInv сохранена' });
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: error instanceof Error ? error.message : 'Не удалось сохранить cnInv'
    });
  }
}

function filterOrgIds(val: string, update: (fn: () => void) => void): void {
  update(() => {
    orgIdFilter.value = val;
  });
}

/**
 * Открывает диалог нового договора.
 */
async function openCreateDialog(): Promise<void> {
  await Promise.all([store.ensureNumTypes(), store.ensureOrgIdLookups()]);
  createDialog.cnnNum = '';
  createDialog.csoCnDate = '';
  createDialog.cnnType = 1;
  createDialog.csosOrgId = null;
  createDialog.duplicateHint = '';
  createDialog.open = true;
}

/**
 * Открывает правку карточки cn (cn_date и пр.).
 */
function openEditCnDialog(): void {
  const cn = store.selectedCn;
  if (!cn) {
    return;
  }
  editCnDialog.cnDate = cn.cnDate ?? '';
  editCnDialog.cnNote = cn.cnNote ?? '';
  editCnDialog.cnMark = cn.cnMark;
  editCnDialog.open = true;
}

/**
 * Сохраняет cn_date / note / mark.
 */
async function saveEditCn(): Promise<void> {
  let cnDate: string | null;
  try {
    cnDate = parseFlexibleDate(editCnDialog.cnDate);
  } catch (err) {
    $q.notify({
      type: 'warning',
      message: err instanceof Error ? err.message : 'Некорректная дата'
    });
    return;
  }
  try {
    await store.saveCn({
      cnDate,
      cnNote: editCnDialog.cnNote.trim() === '' ? null : editCnDialog.cnNote,
      cnMark: editCnDialog.cnMark == null || Number.isNaN(editCnDialog.cnMark) ? null : editCnDialog.cnMark
    });
    editCnDialog.open = false;
    $q.notify({ type: 'positive', message: 'Карточка cn сохранена' });
  } catch {
    /* error в store */
  }
}

/**
 * Создаёт договор; при коллизии номера — предупреждение, решение за оператором.
 */
async function saveCreate(): Promise<void> {
  if (createDialog.cnnType == null || createDialog.cnnType <= 0) {
    $q.notify({ type: 'warning', message: 'Укажите тип номера (обязательное поле БД)' });
    return;
  }
  const cnnNumRaw = createDialog.cnnNum.trim();
  const cnnNum = cnnNumRaw === '' ? null : cnnNumRaw;
  let csoCnDate: string | null;
  try {
    csoCnDate = parseFlexibleDate(createDialog.csoCnDate);
  } catch (err) {
    $q.notify({
      type: 'warning',
      message: err instanceof Error ? err.message : 'Некорректная дата'
    });
    return;
  }
  if (csoCnDate != null && createDialog.csosOrgId == null) {
    $q.notify({
      type: 'warning',
      message: 'Дата csoCnDate сохраняется только вместе с исполнителем — выберите org_id или очистите дату'
    });
    return;
  }

  let duplicates = 0;
  try {
    duplicates = await store.duplicateCount(cnnNum ?? '');
  } catch {
    /* не блокируем создание */
  }

  const doCreate = async (): Promise<void> => {
    try {
      await store.createContract({
        cnnNum,
        csoCnDate,
        cnnType: createDialog.cnnType,
        csosOrgId: createDialog.csosOrgId
      });
      createDialog.open = false;
      $q.notify({ type: 'positive', message: 'Договор создан' });
    } catch {
      /* error в store */
    }
  };

  if (duplicates > 0) {
    const label = cnnNum ?? '(пустой номер)';
    createDialog.duplicateHint =
      `Уже есть ${duplicates} номер(ов) «${label}». Коллизию система не разрешает — ` +
      'если это новый договор, создавайте; если старый — отмените и добавьте smpl к существующему.';
    $q.dialog({
      title: 'Коллизия номера',
      message:
        `В БД уже есть ${duplicates} записей с номером «${label}». ` +
        'Автоматически выбрать «тот самый» договор нельзя. Продолжить создание нового?',
      cancel: { flat: true, label: 'Отмена' },
      ok: { flat: true, color: 'primary', label: 'Создать новый' }
    }).onOk(() => {
      void doCreate();
    });
    return;
  }

  await doCreate();
}

onMounted(() => {
  void store.loadCnNums();
});
</script>

<style scoped>
.contracts-view {
  min-height: 0;
  height: calc(100vh - 100px);
}

.cn-main-splitter,
.cn-detail-splitter {
  flex: 1 1 auto;
  min-height: 0;
}

.fill-pane {
  min-height: 0;
  height: 100%;
  overflow: hidden;
  padding-right: 4px;
}

.detail-block {
  overflow: hidden;
}

.master-table,
.nested-table {
  width: 100%;
}

.cn-split-sep {
  background: var(--femsq-border, #555);
}

.dialog-card {
  min-width: 420px;
  max-width: 520px;
}

.dialog-title {
  font-weight: 600;
}

.cn-card-bar {
  flex: 0 0 auto;
  min-height: 28px;
}
</style>
