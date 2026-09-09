<template>
  <QPage class="sudz-dbt-canon-view q-pa-md column no-wrap" data-test="sudz-dbt-canon-view">
    <div class="row items-center q-mb-sm shrink-0">
      <div class="col">
        <div class="femsq-page-title">Долг (канон)</div>
        <div class="femsq-page-subtitle">
          СУДЗ · фильтр колонок → карточка Dbt · Долг / Слоты / Комментарии
        </div>
      </div>
      <QBtn
        flat
        dense
        no-caps
        label="Сброс"
        data-test="sudz-dbt-canon-reset"
        @click="onReset"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>
      {{ store.error }}
    </QBanner>

    <QSplitter
      v-model="mainSplit"
      horizontal
      :limits="[22, 70]"
      class="col canon-splitter"
      separator-class="sudz-canon-split-sep"
      data-test="sudz-dbt-canon-main-split"
    >
      <template #before>
        <section class="fill-pane candidates-pane" data-test="sudz-dbt-canon-search">
          <FemsqTable
            fill
            class="col"
            mode="server"
            row-key="dbtKey"
            :rows="store.candidates"
            :columns="candidateColumns"
            :loading="store.loading"
            :show-filter="false"
            :show-filter-count="true"
            show-column-filters
            column-filter-placeholder=""
            v-model:column-filters="columnFilters"
            v-model:pagination="pagination"
            v-model:selected="selectedRows"
            selection="single"
            data-test="sudz-dbt-canon-candidates"
            @request="onTableRequest"
            @row-click="onCandidateClick"
          >
            <template #no-data>
              <div class="text-grey-7 q-pa-md">
                Задайте фильтр в шапке колонки (обычно № СФ) — поиск на сервере
              </div>
            </template>
          </FemsqTable>
        </section>
      </template>
      <template #after>
        <section v-if="!store.detail" class="fill-pane text-grey-7 q-pa-md" data-test="sudz-dbt-canon-detail">
          Выберите канон в таблице
        </section>
        <div v-else class="fill-pane card-pane" data-test="sudz-dbt-canon-detail">
          <div class="row items-center q-mb-xs q-gutter-sm shrink-0">
            <div class="text-subtitle1">Канон Dbt {{ store.detail.dbtKey }}</div>
            <div class="text-caption text-grey-7">слотов: {{ store.detail.slots.length }}</div>
          </div>
          <QTabs
            v-model="cardTab"
            dense
            no-caps
            class="shrink-0"
            active-color="primary"
            indicator-color="primary"
            data-test="sudz-dbt-canon-tabs"
          >
            <QTab name="debt" label="Долг" data-test="sudz-dbt-canon-tab-debt" />
            <QTab name="slots" label="Слоты" data-test="sudz-dbt-canon-tab-slots" />
            <QTab name="comments" label="Комментарии" data-test="sudz-dbt-canon-tab-comments" />
          </QTabs>
          <QTabPanels v-model="cardTab" class="col card-tab-panels" animated>
            <QTabPanel name="debt" class="q-pa-none fill-pane">
              <QSplitter
                v-model="cardSplit"
                :limits="[28, 72]"
                class="fit canon-splitter"
                separator-class="sudz-canon-split-sep"
                data-test="sudz-dbt-canon-split"
              >
                <template #before>
                  <div class="tree-pane fill-pane">
                    <FemsqTree
                      fill
                      :nodes="treeNodes"
                      node-key="id"
                      v-model:expanded-keys="expandedKeys"
                      v-model:selected-key="selectedTreeKey"
                      data-test="sudz-dbt-canon-tree"
                      @update:selected-key="onTreeSelect"
                    >
                      <template #header="{ node }">
                        <span>{{ node.title }}</span>
                      </template>
                      <template #detail="{ node }">
                        <div class="row q-gutter-xs q-mt-xs">
                          <QBtn
                            v-if="node.kind === 'slot'"
                            dense
                            flat
                            no-caps
                            size="sm"
                            label="Split"
                            @click.stop="openSplit(node.slotKey)"
                          />
                          <QBtn
                            v-if="node.kind === 'slot'"
                            dense
                            flat
                            no-caps
                            size="sm"
                            label="Merge"
                            @click.stop="openMerge()"
                          />
                          <QBtn
                            v-if="node.kind === 'value' && node.valueKey == null"
                            dense
                            flat
                            no-caps
                            size="sm"
                            label="Добавить Value"
                            @click.stop="openNewValue(node.slotKey)"
                          />
                          <QBtn
                            v-if="node.kind === 'value' && node.valueKey != null"
                            dense
                            flat
                            no-caps
                            size="sm"
                            label="Править Value"
                            @click.stop="openEditValue(node)"
                          />
                          <QBtn
                            v-if="node.kind === 'value' && node.valueKey != null"
                            dense
                            flat
                            no-caps
                            size="sm"
                            color="negative"
                            label="Снять Value"
                            @click.stop="onDeleteValue(node.valueKey)"
                          />
                        </div>
                      </template>
                    </FemsqTree>
                  </div>
                </template>
                <template #after>
                  <div class="chart-pane fill-pane">
                    <FemsqChart
                      :key="'dbt-chart-' + store.detail.dbtKey"
                      fill
                      class="fit"
                      :spec="chartSpec"
                      empty-label="Нет Value с датой выгрузки"
                      data-test="sudz-dbt-canon-chart"
                    />
                  </div>
                </template>
              </QSplitter>
            </QTabPanel>
            <QTabPanel name="slots" class="q-pa-none fill-pane">
              <div class="fill-pane slots-pane">
                <div class="row q-gutter-sm q-mb-sm items-end shrink-0">
                  <QInput
                    v-model="store.linkSlotKey"
                    dense
                    outlined
                    clearable
                    label="slotKey (idKey) для привязки"
                    style="min-width: 200px"
                    data-test="sudz-dbt-canon-link-slot"
                  />
                  <QBtn
                    color="primary"
                    outline
                    no-caps
                    label="Привязать слот"
                    :loading="store.loading"
                    data-test="sudz-dbt-canon-link-btn"
                    @click="store.linkSlot()"
                  />
                </div>
                <FemsqTable
                  fill
                  class="col"
                  row-key="slotKey"
                  :rows="store.detail.slots"
                  :columns="slotColumns"
                  :show-filter="false"
                  :show-column-filters="false"
                  :show-filter-count="false"
                  hide-pagination
                  selection="single"
                  v-model:selected="selectedSlotRows"
                  data-test="sudz-dbt-canon-slots"
                  @row-click="onSlotRowClick"
                >
                  <template #body-cell-actions="slotProps">
                    <QTd :props="slotProps" auto-width>
                      <QBtn
                        flat
                        dense
                        no-caps
                        color="negative"
                        label="Отвязать"
                        :disable="slotProps.row.values.length > 0"
                        :title="
                          slotProps.row.values.length > 0
                            ? 'Сначала обработайте DbtValue'
                            : 'Отвязать слот'
                        "
                        @click.stop="store.unlinkSlot(slotProps.row.slotKey)"
                      />
                    </QTd>
                  </template>
                  <template #no-data>
                    <div class="text-grey-7 q-pa-sm">У канона нет слотов</div>
                  </template>
                </FemsqTable>
              </div>
            </QTabPanel>
            <QTabPanel name="comments" class="q-pa-none fill-pane">
              <QSplitter
                v-model="commentsSplit"
                :limits="[24, 70]"
                class="fit canon-splitter"
                separator-class="sudz-canon-split-sep"
                data-test="sudz-dbt-canon-comments-split"
              >
                <template #before>
                  <div class="tree-pane fill-pane">
                    <FemsqTree
                      fill
                      :nodes="commentTreeNodes"
                      node-key="id"
                      v-model:expanded-keys="commentExpandedKeys"
                      v-model:selected-key="commentSelectedKey"
                      data-test="sudz-dbt-canon-comment-tree"
                    >
                      <template #header="{ node }">
                        <span>{{ node.title }}</span>
                      </template>
                      <template #detail="{ node }">
                        <div v-if="isCommentValueNode(node)" class="q-mt-xs">
                          <QBtn
                            dense
                            flat
                            no-caps
                            size="sm"
                            label="Добавить комментарий"
                            @click.stop="openAddComment(node.valueKey)"
                          />
                        </div>
                      </template>
                    </FemsqTree>
                  </div>
                </template>
                <template #after>
                  <div class="comment-pane fill-pane q-pa-sm">
                    <div class="text-caption text-grey-7 q-mb-sm">
                      Дерево — тот же канон, что вкладка «Долг»: Dbt → слот → DbtValue, комментарий
                      висит на Value (не на группе года). Добавление: выделить Value → группа в
                      модалке. Save пишет в <code>cnInvCmm.cnicDv</code>; пустой текст не удаляет строку.
                    </div>
                    <div v-if="selectedCommentValueKey != null" class="row q-mb-sm shrink-0">
                      <QBtn
                        outline
                        dense
                        no-caps
                        color="primary"
                        label="Добавить комментарий"
                        data-test="sudz-dbt-canon-comment-add"
                        @click="openAddComment(selectedCommentValueKey)"
                      />
                    </div>
                    <QInput
                      v-model="commentDraft"
                      type="textarea"
                      outlined
                      autogrow
                      class="col comment-editor"
                      input-style="min-height: 12rem; white-space: pre-wrap;"
                      :disable="!commentLeafSelected"
                      :placeholder="commentEditorPlaceholder"
                      data-test="sudz-dbt-canon-comment-text"
                    />
                    <div class="row q-gutter-sm q-mt-sm shrink-0">
                      <QBtn
                        unelevated
                        no-caps
                        color="primary"
                        label="Сохранить"
                        :disable="!commentLeafSelected"
                        @click="saveCommentDraft"
                      />
                      <QBtn
                        outline
                        no-caps
                        label="Сбросить"
                        :disable="!commentLeafSelected"
                        @click="resetCommentDraft"
                      />
                      <QBtn
                        flat
                        no-caps
                        color="negative"
                        label="Удалить"
                        :disable="!commentLeafSelected"
                        @click="deleteSelectedComment"
                      />
                    </div>
                  </div>
                </template>
              </QSplitter>
            </QTabPanel>
          </QTabPanels>
        </div>
      </template>
    </QSplitter>

    <QDialog v-model="valueDlg.open">
      <QCard style="min-width: 360px">
        <QCardSection class="text-subtitle1">DbtValue</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model.number="valueDlg.uplKey" dense outlined type="number" label="uplKey" />
          <QInput v-model="valueDlg.ttl" dense outlined label="ttl" />
          <QInput v-model="valueDlg.overd" dense outlined label="overd (просрочено)" />
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn unelevated no-caps color="primary" label="Сохранить" @click="submitValue" />
        </QCardSection>
      </QCard>
    </QDialog>

    <QDialog v-model="splitDlg.open">
      <QCard style="min-width: 420px">
        <QCardSection class="text-subtitle1">Split на доли (эта upl)</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model.number="splitDlg.sourceSlotKey" dense outlined type="number" label="Исходный slotKey" />
          <QInput v-model.number="splitDlg.uplKey" dense outlined type="number" label="uplKey" />
          <div v-for="(part, idx) in splitDlg.parts" :key="idx" class="row q-gutter-sm items-center">
            <QInput v-model="part.ttl" dense outlined label="ttl доли" class="col" />
            <QInput v-model="part.overd" dense outlined label="overd" class="col" />
            <QBtn flat dense icon="remove" :disable="splitDlg.parts.length < 2" @click="splitDlg.parts.splice(idx, 1)" />
          </div>
          <QBtn flat dense no-caps label="Добавить долю" @click="splitDlg.parts.push({ ttl: '', overd: '' })" />
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn unelevated no-caps color="primary" label="Split" @click="submitSplit" />
        </QCardSection>
      </QCard>
    </QDialog>

    <QDialog v-model="mergeDlg.open">
      <QCard style="min-width: 420px">
        <QCardSection class="text-subtitle1">Merge</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QSelect
            v-model="mergeDlg.mode"
            dense
            outlined
            emit-value
            map-options
            :options="mergeModeOptions"
            label="Режим"
          />
          <QInput
            v-model="mergeDlg.slotKeysText"
            dense
            outlined
            label="slotKeys через запятую"
            hint="CANONS: слоты чужих канонов. SHARES: доли этой СФ"
          />
          <QInput v-model.number="mergeDlg.survivorSlotKey" dense outlined type="number" label="survivorSlotKey (для SHARES)" />
          <QInput v-model.number="mergeDlg.uplKey" dense outlined type="number" label="uplKey (для SHARES)" />
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn unelevated no-caps color="primary" label="Merge" @click="submitMerge" />
        </QCardSection>
      </QCard>
    </QDialog>

    <QDialog v-model="commentDlg.open">
      <QCard style="min-width: 360px" data-test="sudz-dbt-canon-comment-add-dlg">
        <QCardSection class="text-subtitle1">Комментарий к DbtValue</QCardSection>
        <QCardSection class="q-gutter-sm">
          <div class="text-caption text-grey-7">valueKey {{ commentDlg.valueKey ?? '—' }}</div>
          <QSelect
            v-if="commentDlgYearOptions.length > 1"
            v-model="commentDlg.yrKey"
            dense
            outlined
            emit-value
            map-options
            :options="commentDlgYearOptions"
            label="Год-вариант"
          />
          <div v-else-if="commentDlgYearOptions.length === 1" class="text-caption">
            {{ commentDlgYearOptions[0].label }}
          </div>
          <QSelect
            v-model="commentDlg.groupKind"
            dense
            outlined
            emit-value
            map-options
            :options="commentGroupOptions"
            label="Группа года"
          />
          <QSelect
            v-model="commentDlg.typeKind"
            dense
            outlined
            emit-value
            map-options
            :options="commentTypeOptions"
            label="Тип"
          />
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn unelevated no-caps color="primary" label="Создать" @click="submitAddComment" />
        </QCardSection>
      </QCard>
    </QDialog>

    <QDialog v-model="commentDeleteDlg">
      <QCard style="min-width: 320px">
        <QCardSection class="text-subtitle1">Удалить комментарий?</QCardSection>
        <QCardSection class="text-body2">Строка будет удалена из БД. Пустое сохранение текст не стирает этим действием.</QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn unelevated no-caps color="negative" label="Удалить" @click="confirmDeleteComment" />
        </QCardSection>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
/**
 * Экран канона Dbt: таблица, вкладки Долг / Слоты / Комментарии (S78).
 */
import { computed, reactive, ref, watch } from 'vue';
import {
  ClosePopup,
  QBanner,
  QBtn,
  QCard,
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
  QTd
} from 'quasar';
import {
  FemsqChart,
  FemsqTable,
  FemsqTree,
  actionsColumn,
  formatMoney,
  moneyColumn,
  type FemsqTableColumn,
  type FemsqTableRequest
} from 'fequlib';

import { useSudzDbtCanonStore } from '@/stores/sudz-dbt-canon';
import type {
  SudzDbtCanonCandidate,
  SudzDbtCanonSlot,
  SudzDbtMergeMode
} from '@/types/sudz';
import {
  buildCanonSlotAreasSpec,
  readCanonChartColors
} from '@/utils/sudz-canon-chart';
import {
  buildCanonCommentTreeNodes,
  buildCanonTreeNodes,
  commentTreeExpandedKeys,
  defaultExpandedKeys,
  commentsFromSlots,
  type CanonCommentGroupKind,
  type CanonCommentTypeKind,
  type CanonTreeNode
} from '@/utils/sudz-canon-tree';

const vClosePopup = ClosePopup;

const store = useSudzDbtCanonStore();

const columnFilters = ref<Record<string, string>>({});
const selectedRows = ref<SudzDbtCanonCandidate[]>([]);
const selectedSlotRows = ref<SudzDbtCanonSlot[]>([]);
const selectedSlotKey = ref<number | null>(null);
const selectedTreeKey = ref<string | number | null>(null);
const expandedKeys = ref<(string | number)[]>([]);
const pagination = ref({ page: 1, rowsPerPage: 0, sortBy: 'dbtKey', descending: false });
/** Верх: таблица канонов ≈ три строки. */
const mainSplit = ref(32);
/** Вкладка карточки. */
const cardTab = ref<'debt' | 'slots' | 'comments'>('debt');
/** Долг: дерево | график. */
const cardSplit = ref(42);
/** Комментарии: дерево | текст. */
const commentsSplit = ref(34);
const commentDraft = ref('');
const commentSelectedKey = ref<string | number | null>(null);
const commentExpandedKeys = ref<(string | number)[]>([]);
const commentDeleteDlg = ref(false);

const valueDlg = reactive({
  open: false,
  slotKey: 0,
  valueKey: null as number | null,
  uplKey: 0,
  ttl: '',
  overd: ''
});

const splitDlg = reactive({
  open: false,
  sourceSlotKey: 0,
  uplKey: 0,
  parts: [{ ttl: '', overd: '' }] as { ttl: string; overd: string }[]
});

const mergeDlg = reactive({
  open: false,
  mode: 'SHARES_ON_UPL' as SudzDbtMergeMode,
  slotKeysText: '',
  survivorSlotKey: 0,
  uplKey: 0
});

const mergeModeOptions = [
  { label: 'Доли на upl (SHARES_ON_UPL)', value: 'SHARES_ON_UPL' },
  { label: 'Каноны (CANONS)', value: 'CANONS' }
];

const commentDlg = reactive({
  open: false,
  valueKey: null as number | null,
  yrKey: null as number | null,
  groupKind: 'new' as CanonCommentGroupKind,
  typeKind: 'mery' as CanonCommentTypeKind
});

const commentGroupOptions = [
  { label: 'Официальная (yr_CmmGr)', value: 'official' },
  { label: 'Рабочая раунда (yr_CmmGr_New)', value: 'new' }
];

const commentTypeOptions = [
  { label: 'Мероприятия (тип 1)', value: 'mery' },
  { label: 'Куратор (тип 8)', value: 'curator' }
];

const treeNodes = computed(() => buildCanonTreeNodes(store.detail?.slots ?? []));

const commentTreeNodes = computed(() =>
  store.detail
    ? buildCanonCommentTreeNodes(store.detail.dbtKey, store.detail.slots)
    : []
);

const canonComments = computed(() => commentsFromSlots(store.detail?.slots ?? []));

const selectedCommentStub = computed(() =>
  canonComments.value.find((stub) => stub.id === String(commentSelectedKey.value ?? ''))
);

const commentDlgYearOptions = computed(() => {
  const valueKey = commentDlg.valueKey;
  if (valueKey == null || store.detail == null) {
    return [];
  }
  let uplKey: number | null = null;
  for (const slot of store.detail.slots) {
    const value = slot.values.find((item) => item.valueKey === valueKey);
    if (value) {
      uplKey = value.uplKey;
      break;
    }
  }
  if (uplKey == null) {
    return [];
  }
  return (store.detail.cmmYears ?? [])
    .filter((year) => uplKey != null && year.uplKeys.includes(uplKey))
    .map((year) => ({
      label: `${year.yrKey} · ${year.yrVariant ?? 'год'}`,
      value: year.yrKey
    }));
});

const commentLeafSelected = computed(() => selectedCommentStub.value != null);

const selectedCommentValueKey = computed(() => {
  const key = String(commentSelectedKey.value ?? '');
  const valMatch = /^val:(\d+)$/.exec(key);
  if (valMatch) {
    return Number(valMatch[1]);
  }
  return selectedCommentStub.value?.valueKey ?? null;
});

const commentEditorPlaceholder = computed(() => {
  if (commentLeafSelected.value) {
    return 'Текст комментария';
  }
  if (selectedCommentValueKey.value != null) {
    return 'Выделите DbtValue и нажмите «Добавить комментарий» — группа выбирается в модалке';
  }
  return 'Выберите DbtValue в дереве (не группу года)';
});

const chartSpec = computed(() =>
  store.detail
    ? buildCanonSlotAreasSpec(store.detail.slots, readCanonChartColors(), selectedSlotKey.value)
    : null
);

const candidateColumns: FemsqTableColumn<SudzDbtCanonCandidate>[] = [
  {
    name: 'dbtKey',
    label: 'dbtKey',
    field: 'dbtKey',
    align: 'right',
    sortable: true
  },
  {
    name: 'invNum',
    label: '№ СФ',
    field: 'invNum',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.invNum ?? '')
  },
  {
    name: 'cnNum',
    label: '№ договора',
    field: 'cnNum',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.cnNum ?? '')
  },
    {
      name: 'orgBuirg',
      label: 'БУиРГ',
      field: 'orgBuirg',
      align: 'right',
      sortable: true,
      filterValue: (row) => String(row.orgBuirg ?? '')
    },
    {
      name: 'orgName',
      label: 'Организация',
      field: 'orgName',
      align: 'left',
      sortable: true,
      filterValue: (row) => String(row.orgName ?? '')
    },
  {
    name: 'csoDate',
    label: 'Дата (ГГГГ-ММ-ДД)',
    field: 'csoDate',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.csoDate ?? '')
  },
  {
    name: 'idNum',
    label: '№ слота',
    field: (row) => row.idNumMin,
    align: 'right',
    sortable: true,
    format: (_value, row) => formatIdNumRange(row),
    filterValue: (row) => formatIdNumRange(row)
  },
  {
    name: 'slotCount',
    label: 'Слотов',
    field: 'slotCount',
    align: 'right',
    sortable: true,
    filterable: false
  },
  moneyColumn({
    name: 'lastTtlSum',
    label: '∑ last',
    field: 'lastTtlSum',
    filterable: false
  })
];

const slotColumns: FemsqTableColumn<SudzDbtCanonSlot>[] = [
  { name: 'slotKey', label: 'slot', field: 'slotKey', align: 'right' },
  { name: 'iKey', label: 'iKey', field: 'iKey', align: 'right' },
  { name: 'idNum', label: 'idNum', field: 'idNum', align: 'right' },
  {
    name: 'invNum',
    label: 'СФ',
    field: 'invNum',
    format: (value) => (value ? String(value) : '—')
  },
  {
    name: 'cnNum',
    label: 'Договор',
    field: 'cnNum',
    format: (value) => (value ? String(value) : '—')
  },
  {
    name: 'orgBuirg',
    label: 'БУиРГ',
    field: 'orgBuirg',
    align: 'right',
    format: (value) => (value != null ? String(value) : '—')
  },
  {
    name: 'csoDate',
    label: 'Дата',
    field: 'csoDate',
    format: (value) => (value ? String(value) : '—')
  },
  {
    name: 'accountNum',
    label: 'Счёт',
    field: 'accountNum',
    align: 'right',
    format: (value) => (value != null ? String(value) : '—')
  },
  {
    name: 'values',
    label: 'Value (upl:ttl)',
    field: 'values',
    sortable: false,
    format: (_value, row) => formatSlotValues(row)
  },
  actionsColumn()
];

/**
 * Диапазон idNum слотов кандидата.
 *
 * @param row кандидат
 */
function formatIdNumRange(row: SudzDbtCanonCandidate): string {
  if (row.idNumMin == null) {
    return '—';
  }
  if (row.idNumMax == null || row.idNumMin === row.idNumMax) {
    return String(row.idNumMin);
  }
  return `${row.idNumMin}…${row.idNumMax}`;
}

/**
 * Краткий список Value слота.
 *
 * @param slot слот канона
 */
function formatSlotValues(slot: SudzDbtCanonSlot): string {
  if (!slot.values.length) {
    return 'нет';
  }
  return slot.values
    .slice(0, 4)
    .map((item) => `${item.uplKey}:${formatMoney(item.ttl)}`)
    .join('; ');
}

/**
 * Серверный запрос по фильтрам колонок.
 *
 * @param request контракт FemsqTable
 */
function onTableRequest(request: FemsqTableRequest): void {
  void store.searchByColumnFilters(request.columnFilters ?? {});
}

/**
 * Открыть карточку выбранной строки.
 *
 * @param _evt событие
 * @param row кандидат
 */
function onCandidateClick(_evt: Event, row: SudzDbtCanonCandidate): void {
  selectedRows.value = [row];
  void store.openCanon(row.dbtKey);
}

/**
 * Выбор слота в таблице.
 *
 * @param _evt событие
 * @param row слот
 */
function onSlotRowClick(_evt: Event, row: SudzDbtCanonSlot): void {
  selectedSlotRows.value = [row];
  selectedSlotKey.value = row.slotKey;
  selectedTreeKey.value = `slot:${row.slotKey}`;
}

/**
 * Выбор узла дерева → подсветка серии.
 *
 * @param key ключ узла
 */
function onTreeSelect(key: string | number | null): void {
  if (key == null) {
    return;
  }
  const text = String(key);
  const slotMatch = /^slot:(\d+)$/.exec(text) ?? /^var:(\d+)$/.exec(text) ?? /^vals:(\d+)$/.exec(text);
  if (slotMatch) {
    selectedSlotKey.value = Number(slotMatch[1]);
    const slot = store.detail?.slots.find((s) => s.slotKey === selectedSlotKey.value);
    selectedSlotRows.value = slot ? [slot] : [];
    return;
  }
  const valMatch = /^val:(\d+)$/.exec(text);
  if (valMatch && store.detail) {
    const vk = Number(valMatch[1]);
    const slot = store.detail.slots.find((s) => s.values.some((v) => v.valueKey === vk));
    if (slot) {
      selectedSlotKey.value = slot.slotKey;
      selectedSlotRows.value = [slot];
    }
  }
}

/**
 * Сброс фильтров таблицы и карточки.
 */
function onReset(): void {
  columnFilters.value = {};
  selectedRows.value = [];
  selectedSlotRows.value = [];
  selectedSlotKey.value = null;
  selectedTreeKey.value = null;
  commentDraft.value = '';
  commentSelectedKey.value = null;
  commentExpandedKeys.value = [];
  store.resetFilters();
}

/**
 * Модалка новой Value.
 *
 * @param slotKey слот
 */
function openNewValue(slotKey: number): void {
  const slot = store.detail?.slots.find((s) => s.slotKey === slotKey);
  const last = slot?.values[0];
  valueDlg.slotKey = slotKey;
  valueDlg.valueKey = null;
  valueDlg.uplKey = last?.uplKey ?? 0;
  valueDlg.ttl = '';
  valueDlg.overd = '';
  valueDlg.open = true;
}

/**
 * Модалка правки Value.
 *
 * @param node узел дерева
 */
function openEditValue(node: CanonTreeNode): void {
  if (node.value == null || node.slotKey == null) {
    return;
  }
  valueDlg.slotKey = node.slotKey;
  valueDlg.valueKey = node.value.valueKey;
  valueDlg.uplKey = node.value.uplKey;
  valueDlg.ttl = node.value.ttl != null ? String(node.value.ttl) : '';
  valueDlg.overd = node.value.overd != null ? String(node.value.overd) : '';
  valueDlg.open = true;
}

/**
 * Сохранить Value.
 */
function submitValue(): void {
  const ttl = Number(String(valueDlg.ttl).replace(',', '.'));
  if (!valueDlg.uplKey || Number.isNaN(ttl)) {
    store.error = 'Укажите uplKey и ttl';
    return;
  }
  const overdRaw = String(valueDlg.overd).trim();
  const overd = overdRaw === '' ? null : Number(overdRaw.replace(',', '.'));
  valueDlg.open = false;
  void store.upsertValue({
    slotKey: valueDlg.slotKey,
    uplKey: valueDlg.uplKey,
    ttl,
    overd: overd != null && !Number.isNaN(overd) ? overd : null,
    valueKey: valueDlg.valueKey
  });
}

/**
 * Модалка Split.
 *
 * @param slotKey исходный слот
 */
function openSplit(slotKey: number): void {
  const slot = store.detail?.slots.find((s) => s.slotKey === slotKey);
  const last = slot?.values[0];
  const half = last?.ttl != null ? String(last.ttl / 2) : '';
  splitDlg.sourceSlotKey = slotKey;
  splitDlg.uplKey = last?.uplKey ?? 0;
  splitDlg.parts = [
    { ttl: half, overd: '' },
    { ttl: half, overd: '' }
  ];
  splitDlg.open = true;
}

/**
 * Выполнить Split.
 */
function submitSplit(): void {
  if (!store.selectedDbtKey) {
    return;
  }
  const parts = splitDlg.parts
    .map((p) => {
      const ttl = Number(String(p.ttl).replace(',', '.'));
      const overdRaw = String(p.overd).trim();
      const overd = overdRaw === '' ? null : Number(overdRaw.replace(',', '.'));
      return {
        ttl,
        overd: overd != null && !Number.isNaN(overd) ? overd : null
      };
    })
    .filter((p) => !Number.isNaN(p.ttl) && p.ttl > 0);
  if (parts.length < 2 || !splitDlg.uplKey) {
    store.error = 'Нужны uplKey и минимум две доли с ttl';
    return;
  }
  splitDlg.open = false;
  void store.splitCanon({
    dbtKey: store.selectedDbtKey,
    sourceSlotKey: splitDlg.sourceSlotKey,
    uplKey: splitDlg.uplKey,
    parts
  });
}

/**
 * Модалка Merge.
 */
function openMerge(): void {
  const slots = store.detail?.slots ?? [];
  mergeDlg.mode = 'SHARES_ON_UPL';
  mergeDlg.slotKeysText = slots.map((s) => s.slotKey).join(', ');
  mergeDlg.survivorSlotKey = slots[0]?.slotKey ?? 0;
  mergeDlg.uplKey = slots[0]?.values[0]?.uplKey ?? 0;
  mergeDlg.open = true;
}

/**
 * Выполнить Merge.
 */
function submitMerge(): void {
  if (!store.selectedDbtKey) {
    return;
  }
  const slotKeys = mergeDlg.slotKeysText
    .split(/[,;\s]+/)
    .map((s) => Number(s))
    .filter((n) => Number.isFinite(n) && n > 0);
  if (!slotKeys.length) {
    store.error = 'Укажите slotKeys';
    return;
  }
  mergeDlg.open = false;
  void store.mergeCanon({
    mode: mergeDlg.mode,
    survivorDbtKey: store.selectedDbtKey,
    slotKeys,
    survivorSlotKey: mergeDlg.survivorSlotKey || null,
    uplKey: mergeDlg.uplKey || null
  });
}

watch(
  () => store.selectedDbtKey,
  (key) => {
    selectedRows.value =
      key == null ? [] : store.candidates.filter((row) => row.dbtKey === key);
  }
);

/**
 * Снять Value (кнопка дерева).
 *
 * @param valueKey ключ или undefined
 */
function onDeleteValue(valueKey: number | undefined): void {
  if (valueKey == null) {
    return;
  }
  void store.deleteValue(valueKey);
}

watch(
  () => store.detail,
  (detail) => {
    if (!detail) {
      commentDraft.value = '';
      commentSelectedKey.value = null;
      selectedSlotKey.value = null;
      selectedTreeKey.value = null;
      expandedKeys.value = [];
      commentExpandedKeys.value = [];
      selectedSlotRows.value = [];
      return;
    }
    const nodes = buildCanonTreeNodes(detail.slots);
    expandedKeys.value = defaultExpandedKeys(nodes);
    const commentNodes = buildCanonCommentTreeNodes(detail.dbtKey, detail.slots);
    commentExpandedKeys.value = commentTreeExpandedKeys(commentNodes);
    const keepSelected = commentSelectedKey.value;
    const stillThere =
      keepSelected != null &&
      commentsFromSlots(detail.slots).some((item) => item.id === String(keepSelected));
    if (!stillThere) {
      commentSelectedKey.value = null;
      commentDraft.value = '';
    }
    const keep =
      selectedSlotKey.value == null
        ? undefined
        : detail.slots.find((slot) => slot.slotKey === selectedSlotKey.value);
    const first = keep ?? detail.slots[0];
    selectedSlotKey.value = first?.slotKey ?? null;
    selectedSlotRows.value = first ? [first] : [];
    selectedTreeKey.value = first ? `slot:${first.slotKey}` : null;
  }
);

watch(commentSelectedKey, (key) => {
  const stub = canonComments.value.find((item) => item.id === String(key ?? ''));
  commentDraft.value = stub?.text ?? '';
});

/**
 * Узел DbtValue (не папка vals:), к которому можно повесить cmm.
 *
 * @param node узел дерева комментариев
 */
function isCommentValueNode(node: CanonTreeNode): boolean {
  return node.kind === 'value' && node.valueKey != null;
}

/**
 * Модалка: группа года + тип для выбранного DbtValue.
 *
 * @param valueKey ключ Value
 */
function openAddComment(valueKey: number | undefined): void {
  if (valueKey == null) {
    return;
  }
  commentDlg.valueKey = valueKey;
  commentDlg.groupKind = 'new';
  commentDlg.typeKind = 'mery';
  let uplKey: number | null = null;
  for (const slot of store.detail?.slots ?? []) {
    const value = slot.values.find((item) => item.valueKey === valueKey);
    if (value) {
      uplKey = value.uplKey;
      break;
    }
  }
  const years = (store.detail?.cmmYears ?? []).filter(
    (year) => uplKey != null && year.uplKeys.includes(uplKey)
  );
  const withNew = years.find((year) => year.cmmGrNew != null) ?? years[0];
  commentDlg.yrKey = withNew?.yrKey ?? null;
  if (withNew?.cmmGrNew == null) {
    commentDlg.groupKind = 'official';
  }
  commentDlg.open = true;
}

/**
 * Создать комментарий в БД (пустой текст; Save допишет).
 */
async function submitAddComment(): Promise<void> {
  const valueKey = commentDlg.valueKey;
  if (valueKey == null) {
    return;
  }
  const year = store.detail?.cmmYears?.find((item) => item.yrKey === commentDlg.yrKey);
  const cmmGrKey =
    commentDlg.groupKind === 'new' ? year?.cmmGrNew ?? null : year?.cmmGr ?? null;
  if (cmmGrKey == null) {
    store.error =
      commentDlg.groupKind === 'new'
        ? 'У года нет yr_CmmGr_New'
        : 'Не выбран год-вариант или нет yr_CmmGr';
    commentDlg.open = false;
    return;
  }
  const cnicType = commentDlg.typeKind === 'curator' ? 8 : 1;
  const duplicate = canonComments.value.some(
    (stub) =>
      stub.valueKey === valueKey &&
      stub.cmmGrKey === cmmGrKey &&
      stub.typeKind === commentDlg.typeKind
  );
  if (duplicate) {
    store.error = 'На этой DbtValue уже есть комментарий этой группы и типа';
    commentDlg.open = false;
    return;
  }
  commentDlg.open = false;
  await store.upsertComment({
    valueKey,
    cmmGrKey,
    cnicType,
    text: ''
  });
  const created = commentsFromSlots(store.detail?.slots ?? []).find(
    (item) =>
      item.valueKey === valueKey &&
      item.cmmGrKey === cmmGrKey &&
      item.typeKind === commentDlg.typeKind
  );
  commentSelectedKey.value = created?.id ?? `val:${valueKey}`;
  commentDraft.value = created?.text ?? '';
}

/**
 * Записать черновик в БД (пустой текст остаётся строкой).
 */
async function saveCommentDraft(): Promise<void> {
  const current = selectedCommentStub.value;
  if (current?.cmmKey == null || current.cmmGrKey == null) {
    return;
  }
  await store.upsertComment({
    valueKey: current.valueKey,
    cmmGrKey: current.cmmGrKey,
    cnicType: current.typeKind === 'curator' ? 8 : 1,
    text: commentDraft.value
  });
  commentSelectedKey.value = `cmm:${current.cmmKey}`;
}

/**
 * Вернуть текст из карточки.
 */
function resetCommentDraft(): void {
  commentDraft.value = selectedCommentStub.value?.text ?? '';
}

/**
 * Подтверждение удаления комментария.
 */
function deleteSelectedComment(): void {
  if (selectedCommentStub.value?.cmmKey == null) {
    return;
  }
  commentDeleteDlg.value = true;
}

/**
 * Удалить комментарий после подтверждения.
 */
async function confirmDeleteComment(): Promise<void> {
  const current = selectedCommentStub.value;
  commentDeleteDlg.value = false;
  if (current?.cmmKey == null) {
    return;
  }
  const valueKey = current.valueKey;
  await store.deleteComment(current.cmmKey);
  commentSelectedKey.value = `val:${valueKey}`;
  commentDraft.value = '';
}
</script>

<style scoped>
.sudz-dbt-canon-view {
  height: 100%;
  max-height: 100%;
  overflow: hidden;
  --sudz-canon-row-h: 32px;
}
.canon-splitter {
  min-height: 0;
  min-width: 0;
}
.sudz-dbt-canon-view > .canon-splitter {
  flex: 1 1 auto;
  height: 0;
}
.canon-splitter :deep(.q-splitter__panel) {
  overflow: hidden;
}
.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.candidates-pane {
  min-height: calc(var(--sudz-canon-row-h) * 3 + 6rem);
}
.slots-pane {
  min-height: calc(var(--sudz-canon-row-h) * 3 + 7.5rem);
}
.card-pane {
  min-height: 0;
}
.card-tab-panels {
  min-height: 0;
}
.card-tab-panels :deep(.q-tab-panel) {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}
.comment-pane {
  min-width: 0;
}
.comment-editor {
  min-height: 0;
}
.tree-pane,
.chart-pane {
  min-width: 0;
}
:deep(.sudz-canon-split-sep) {
  background: var(--femsq-primary);
  opacity: 0.55;
}
.canon-splitter :deep(.q-splitter--horizontal > .q-splitter__separator),
:deep(.q-splitter.q-splitter--horizontal > .q-splitter__separator) {
  height: 6px;
}
:deep(.q-splitter.q-splitter--vertical > .q-splitter__separator) {
  width: 6px;
}
</style>
