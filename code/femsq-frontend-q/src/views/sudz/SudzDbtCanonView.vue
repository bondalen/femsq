<template>
  <QPage class="sudz-dbt-canon-view q-pa-md column no-wrap" data-test="sudz-dbt-canon-view">
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
            title="Долг (канон)"
            caption="СУДЗ · фильтр колонок → карточка Dbt · Долг / Слоты / Комментарии"
            :rows="store.candidates"
            :columns="candidateColumns"
            :loading="store.loading"
            :show-filter="false"
            :show-filter-count="true"
            show-column-filters
            v-model:filters-visible="candidatesFiltersVisible"
            column-filter-placeholder=""
            v-model:column-filters="columnFilters"
            v-model:pagination="pagination"
            v-model:selected="selectedRows"
            selection="single"
            data-test="sudz-dbt-canon-candidates"
            @request="onTableRequest"
            @row-click="onCandidateClick"
          >
            <template #actions>
              <QBtn
                flat
                dense
                no-caps
                label="Сброс"
                data-test="sudz-dbt-canon-reset"
                @click="onReset"
              />
            </template>
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
                    <FemsqWalkTree
                      v-if="store.detail"
                      class="fit"
                      :spec="canonWalkSpec"
                      :root-id="null"
                      :roots-token="canonRootsToken"
                      :fetch-node="fetchCanonNode"
                      :fetch-expand="fetchCanonExpand"
                      :fetch-query="fetchCanonQuery"
                      :fetch-roots="fetchCanonRoots"
                      v-model:selected-key="selectedTreeKey"
                      data-test="sudz-dbt-canon-tree"
                      root-class="sudz-dbt-canon-walk"
                      @action="onCanonWalkAction"
                      @update:selected-key="onTreeSelect"
                    />
                  </div>
                </template>
                <template #after>
                  <div class="chart-pane fill-pane">
                    <FemsqChart
                      :key="'dbt-chart-' + store.detail.dbtKey + '-' + (selectedPortfolioChain?.id ?? '')"
                      fill
                      class="fit"
                      :spec="chartSpec"
                      empty-label="Нет Value с датой выгрузки"
                      data-test="sudz-dbt-canon-chart"
                    >
                      <template v-if="portfolioChains.length" #zoom-extra>
                        <QSelect
                          v-model="selectedPortfolioChainId"
                          dense
                          outlined
                          emit-value
                          map-options
                          options-dense
                          :options="
                            portfolioChains.map((c) => ({
                              label: c.label,
                              value: c.id
                            }))
                          "
                          class="col"
                          style="min-width: 200px; max-width: 100%"
                          label="Цепь портфелей"
                          data-test="sudz-dbt-canon-chain-select"
                        />
                      </template>
                    </FemsqChart>
                  </div>
                </template>
              </QSplitter>
            </QTabPanel>
            <QTabPanel name="slots" class="q-pa-none fill-pane">
              <div class="fill-pane slots-pane">
                <div class="row q-gutter-sm q-mb-sm items-end shrink-0">
                  <QInput
                    v-model="linkInvNum"
                    dense
                    outlined
                    clearable
                    label="№ СФ"
                    style="min-width: 160px"
                    data-test="sudz-dbt-canon-link-inv"
                  />
                  <QInput
                    v-model="linkCnNum"
                    dense
                    outlined
                    clearable
                    label="№ договора"
                    style="min-width: 160px"
                    data-test="sudz-dbt-canon-link-cn"
                  />
                  <QBtn
                    outline
                    no-caps
                    label="Найти"
                    :loading="store.slotSearchLoading"
                    data-test="sudz-dbt-canon-link-find"
                    @click="onFindLinkSlots"
                  />
                  <QSelect
                    v-model="linkPickKey"
                    dense
                    outlined
                    emit-value
                    map-options
                    clearable
                    :options="linkHitOptions"
                    label="Слот"
                    style="min-width: 280px"
                    data-test="sudz-dbt-canon-link-pick"
                  />
                  <QBtn
                    color="primary"
                    outline
                    no-caps
                    label="Привязать слот"
                    :loading="store.loading"
                    :disable="!canLinkPick"
                    :title="linkPickTitle"
                    data-test="sudz-dbt-canon-link-btn"
                    @click="onLinkPick"
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
                <PmDocForest
                  v-if="selectedSlotRows[0]"
                  class="pm-doc-forest-pane"
                  :inv-key="selectedSlotRows[0].iKey"
                  @open-inv="onPmDocOpenInv"
                />
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
                    <FemsqWalkTree
                      v-if="store.detail"
                      class="fit"
                      :spec="canonWalkSpec"
                      :root-id="null"
                      :roots-token="canonRootsToken"
                      :fetch-node="fetchCanonNode"
                      :fetch-expand="fetchCanonExpand"
                      :fetch-query="fetchCanonQuery"
                      :fetch-roots="fetchCanonRoots"
                      v-model:selected-key="commentSelectedKey"
                      data-test="sudz-dbt-canon-comment-tree"
                      root-class="sudz-dbt-canon-walk-cmm"
                      @action="onCanonWalkAction"
                    />
                  </div>
                </template>
                <template #after>
                  <div class="comment-pane fill-pane q-pa-sm">
                    <div class="text-caption text-grey-7 q-mb-sm">
                      Дерево то же, что на вкладке «Долг»: слот и сумма выгрузки. Комментарий
                      относится к сумме. Выделите сумму и укажите группу в окне. Пустой текст строку
                      не удаляет.
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
      <QCard style="min-width: 480px" data-test="sudz-dbt-canon-split-dlg">
        <QCardSection class="text-subtitle1">Разделить сумму выгрузки</QCardSection>
        <QCardSection class="q-gutter-sm">
          <div class="text-body2" data-test="sudz-dbt-canon-split-slot">{{ splitSlotLabel }}</div>
          <QSelect
            :model-value="splitDlg.uplKey"
            dense
            outlined
            emit-value
            map-options
            :options="splitUplOptions"
            label="Выгрузка"
            data-test="sudz-dbt-canon-split-upl"
            @update:model-value="applySplitUpl"
          />
          <div v-for="(part, idx) in splitDlg.parts" :key="idx" class="row q-gutter-sm items-center">
            <QInput v-model="part.ttl" dense outlined label="Сумма доли" class="col" />
            <QInput v-model="part.overd" dense outlined label="Просрочено" class="col" />
            <QBtn flat dense icon="remove" :disable="splitDlg.parts.length < 2" @click="splitDlg.parts.splice(idx, 1)" />
          </div>
          <QBtn flat dense no-caps label="Добавить долю" @click="splitDlg.parts.push({ ttl: '', overd: '' })" />
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup data-test="sudz-dbt-canon-split-cancel" />
          <QBtn unelevated no-caps color="primary" label="Разделить" @click="submitSplit" />
        </QCardSection>
      </QCard>
    </QDialog>

    <QDialog v-model="mergeDlg.open">
      <QCard style="min-width: 480px" data-test="sudz-dbt-canon-merge-dlg">
        <QCardSection class="text-subtitle1">Слить</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QSelect
            v-model="mergeDlg.mode"
            dense
            outlined
            emit-value
            map-options
            :options="mergeModeOptions"
            label="Что слить"
            data-test="sudz-dbt-canon-merge-mode"
          />
          <template v-if="mergeDlg.mode === 'SHARES_ON_UPL'">
            <QSelect
              :model-value="mergeDlg.survivorSlotKey"
              dense
              outlined
              emit-value
              map-options
              :options="mergeSlotOptions"
              label="Слот, который остаётся"
              data-test="sudz-dbt-canon-merge-survivor"
              @update:model-value="applyMergeSurvivor"
            />
            <QSelect
              v-model="mergeDlg.slotKeys"
              dense
              outlined
              multiple
              emit-value
              map-options
              :options="mergeShareOptions"
              label="Доли этой СФ"
              data-test="sudz-dbt-canon-merge-shares"
            />
            <QSelect
              v-model="mergeDlg.uplKey"
              dense
              outlined
              emit-value
              map-options
              :options="mergeUplOptions"
              label="Выгрузка"
              data-test="sudz-dbt-canon-merge-upl"
            />
          </template>
          <template v-else>
            <div class="row q-gutter-sm items-end">
              <QInput v-model="mergeFindInv" dense outlined label="№ СФ" class="col" />
              <QInput v-model="mergeFindCn" dense outlined label="№ договора" class="col" />
              <QBtn outline no-caps label="Найти" :loading="store.slotSearchLoading" @click="onFindMergeSlots" />
            </div>
            <QSelect
              v-model="mergeDlg.slotKeys"
              dense
              outlined
              multiple
              emit-value
              map-options
              :options="mergeForeignOptions"
              label="Слоты других канонов"
              data-test="sudz-dbt-canon-merge-foreign"
            />
          </template>
        </QCardSection>
        <QCardSection align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup data-test="sudz-dbt-canon-merge-cancel" />
          <QBtn unelevated no-caps color="primary" label="Слить" @click="submitMerge" />
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
  QTd,
  useQuasar
} from 'quasar';
import {
  FemsqChart,
  FemsqTable,
  FemsqWalkTree,
  actionsColumn,
  formatMoney,
  moneyColumn,
  type FemsqTableColumn,
  type FemsqTableRequest,
  type FemsqWalkActionContext,
  type FemsqWalkTreeSpec
} from 'fequlib';

import { useSudzDbtCanonStore } from '@/stores/sudz-dbt-canon';
import PmDocForest from '@/components/sudz/PmDocForest.vue';
import type {
  SudzDbtCanonCandidate,
  SudzDbtCanonSlot,
  SudzDbtCanonValue,
  SudzDbtMergeMode,
  SudzInvDbtSlotPick
} from '@/types/sudz';
import {
  commentStubFromWalkNodeId,
  dbtCanonQueryRows,
  dbtCanonRootRows,
  dbtCanonRootsToken,
  slotKeyFromWalkNodeId,
  valueKeyFromWalkNodeId
} from '@/sudz/dbt-canon-tree';
import * as dbtCanonSpecJson from '@/trees/dbt-canon.tree.json';
import {
  buildCanonPortfolioChartSpec,
  readCanonChartColors
} from '@/utils/sudz-canon-chart';
import type { SudzDbtCanonPortfolioChain } from '@/types/sudz';
import {
  commentsFromSlots,
  type CanonCommentGroupKind,
  type CanonCommentTypeKind
} from '@/utils/sudz-canon-tree';

const canonWalkSpec = dbtCanonSpecJson as FemsqWalkTreeSpec;

const vClosePopup = ClosePopup;

const store = useSudzDbtCanonStore();

const linkInvNum = ref('');
const linkCnNum = ref('');
const linkHits = ref<SudzInvDbtSlotPick[]>([]);
const linkPickKey = ref<number | null>(null);
const mergeFindInv = ref('');
const mergeFindCn = ref('');
const mergeHits = ref<SudzInvDbtSlotPick[]>([]);

const columnFilters = ref<Record<string, string>>({});
/** Поколоночный поиск кандидатов открыт по умолчанию (server-criteria). */
const candidatesFiltersVisible = ref(true);
const selectedRows = ref<SudzDbtCanonCandidate[]>([]);
const selectedSlotRows = ref<SudzDbtCanonSlot[]>([]);
const selectedSlotKey = ref<number | null>(null);
const $q = useQuasar();

/**
 * На карточке долга отдельного дерева СФ нет: сообщаем ключ.
 */
function onPmDocOpenInv(invKey: number): void {
  $q.notify({ type: 'info', message: `Счёт-фактура inv=${invKey}` });
}
const selectedTreeKey = ref<string | number | null>(null);
/** Выбранная цепь портфелей для графика (id из portfolioChains). */
const selectedPortfolioChainId = ref<string | null>(null);
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
  slotKeys: [] as number[],
  survivorSlotKey: 0,
  uplKey: 0
});

const mergeModeOptions = [
  { label: 'Доли одной выгрузки', value: 'SHARES_ON_UPL' },
  { label: 'Несколько канонов', value: 'CANONS' }
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

const canonRootsToken = computed(() =>
  dbtCanonRootsToken(store.detail?.dbtKey, store.detail?.slots)
);

const canonComments = computed(() => commentsFromSlots(store.detail?.slots ?? []));

const selectedCommentStub = computed(() =>
  commentStubFromWalkNodeId(commentSelectedKey.value, store.detail?.slots ?? [])
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
  const fromValue = valueKeyFromWalkNodeId(commentSelectedKey.value);
  if (fromValue != null) {
    return fromValue;
  }
  return selectedCommentStub.value?.valueKey ?? null;
});

const commentEditorPlaceholder = computed(() => {
  if (commentLeafSelected.value) {
    return 'Текст комментария';
  }
  if (selectedCommentValueKey.value != null) {
    return 'Выделите DbtValue и нажмите «Комментарий» — группа выбирается в модалке';
  }
  return 'Выберите DbtValue в дереве';
});

/**
 * Лес слотов из карточки.
 */
async function fetchCanonRoots(queryId: string) {
  if (queryId !== 'sudz.dbtCanon.slots') {
    return [];
  }
  return dbtCanonRootRows(store.detail?.slots ?? []);
}

/**
 * Запись по таблице (лес не использует).
 */
async function fetchCanonNode(_table: string, _id: number) {
  return null;
}

/**
 * Рёбра не используются — только queryId.
 */
async function fetchCanonExpand(_edge: string, _fromId: number) {
  return [];
}

/**
 * Дети папок var / values / comments.
 */
async function fetchCanonQuery(queryId: string, fromId: number) {
  return dbtCanonQueryRows(queryId, fromId, store.detail?.slots ?? []);
}

/**
 * Действия WalkTree: Split / Merge / Value / комментарий.
 */
function onCanonWalkAction(context: FemsqWalkActionContext): void {
  const slotKey =
    context.node.table === 'invDbt'
      ? context.node.rowKey
      : slotKeyFromWalkNodeId(
          context.node.table && context.node.rowKey != null
            ? `${context.node.table}:${context.node.rowKey}`
            : null,
          store.detail?.slots ?? []
        );
  if (context.actionId === 'dbt.canon.split' && slotKey != null) {
    openSplit(slotKey);
    return;
  }
  if (context.actionId === 'dbt.canon.merge') {
    openMerge();
    return;
  }
  if (context.actionId === 'dbt.canon.value.add') {
    const fromFolder = context.node.fromId ?? slotKey;
    if (fromFolder != null) {
      openNewValue(fromFolder);
    }
    return;
  }
  if (context.actionId === 'dbt.canon.value.edit' && context.node.rowKey != null) {
    openEditValue(context.node.rowKey);
    return;
  }
  if (context.actionId === 'dbt.canon.value.delete' && context.node.rowKey != null) {
    onDeleteValue(context.node.rowKey);
    return;
  }
  if (context.actionId === 'dbt.canon.comment.add') {
    const vk = context.node.table === 'DbtValue' ? context.node.rowKey : null;
    openAddComment(vk ?? undefined);
  }
}

const portfolioChains = computed((): SudzDbtCanonPortfolioChain[] => {
  return store.detail?.portfolioChains ?? [];
});

const selectedPortfolioChain = computed((): SudzDbtCanonPortfolioChain | null => {
  const chains = portfolioChains.value;
  if (!chains.length) {
    return null;
  }
  const id = selectedPortfolioChainId.value;
  return chains.find((c) => c.id === id) ?? chains[0] ?? null;
});

watch(
  () => store.detail?.dbtKey,
  () => {
    const top = store.detail?.portfolioChains?.[0];
    selectedPortfolioChainId.value = top?.id ?? null;
  }
);

const chartSpec = computed(() =>
  store.detail
    ? buildCanonPortfolioChartSpec(
        store.detail.slots,
        selectedPortfolioChain.value,
        readCanonChartColors(),
        selectedSlotKey.value
      )
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
 * Дедуп одинаковых columnFilters — защита от цикла QTable @request ↔ pagination.
 *
 * @param request контракт FemsqTable
 */
let lastSearchFiltersKey = '';
function onTableRequest(request: FemsqTableRequest): void {
  const filters = request.columnFilters ?? {};
  const key = JSON.stringify(filters);
  if (key === lastSearchFiltersKey) {
    return;
  }
  lastSearchFiltersKey = key;
  void store.searchByColumnFilters(filters);
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
  selectedTreeKey.value = `invDbt:${row.slotKey}`;
}

/**
 * Выбор узла дерева → подсветка серии.
 *
 * @param key ключ узла WalkTree
 */
function onTreeSelect(key: string | number | null): void {
  const slots = store.detail?.slots ?? [];
  const slotKey = slotKeyFromWalkNodeId(key, slots);
  if (slotKey == null) {
    return;
  }
  selectedSlotKey.value = slotKey;
  const slot = slots.find((item) => item.slotKey === slotKey);
  selectedSlotRows.value = slot ? [slot] : [];
}

/**
 * Сброс фильтров таблицы и карточки.
 */
function onReset(): void {
  lastSearchFiltersKey = '';
  columnFilters.value = {};
  selectedRows.value = [];
  selectedSlotRows.value = [];
  selectedSlotKey.value = null;
  selectedTreeKey.value = null;
  commentDraft.value = '';
  commentSelectedKey.value = null;
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
 * @param valueKey ключ DbtValue
 */
function openEditValue(valueKey: number): void {
  const slots = store.detail?.slots ?? [];
  for (const slot of slots) {
    const value = slot.values.find((item) => item.valueKey === valueKey);
    if (!value) {
      continue;
    }
    valueDlg.slotKey = slot.slotKey;
    valueDlg.valueKey = value.valueKey;
    valueDlg.uplKey = value.uplKey;
    valueDlg.ttl = value.ttl != null ? String(value.ttl) : '';
    valueDlg.overd = value.overd != null ? String(value.overd) : '';
    valueDlg.open = true;
    return;
  }
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
 * Подпись слота для оператора: номер на СФ, номер СФ, договор.
 *
 * @param slot слот канона
 */
function slotCaption(slot: SudzDbtCanonSlot): string {
  return `№ ${slot.idNum} · СФ ${slot.invNum ?? '—'} · ${slot.cnNum ?? '—'}`;
}

/**
 * Подпись выгрузки: имя, дата и место относительно портфеля.
 *
 * @param value сумма слота
 */
function uplCaption(value: SudzDbtCanonValue): string {
  const name = value.uplName?.trim() || 'без имени';
  const date = value.uplStatusOnDate || value.uplDate || 'без даты';
  const place = value.portfolioLabels?.length
    ? value.portfolioLabels.join(', ')
    : 'вне портфеля';
  return `${value.uplKey} · ${name} · ${date} · ${place}`;
}

/**
 * Выгрузка слота из выбранной цепи портфелей, иначе любая внутри портфеля.
 *
 * @param slot слот
 */
function defaultUplKey(slot: SudzDbtCanonSlot | undefined): number {
  const values = slot?.values ?? [];
  if (!values.length) {
    return 0;
  }
  const chain = selectedPortfolioChain.value ?? portfolioChains.value[0];
  const chainKeys = new Set((chain?.upls ?? []).map((upl) => upl.uplKey));
  const inChain = values.find((value) => chainKeys.has(value.uplKey));
  if (inChain) {
    return inChain.uplKey;
  }
  const inPortfolio = values.find((value) => (value.portfolioLabels?.length ?? 0) > 0);
  return (inPortfolio ?? values[0]).uplKey;
}

/**
 * Делит сумму выбранной выгрузки пополам в поля долей.
 *
 * @param uplKey выгрузка
 */
function applySplitUpl(uplKey: number): void {
  splitDlg.uplKey = uplKey;
  const slot = store.detail?.slots.find((item) => item.slotKey === splitDlg.sourceSlotKey);
  const value = slot?.values.find((item) => item.uplKey === uplKey);
  const half = value?.ttl != null ? String(value.ttl / 2) : '';
  splitDlg.parts = [
    { ttl: half, overd: '' },
    { ttl: half, overd: '' }
  ];
}

const splitSlotLabel = computed(() => {
  const slot = store.detail?.slots.find((item) => item.slotKey === splitDlg.sourceSlotKey);
  return slot ? slotCaption(slot) : '';
});

const splitUplOptions = computed(() => {
  const slot = store.detail?.slots.find((item) => item.slotKey === splitDlg.sourceSlotKey);
  return (slot?.values ?? []).map((value) => ({ label: uplCaption(value), value: value.uplKey }));
});

const mergeSlotOptions = computed(() =>
  (store.detail?.slots ?? []).map((slot) => ({ label: slotCaption(slot), value: slot.slotKey }))
);

const mergeShareOptions = computed(() =>
  mergeSlotOptions.value.filter((option) => option.value !== mergeDlg.survivorSlotKey)
);

const mergeUplOptions = computed(() => {
  const slot = store.detail?.slots.find((item) => item.slotKey === mergeDlg.survivorSlotKey);
  return (slot?.values ?? []).map((value) => ({ label: uplCaption(value), value: value.uplKey }));
});

/**
 * Подпись найденного слота, с каноном, если мост уже есть.
 *
 * @param hit строка поиска
 */
function hitCaption(hit: SudzInvDbtSlotPick): string {
  const canon = hit.dbtKey != null ? ` · канон ${hit.dbtKey}` : '';
  return `№ ${hit.idNum} · СФ ${hit.invNum ?? '—'} · ${hit.cnNum ?? '—'}${canon}`;
}

const linkHitOptions = computed(() =>
  linkHits.value.map((hit) => ({ label: hitCaption(hit), value: hit.slotKey }))
);

const linkPick = computed(
  () => linkHits.value.find((hit) => hit.slotKey === linkPickKey.value) ?? null
);

const canLinkPick = computed(
  () => linkPick.value != null && linkPick.value.dbtKey !== store.detail?.dbtKey
);

const linkPickTitle = computed(() => {
  if (!linkPick.value) {
    return 'Сначала найдите слот';
  }
  if (linkPick.value.dbtKey === store.detail?.dbtKey) {
    return 'Слот уже на этом каноне';
  }
  return 'Привязать выбранный слот';
});

const mergeForeignOptions = computed(() =>
  mergeHits.value
    .filter((hit) => hit.dbtKey != null && hit.dbtKey !== store.detail?.dbtKey)
    .map((hit) => ({ label: hitCaption(hit), value: hit.slotKey }))
);

/**
 * Ищет слоты для привязки и оставляет выбор, если он ещё в списке.
 */
async function onFindLinkSlots(): Promise<void> {
  linkHits.value = await store.findSlots(linkInvNum.value, linkCnNum.value);
  if (!linkHits.value.some((hit) => hit.slotKey === linkPickKey.value)) {
    linkPickKey.value = linkHits.value[0]?.slotKey ?? null;
  }
}

/**
 * Привязывает выбранный слот. Уже стоящий на этом каноне не отправляет.
 */
function onLinkPick(): void {
  if (!canLinkPick.value || linkPickKey.value == null) {
    return;
  }
  void store.linkSlot(linkPickKey.value);
}

/**
 * Ищет чужие слоты для слияния канонов.
 */
async function onFindMergeSlots(): Promise<void> {
  mergeHits.value = await store.findSlots(mergeFindInv.value, mergeFindCn.value);
  const allowed = new Set(mergeForeignOptions.value.map((option) => option.value));
  mergeDlg.slotKeys = mergeDlg.slotKeys.filter((key) => allowed.has(key));
}

/**
 * Меняет остающийся слот и подставляет выгрузку из цепи портфелей.
 *
 * @param slotKey слот
 */
function applyMergeSurvivor(slotKey: number): void {
  mergeDlg.survivorSlotKey = slotKey;
  mergeDlg.slotKeys = mergeDlg.slotKeys.filter((key) => key !== slotKey);
  const slot = store.detail?.slots.find((item) => item.slotKey === slotKey);
  mergeDlg.uplKey = defaultUplKey(slot);
}

/**
 * Модалка разделения суммы выбранного слота.
 *
 * @param slotKey исходный слот
 */
function openSplit(slotKey: number): void {
  const slot = store.detail?.slots.find((item) => item.slotKey === slotKey);
  splitDlg.sourceSlotKey = slotKey;
  splitDlg.open = true;
  applySplitUpl(defaultUplKey(slot));
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
    store.error = 'Выберите выгрузку и укажите минимум две доли с суммой';
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
  const survivor = slots[0];
  mergeDlg.mode = 'SHARES_ON_UPL';
  mergeDlg.survivorSlotKey = survivor?.slotKey ?? 0;
  mergeDlg.slotKeys = slots.slice(1).map((slot) => slot.slotKey);
  mergeDlg.uplKey = defaultUplKey(survivor);
  mergeFindInv.value = '';
  mergeFindCn.value = '';
  mergeHits.value = [];
  mergeDlg.open = true;
}

/**
 * Выполнить Merge.
 */
function submitMerge(): void {
  if (!store.selectedDbtKey) {
    return;
  }
  const slotKeys = mergeDlg.slotKeys.filter((key) => Number.isFinite(key) && key > 0);
  if (!slotKeys.length) {
    store.error = 'Выберите слоты';
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
  () => mergeDlg.mode,
  (mode) => {
    if (!mergeDlg.open) {
      return;
    }
    if (mode === 'SHARES_ON_UPL') {
      mergeDlg.slotKeys = (store.detail?.slots ?? [])
        .map((slot) => slot.slotKey)
        .filter((key) => key !== mergeDlg.survivorSlotKey);
      return;
    }
    mergeDlg.slotKeys = [];
  }
);

watch(
  () => store.selectedDbtKey,
  (key) => {
    selectedRows.value =
      key == null ? [] : store.candidates.filter((row) => row.dbtKey === key);
  }
);

/** Выбор чекбоксом не вызывает @row-click — открываем карточку по v-model:selected. */
watch(selectedRows, (rows) => {
  const row = rows[0];
  if (row != null && row.dbtKey !== store.selectedDbtKey) {
    void store.openCanon(row.dbtKey);
  }
});

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
      selectedSlotRows.value = [];
      return;
    }
    const keepSelected = commentSelectedKey.value;
    const stillThere =
      keepSelected != null && commentStubFromWalkNodeId(keepSelected, detail.slots) != null;
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
    selectedTreeKey.value = first ? `invDbt:${first.slotKey}` : null;
  }
);

watch(commentSelectedKey, (key) => {
  const stub = commentStubFromWalkNodeId(key, store.detail?.slots ?? []);
  commentDraft.value = stub?.text ?? '';
});

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
