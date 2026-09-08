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
                · ввод={{ formatCnDateTime(store.selectedCn.cnTimeOfEntry) }}
                <template v-if="store.selectedCn.cnMark != null">
                  · cnMark={{ store.selectedCn.cnMark }}
                </template>
                <template v-if="store.selectedCn.cnName">
                  · cnName={{ store.selectedCn.cnName }}
                </template>
              </span>
              <QBtn
                flat
                dense
                no-caps
                size="sm"
                color="primary"
                icon="add"
                label="Номер"
                data-test="cn-num-add-btn"
                @click="openAddNumDialog"
              />
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
              <QBtn
                flat
                dense
                no-caps
                size="sm"
                color="negative"
                icon="delete"
                label="Договор"
                data-test="cn-delete-btn"
                @click="confirmDeleteCn"
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
                    <QSplitter
                      v-model="sfSplit"
                      :limits="[22, 55]"
                      separator-class="cn-split-sep"
                      class="fit"
                      data-test="cn-sf-splitter"
                    >
                      <template #before>
                        <div class="column fill-pane no-wrap" data-test="cn-inv-list">
                          <div class="row items-center q-gutter-xs q-pb-xs shrink-0">
                            <div class="col text-caption text-grey-7">
                              Связи cnInv договора
                              <span v-if="store.cnInvs.length"> · {{ store.cnInvs.length }}</span>
                            </div>
                            <QBtn
                              flat
                              dense
                              no-caps
                              size="sm"
                              color="primary"
                              icon="add"
                              label="Связь"
                              data-test="cn-inv-create-btn"
                              @click="openCreateCnInvDialog"
                            />
                            <QBtn
                              flat
                              dense
                              no-caps
                              size="sm"
                              color="primary"
                              icon="edit"
                              label="Перенести"
                              :disable="!store.selectedCnInv"
                              data-test="cn-inv-edit-btn"
                              @click="openEditCnInvDialog"
                            />
                            <QBtn
                              flat
                              dense
                              no-caps
                              size="sm"
                              color="negative"
                              icon="delete"
                              label="Связь"
                              :disable="!store.selectedCnInv"
                              data-test="cn-inv-delete-btn"
                              @click="confirmDeleteSelectedCnInv"
                            />
                          </div>
                          <FemsqTable
                            class="col cn-inv-table"
                            root-class="cn-inv-table"
                            row-key="ciKey"
                            :rows="store.cnInvs"
                            :columns="cnInvColumns"
                            :loading="store.loadingCnInvs"
                            :show-filter="true"
                            v-model:pagination="cnInvPagination"
                            selection="single"
                            v-model:selected="selectedCnInvRows"
                            dense
                            @row-click="onCnInvRowClick"
                          />
                        </div>
                      </template>
                      <template #after>
                        <div class="column fill-pane no-wrap" data-test="cn-inv-tree">
                          <div class="text-caption text-grey-7 q-pb-xs shrink-0">
                            Дерево СФ (<code>contracts-inv</code>)
                          </div>
                          <RelationTree
                            v-if="store.selectedCnInv"
                            :key="`inv-${store.selectedCnInv.ciInv}-${relationTreeKey}`"
                            class="col"
                            :spec="contractsInvSpec"
                            :root-id="store.selectedCnInv.ciInv"
                            :fetch-node="fetchRelationNode"
                            :fetch-expand="fetchRelationExpand"
                            root-class="contracts-relation-tree"
                            @action="onRelationAction"
                          />
                          <div v-else class="text-grey-7 q-pa-sm">
                            {{
                              store.loadingCnInvs
                                ? 'Загрузка связей…'
                                : store.cnInvs.length === 0
                                  ? 'У договора нет связей cnInv'
                                  : 'Выберите связь слева'
                            }}
                          </div>
                        </div>
                      </template>
                    </QSplitter>
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

    <QDialog v-model="addNumDialog.open" persistent>
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">Добавить номер к договору</QCardSection>
        <QCardSection class="text-caption text-grey-7">
          Добавляет строку в <code>cnNum</code> для cn_key={{ store.selectedCn?.cnKey ?? '—' }}.
          Не создаёт новый договор — в отличие от «+ Договор» в шапке.
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="addNumDialog.cnnNum" label="Номер *" dense autofocus />
          <QSelect
            v-model="addNumDialog.cnnType"
            :options="numTypeOptions"
            emit-value
            map-options
            label="Тип номера *"
            dense
            options-dense
          />
          <QBanner v-if="addNumDialog.duplicateHint" class="bg-warning text-dark" rounded dense>
            {{ addNumDialog.duplicateHint }}
          </QBanner>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn
            flat
            dense
            no-caps
            color="primary"
            label="Добавить"
            :loading="store.saving"
            @click="saveAddNum"
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
import { computed, onMounted, reactive, ref, watch } from 'vue';
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

import { createCnInv, updateCnInv } from '@/api/contracts-api';
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
import type { CnInvListRow, CnNumDto } from '@/types/contracts';
import { parseFlexibleDate } from '@/utils/flexible-date';

const store = useContractsStore();
const $q = useQuasar();
const cnRelationSpec = cnPickerSpecJson as RelationTreeSpec;
const contractsInvSpec = contractsInvSpecJson as RelationTreeSpec;

/**
 * Краткий показ DateTime с GraphQL (ISO) для полосы карточки cn.
 */
function formatCnDateTime(value: string | null | undefined): string {
  if (value == null || value === '') {
    return '—';
  }
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) {
    return value;
  }
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** Доля ширины левой панели (список cnNum), как Access. */
const masterSplit = ref(36);
/** Доля высоты блока номеров над сторонами. */
const detailSplit = ref(32);
/** Доля ширины списка cnInv на вкладке СФ. */
const sfSplit = ref(36);
const detailTab = ref<'parties' | 'sf'>('parties');
const cnNumPagination = ref({ page: 1, rowsPerPage: 25 });
const nestedPagination = ref({ page: 1, rowsPerPage: 10 });
const cnInvPagination = ref({ page: 1, rowsPerPage: 25 });
const orgIdFilter = ref('');
const relationTreeKey = ref(0);
const relationAction = ref<RelationTreeActionContext | null>(null);
const linkModalOpen = ref(false);
/** Выбранный договор в модалке cnInv (для переноса связи в режиме «Правка»). */
const linkCnCandidate = ref<RelationPickerCandidateRow | null>(null);
const cnPickerQuery = ref('');
const cnInvFormMode = computed<'create' | 'edit'>(() =>
  relationAction.value?.actionId === 'cnInv.link.edit' ? 'edit' : 'create'
);

const createDialog = reactive({
  open: false,
  cnnNum: '',
  csoCnDate: '',
  cnnType: 1,
  csosOrgId: null as number | null,
  duplicateHint: '' as string
});

const addNumDialog = reactive({
  open: false,
  cnnNum: '',
  cnnType: 1,
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
    name: 'cnnNote',
    label: 'Примечание',
    field: 'cnnNote',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.cnnNote ?? ''
  },
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

const cnInvColumns: FemsqTableColumn<CnInvListRow>[] = [
  {
    name: 'iNum',
    label: '№ СФ',
    field: 'iNum',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.iNum ?? ''
  },
  {
    name: 'ciInv',
    label: 'inv',
    field: 'ciInv',
    sortable: true,
    align: 'right',
    filterValue: (row) => String(row.ciInv)
  },
  {
    name: 'ciKey',
    label: 'ciKey',
    field: 'ciKey',
    sortable: true,
    align: 'right',
    filterValue: (row) => String(row.ciKey)
  },
  {
    name: 'ciTimeOfEntry',
    label: 'ввод',
    field: 'ciTimeOfEntry',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.ciTimeOfEntry ?? ''
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

const selectedCnInvRows = computed({
  get: () => {
    const row = store.selectedCnInv;
    return row ? [row] : [];
  },
  set: (rows: CnInvListRow[]) => {
    const first = rows[0];
    if (first) {
      store.selectCnInv(first.ciKey);
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

/**
 * Кандидаты договора для picker в модалке (dedupe по cn_key из master cnNum).
 */
const cnPickerRows = computed<RelationPickerCandidateRow[]>(() => {
  const q = cnPickerQuery.value.trim().toLowerCase();
  const seen = new Set<number>();
  const rows: RelationPickerCandidateRow[] = [];
  for (const item of store.cnNums) {
    if (seen.has(item.cnnCn)) {
      continue;
    }
    seen.add(item.cnnCn);
    const cnNum = item.cnnNum ?? '';
    if (q && !cnNum.toLowerCase().includes(q) && !String(item.cnnCn).includes(q)) {
      continue;
    }
    rows.push({
      rowKey: String(item.cnnCn),
      cnKey: item.cnnCn,
      cnNum: item.cnnNum,
      invKey: null,
      invNum: null
    });
  }
  return rows;
});

const selectedCnInvCandidate = computed<RelationPickerCandidateRow | null>(() => {
  const row = store.selectedCnInv;
  if (!row) {
    return null;
  }
  return {
    rowKey: String(row.ciInv),
    invKey: row.ciInv,
    invNum: row.iNum,
    cnKey: store.selectedCn?.cnKey ?? null,
    cnNum: store.selectedCnNum?.cnnNum ?? store.selectedCn?.cnNumber ?? null
  };
});

const linkForm = computed<RelationFormState | null>(() => {
  const action = relationAction.value;
  const cnCandidate = linkCnCandidate.value ?? selectedCnCandidate.value;
  if (!linkModalOpen.value || action == null || cnCandidate == null) {
    return null;
  }
  const isEdit = cnInvFormMode.value === 'edit';
  return buildCnInvLinkForm({
    context: action,
    mode: cnInvFormMode.value,
    domain: null,
    cnCandidates: isEdit ? cnPickerRows.value : [cnCandidate],
    invCandidates: store.cnInvLookupRows as RelationPickerCandidateRow[],
    selectedCnCandidate: cnCandidate,
    selectedInvCandidate: isEdit
      ? selectedCnInvCandidate.value
      : (store.selectedCnInvLookup as RelationPickerCandidateRow | null),
    cnPickerSpec: cnRelationSpec,
    invPickerSpec: contractsInvSpec,
    pickerColumns,
    invSearchValue: store.cnInvLookupQuery,
    invSearchLoading: store.cnInvLookupLoading,
    invSearchStatus: store.cnInvLookupStatus,
    cnSearchValue: cnPickerQuery.value,
    cnSearchStatus:
      cnPickerRows.value.length > 0
        ? `Договоров в списке: ${cnPickerRows.value.length}`
        : 'Нет договоров по фильтру — уточните номер или cn_key'
  });
});

function onCnNumRowClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

function onNestedCnNumClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

/**
 * Выбор связи cnInv на вкладке «Счета-фактуры».
 */
function onCnInvRowClick(_evt: Event, row: CnInvListRow): void {
  store.selectCnInv(row.ciKey);
}

/**
 * Контекст action для создания/правки cnInv с панели «Счета-фактуры».
 */
function cnInvActionContext(
  actionId: 'cnInv.link.create' | 'cnInv.link.edit',
  ciKey?: number | null,
  invKey?: number | null
): RelationTreeActionContext {
  const cnKey = store.selectedCn?.cnKey ?? null;
  return {
    actionId,
    root: { table: 'cn', id: cnKey },
    node: {
      kind: 'record',
      table: actionId === 'cnInv.link.edit' ? 'cnInv' : 'cn',
      edge: 'cn.cnInv',
      fromId: cnKey,
      rowKey: ciKey ?? null,
      title: '',
      fields: {
        ciCn: cnKey != null ? String(cnKey) : null,
        ciInv: invKey != null ? String(invKey) : null
      }
    }
  };
}

function openCreateCnInvDialog(): void {
  if (store.selectedCn == null) {
    $q.notify({ type: 'warning', message: 'Сначала выберите договор' });
    return;
  }
  store.clearCnInvLookup();
  linkCnCandidate.value = selectedCnCandidate.value;
  cnPickerQuery.value = '';
  relationAction.value = cnInvActionContext('cnInv.link.create');
  linkModalOpen.value = true;
}

function openEditCnInvDialog(): void {
  const row = store.selectedCnInv;
  if (row == null) {
    $q.notify({ type: 'warning', message: 'Выберите связь cnInv' });
    return;
  }
  linkCnCandidate.value = selectedCnCandidate.value;
  cnPickerQuery.value = store.selectedCnNum?.cnnNum ?? store.selectedCn?.cnNumber ?? '';
  relationAction.value = cnInvActionContext('cnInv.link.edit', row.ciKey, row.ciInv);
  linkModalOpen.value = true;
}

/**
 * Contract-side action открывает тот же flow `cnInv.link`.
 */
function onRelationAction(context: RelationTreeActionContext): void {
  if (context.actionId === 'cnInv.link.create' && context.node.edge === 'cn.cnInv') {
    relationAction.value = context;
    linkModalOpen.value = true;
    return;
  }
  if (context.actionId === 'cnInv.link.edit' && context.node.table === 'cnInv') {
    relationAction.value = context;
    linkModalOpen.value = true;
    return;
  }
  if (context.actionId === 'cnInv.link.delete' && context.node.table === 'cnInv') {
    void onDeleteCnInv(context);
  }
}

function onPickerSelect(pickerId: string, rowKey: string | null): void {
  if (pickerId === 'inv') {
    store.selectCnInvLookup(rowKey);
    return;
  }
  if (pickerId === 'cn') {
    linkCnCandidate.value =
      cnPickerRows.value.find((row) => row.rowKey === rowKey) ??
      (rowKey != null
        ? {
            rowKey,
            cnKey: Number(rowKey) || null,
            cnNum: null,
            invKey: null,
            invNum: null
          }
        : null);
  }
}

async function onPickerSearch(pickerId: string, value: string): Promise<void> {
  if (pickerId === 'cn') {
    cnPickerQuery.value = value;
    return;
  }
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
  const mode = cnInvFormMode.value;
  const cnKey = linkCnCandidate.value?.cnKey ?? selectedCnCandidate.value?.cnKey;
  const currentInvFromAction = Number(relationAction.value?.node.fields.ciInv ?? null);
  const invKey =
    (mode === 'edit' ? store.selectedCnInv?.ciInv : null) ??
    store.selectedCnInvLookup?.invKey ??
    (currentInvFromAction > 0 ? currentInvFromAction : null);
  if (cnKey == null || invKey == null) {
    $q.notify({ type: 'warning', message: 'Выберите СФ для привязки к договору.' });
    return;
  }
  try {
    const ciKey = relationAction.value?.node.rowKey;
    if (mode === 'edit') {
      if (ciKey == null) {
        throw new Error('Не найден ciKey для правки cnInv.');
      }
      await updateCnInv(ciKey, { ciInv: invKey, ciCn: cnKey });
    } else {
      await createCnInv({ ciInv: invKey, ciCn: cnKey });
    }
    linkModalOpen.value = false;
    relationAction.value = null;
    linkCnCandidate.value = null;
    cnPickerQuery.value = '';
    relationTreeKey.value += 1;
    if (cnKey != null) {
      await store.loadCnInvs(cnKey);
    }
    const currentCnKey = store.selectedCn?.cnKey;
    if (currentCnKey != null && currentCnKey !== cnKey) {
      await store.loadCnInvs(currentCnKey);
    }
    $q.notify({
      type: 'positive',
      message: mode === 'edit' ? 'Связь cnInv обновлена' : 'Связь cnInv сохранена'
    });
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: error instanceof Error ? error.message : 'Не удалось сохранить cnInv'
    });
  }
}

async function confirmDeleteSelectedCnInv(): Promise<void> {
  const row = store.selectedCnInv;
  if (row == null) {
    $q.notify({ type: 'warning', message: 'Выберите связь cnInv' });
    return;
  }
  await confirmDeleteCnInv(row.ciKey, row.iNum, row.ciInv);
}

async function confirmDeleteCnInv(
  ciKey: number,
  invNum?: string | null,
  invKey?: number | null
): Promise<void> {
  const label = invNum ?? (invKey != null ? `inv=${invKey}` : '');
  const confirmed = await new Promise<boolean>((resolve) => {
    $q.dialog({
      title: 'Удалить связь с СФ',
      message: `Удалить cnInv ciKey=${ciKey}${label ? ` (${label})` : ''}?`,
      cancel: true,
      persistent: true
    })
      .onOk(() => resolve(true))
      .onCancel(() => resolve(false))
      .onDismiss(() => resolve(false));
  });
  if (!confirmed) {
    return;
  }
  try {
    await store.removeCnInv(ciKey);
    relationTreeKey.value += 1;
    $q.notify({ type: 'positive', message: 'Связь cnInv удалена' });
  } catch {
    /* error в store */
  }
}

async function onDeleteCnInv(context: RelationTreeActionContext): Promise<void> {
  const ciKey = context.node.rowKey;
  if (ciKey == null) {
    $q.notify({ type: 'warning', message: 'Не найден ciKey для удаления cnInv.' });
    return;
  }
  const invKey = Number(context.node.fields.ciInv ?? null);
  await confirmDeleteCnInv(ciKey, null, invKey > 0 ? invKey : null);
}

async function confirmDeleteCn(): Promise<void> {
  const cn = store.selectedCn;
  if (cn == null) {
    return;
  }
  await store.loadCnInvs(cn.cnKey);
  if (store.cnInvs.length > 0) {
    $q.notify({
      type: 'warning',
      message: `У договора cn=${cn.cnKey} есть ${store.cnInvs.length} связей cnInv — сначала удалите их на вкладке «Счета-фактуры».`
    });
    return;
  }
  const confirmed = await new Promise<boolean>((resolve) => {
    $q.dialog({
      title: 'Удалить договор',
      message:
        `Удалить cn_key=${cn.cnKey} «${store.selectedCnNum?.cnnNum ?? cn.cnNumber ?? '—'}»? ` +
        'Будут удалены номера и стороны; операция необратима.',
      cancel: true,
      persistent: true
    })
      .onOk(() => resolve(true))
      .onCancel(() => resolve(false))
      .onDismiss(() => resolve(false));
  });
  if (!confirmed) {
    return;
  }
  try {
    await store.removeCn(cn.cnKey);
    $q.notify({ type: 'positive', message: 'Договор удалён' });
  } catch {
    /* error в store */
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
 * Открывает диалог добавления номера к выбранному cn.
 */
async function openAddNumDialog(): Promise<void> {
  const cn = store.selectedCn;
  if (!cn) {
    return;
  }
  await store.ensureNumTypes();
  const existingType =
    store.selectedCnNum?.cnnType ??
    store.cnNumsForCn.find((row) => row.cnnType != null && row.cnnType > 0)?.cnnType ??
    1;
  addNumDialog.cnnNum = '';
  addNumDialog.cnnType = existingType;
  addNumDialog.duplicateHint = '';
  addNumDialog.open = true;
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

/**
 * Добавляет второй номер к выбранному договору.
 */
async function saveAddNum(): Promise<void> {
  const cnKey = store.selectedCn?.cnKey;
  if (cnKey == null) {
    $q.notify({ type: 'warning', message: 'Договор не выбран' });
    return;
  }
  if (addNumDialog.cnnType == null || addNumDialog.cnnType <= 0) {
    $q.notify({ type: 'warning', message: 'Укажите тип номера (обязательное поле БД)' });
    return;
  }
  const cnnNumRaw = addNumDialog.cnnNum.trim();
  if (cnnNumRaw === '') {
    $q.notify({ type: 'warning', message: 'Укажите номер' });
    return;
  }

  const alreadyOnCn = store.cnNumsForCn.some(
    (row) => (row.cnnNum ?? '').trim().toUpperCase() === cnnNumRaw.toUpperCase()
  );
  if (alreadyOnCn) {
    $q.notify({ type: 'warning', message: `Номер «${cnnNumRaw}» уже есть у этого договора` });
    return;
  }

  let duplicates = 0;
  try {
    duplicates = await store.duplicateCount(cnnNumRaw);
  } catch {
    /* не блокируем */
  }

  const doAdd = async (): Promise<void> => {
    try {
      await store.addCnNum({
        cnKey,
        cnnNum: cnnNumRaw,
        cnnType: addNumDialog.cnnType
      });
      addNumDialog.open = false;
      $q.notify({ type: 'positive', message: 'Номер добавлен' });
    } catch {
      /* error в store */
    }
  };

  if (duplicates > 0) {
    addNumDialog.duplicateHint =
      `В БД уже есть ${duplicates} номер(ов) «${cnnNumRaw}» (часто это дубль воронки). ` +
      'Добавление к каноническому договору — ожидаемый сценарий объединения.';
    $q.dialog({
      title: 'Номер уже встречается',
      message:
        `В БД уже есть ${duplicates} записей с номером «${cnnNumRaw}». ` +
        'Добавить его как второй номер к текущему договору?',
      cancel: { flat: true, label: 'Отмена' },
      ok: { flat: true, color: 'primary', label: 'Добавить' }
    }).onOk(() => {
      void doAdd();
    });
    return;
  }

  await doAdd();
}

onMounted(() => {
  void store.loadCnNums();
});

/**
 * Список cnInv грузим лениво при открытии вкладки СФ (массовые договоры могут быть большими).
 */
watch(
  [() => store.selectedCn?.cnKey ?? null, detailTab],
  ([cnKey, tab]) => {
    if (tab === 'sf' && cnKey != null) {
      void store.loadCnInvs(cnKey);
    }
  }
);
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
.nested-table,
.cn-inv-table {
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
