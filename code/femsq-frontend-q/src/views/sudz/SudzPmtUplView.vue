<template>
  <!-- absolute-full: высота = область между header/footer; без calc(100vh) — нет лишнего скролла страницы -->
  <QPage class="q-pa-none" data-test="sudz-pmt-upl-view">
    <div class="absolute-full q-pa-md column no-wrap sudz-pmt-upl-view">
    <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
      <div class="text-h6 col">Загрузка платежей</div>
      <QBtn
        color="primary"
        unelevated
        no-caps
        dense
        icon="add"
        label="Выгрузка"
        data-test="sudz-pmt-upl-create"
        @click="openCreateDialog"
      />
      <QBtn
        flat
        dense
        no-caps
        icon="refresh"
        label="Обновить"
        :loading="store.loading"
        data-test="sudz-pmt-upl-refresh"
        @click="store.loadUpls()"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm shrink-0" rounded dense>
      {{ store.error }}
    </QBanner>

    <!-- Список ↔ детали (тянущийся разделитель) -->
    <QSplitter
      v-model="listSplit"
      horizontal
      :limits="[15, 60]"
      separator-class="sudz-split-sep"
      class="sudz-main-splitter"
      data-test="sudz-pmt-upl-main-splitter"
    >
      <template #before>
        <section class="fill-pane column no-wrap" data-test="sudz-pmt-upl-list-pane">
          <QCard flat bordered class="fill-pane column no-wrap">
            <QCardSection class="q-pa-none col column no-wrap min-h-0">
              <FemsqTable
                class="sudz-upl-table col"
                root-class="sudz-upl-table"
                :rows="store.upls"
                :columns="uplColumns"
                row-key="pmKey"
                dense
                flat
                :loading="store.loading"
                selection="single"
                v-model:selected="selectedRows"
                hide-bottom
                :rows-per-page-options="[0]"
                data-test="sudz-pmt-upl-table"
                @row-click="onUplClick"
              />
            </QCardSection>
            <QCardSection class="q-py-xs q-px-sm shrink-0 text-caption">
              <template v-if="store.selectedUpl">
                <span data-test="sudz-pmt-upl-header">
                  Выбрано:
                  {{ formatDate(store.selectedUpl.date) }}
                  ·
                  {{ store.selectedUpl.name || '—' }}
                  <span class="text-grey-7">(pm_key={{ store.selectedUpl.pmKey }})</span>
                </span>
              </template>
              <span v-else class="text-grey-7">Выберите выгрузку в списке.</span>
            </QCardSection>
          </QCard>
        </section>
      </template>

      <template #after>
        <section v-if="!store.selectedUpl" class="fill-pane flex flex-center text-grey-6">
          Выберите выгрузку сверху — откроется панель загрузки и ход.
        </section>

        <!-- Управление ↔ ход загрузки -->
        <QSplitter
          v-else
          v-model="detailSplit"
          horizontal
          :limits="[20, 80]"
          separator-class="sudz-split-sep"
          class="sudz-detail-splitter fill-pane"
          data-test="sudz-pmt-upl-detail-splitter"
        >
          <template #before>
            <QCard flat bordered class="fill-pane column no-wrap">
              <QTabs
                v-model="mainTab"
                dense
                class="text-primary shrink-0"
                active-color="primary"
                indicator-color="primary"
                align="left"
              >
                <QTab name="load" label="загрузка" data-test="sudz-pmt-upl-tab-load" />
                <QTab name="acc" label="счета, сумма" disable data-test="sudz-pmt-upl-tab-acc" />
              </QTabs>
              <QSeparator />

              <QTabPanels v-model="mainTab" animated class="col min-h-0 sudz-tab-panels">
                <QTabPanel name="load" class="q-pa-sm column no-wrap fill-pane">
                  <div class="row q-col-gutter-sm items-center q-mb-xs shrink-0">
                    <div class="col">
                      <QInput
                        v-model="pathDraft"
                        dense
                        outlined
                        label="Файл"
                        hint="Путь как в Проводнике; сохраняется в БД по blur / Enter."
                        hint-persistent
                        :disable="!store.selectedUpl"
                        :loading="store.saving"
                        data-test="sudz-pmt-upl-file-name"
                        @blur="onPathCommit"
                        @keyup.enter="onPathCommit"
                      />
                    </div>
                    <div class="col-auto" style="min-width: 10rem">
                      <QInput
                        v-model="sheetDraft"
                        dense
                        outlined
                        label="лист"
                        hint="cipufSheet"
                        hint-persistent
                        :disable="!store.selectedUpl"
                        :loading="store.saving"
                        data-test="sudz-pmt-upl-sheet"
                        @blur="onSheetCommit"
                        @keyup.enter="onSheetCommit"
                      />
                    </div>
                  </div>
                  <div class="row q-col-gutter-sm items-center q-mb-sm shrink-0">
                    <div class="col-auto">
                      <QToggle
                        :model-value="flLoad"
                        label="Обновлять"
                        dense
                        :disable="!store.selectedUpl || store.saving"
                        data-test="sudz-pmt-upl-fl-load"
                        @update:model-value="(v) => store.patchFileFlags({ flLoad: !!v })"
                      />
                    </div>
                    <div class="col-auto">
                      <QToggle
                        :model-value="flTbl"
                        label="обнов. по исх?"
                        dense
                        :disable="!store.selectedUpl || store.saving"
                        data-test="sudz-pmt-upl-fl-tbl"
                        @update:model-value="(v) => store.patchFileFlags({ flTbl: !!v })"
                      />
                    </div>
                    <div class="col-auto">
                      <QBtn
                        color="primary"
                        unelevated
                        no-caps
                        dense
                        label="загрузка"
                        :disable="!store.selectedUpl || store.funnelRunning || store.saving"
                        :loading="store.funnelRunning"
                        data-test="sudz-pmt-upl-run"
                        @click="onRunLoad"
                      />
                    </div>
                  </div>

                  <QSeparator class="q-mb-sm shrink-0" />

                  <div class="text-subtitle2 q-mb-xs shrink-0">Шаги (префикс цепочки)</div>
                  <div
                    class="sudz-funnel-scroll shrink-0"
                    data-test="sudz-pmt-upl-funnel-steps"
                  >
                    <table class="sudz-funnel-table">
                      <thead>
                        <tr>
                          <th
                            v-for="(step, idx) in funnelSteps"
                            :key="`chk-${step.id}`"
                            :title="step.id"
                          >
                            <QCheckbox
                              dense
                              :model-value="isStepChecked(idx)"
                              :data-test="`sudz-pmt-upl-step-${step.id}`"
                              @update:model-value="(v) => onStepToggle(idx, !!v)"
                            />
                          </th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td
                            v-for="step in funnelSteps"
                            :key="`cap-${step.id}`"
                            :title="step.id"
                          >
                            <div class="sudz-funnel-caption">{{ step.titleRu }}</div>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                  <div class="text-caption text-grey-7 q-mt-xs shrink-0">
                    Включён префикс из {{ selectedStepIds.length }} шагов · Excel→Tbl — «обнов. по исх?».
                    Кнопка «загрузка» — воронка 0074 (Excel→Tbl + stub cipu*). Наведите на ячейку — id
                    процедуры.
                  </div>
                </QTabPanel>
              </QTabPanels>
            </QCard>
          </template>

          <template #after>
            <QCard flat bordered class="fill-pane column no-wrap" data-test="sudz-pmt-upl-bottom">
              <QTabs
                v-model="subTab"
                dense
                class="text-primary shrink-0"
                active-color="primary"
                indicator-color="primary"
                align="left"
              >
                <QTab name="progress" label="ход загрузки" data-test="sudz-pmt-upl-tab-progress" />
                <QTab name="doubles" data-test="sudz-pmt-upl-tab-doubles">
                  <div class="row items-center no-wrap">
                  <span>повторяющиеся СФ</span>
                  <QBadge
                    class="q-ml-xs"
                    :color="badgeColor(sfWorkOpenCount)"
                    :label="badgeText(sfWorkOpenCount, store.sfDoublesLoading && store.badges == null)"
                    data-test="sudz-pmt-upl-badge-sf-open"
                  />
                  <QBadge
                    class="q-ml-xs"
                    outline
                    :color="badgeColor(store.badges?.invNot)"
                    :label="'Inv ' + badgeText(store.badges?.invNot, store.badgesLoading)"
                    data-test="sudz-pmt-upl-badge-inv-not"
                  />
                  <QBadge
                    class="q-ml-xs"
                    outline
                    :color="badgeColor(store.badges?.twoLoad)"
                    :label="'Two ' + badgeText(store.badges?.twoLoad, store.badgesLoading)"
                    data-test="sudz-pmt-upl-badge-two-load"
                  />
                  </div>
                </QTab>
                <QTab name="cst-new" data-test="sudz-pmt-upl-tab-cst-new">
                  <div class="row items-center no-wrap">
                  <span>стройки новые</span>
                  <QBadge
                    class="q-ml-xs"
                    :color="badgeColor(cstNewCount)"
                    :label="badgeText(cstNewCount, store.cstNewLoading && store.badges == null)"
                    data-test="sudz-pmt-upl-badge-cst-new"
                  />
                  </div>
                </QTab>
              </QTabs>
              <QSeparator />

              <QTabPanels v-model="subTab" animated class="col min-h-0 sudz-tab-panels">
                <QTabPanel name="progress" class="q-pa-none fill-pane">
                  <div
                    v-if="progressHtml"
                    ref="progressPane"
                    class="sudz-pmt-upl-progress q-pa-sm"
                    data-test="sudz-pmt-upl-progress"
                    v-html="progressHtml"
                  />
                  <div
                    v-else
                    class="text-grey-6 q-pa-sm"
                    data-test="sudz-pmt-upl-progress-empty"
                  >
                    Лог хода пуст (заполнится при «загрузка» / воронке).
                  </div>
                </QTabPanel>

                <QTabPanel name="doubles" class="q-pa-none fill-pane column no-wrap">
                  <div class="row items-center q-px-sm q-py-xs q-gutter-sm shrink-0">
                    <QBtnToggle
                      v-model="doublesFilter"
                      dense
                      unelevated
                      toggle-color="primary"
                      :options="doublesFilterOptions"
                      data-test="sudz-pmt-upl-doubles-filter"
                    />
                    <div class="text-caption text-grey-7">
                      {{ sfWorkFilteredRows.length }} из {{ sfWorkRows.length }}
                      · Inv {{ store.badges?.invNot ?? store.invNot.length }}
                      · Two {{ store.badges?.twoLoad ?? store.twoLoad.length }}
                    </div>
                    <QSpace />
                    <QBtn
                      flat
                      dense
                      no-caps
                      color="primary"
                      label="Разбор повторяющихся СФ…"
                      :disable="!sfWorkOpenCount"
                      :loading="store.sfDoublesLoading"
                      data-test="sudz-pmt-upl-open-sf-double"
                      @click="openSfDouble"
                    />
                  </div>
                  <FemsqTable
                    class="col"
                    :rows="sfWorkFilteredRows"
                    :columns="sfWorkColumns"
                    row-key="ciusKey"
                    dense
                    flat
                    :loading="
                      store.sfDoublesLoading || store.invNotLoading || store.twoLoadLoading
                    "
                    selection="single"
                    v-model:selected="sfWorkSelected"
                    data-test="sudz-pmt-upl-sf-work"
                  />
                  <div
                    v-if="!sfWorkRows.length && !store.sfDoublesLoading"
                    class="text-grey-6 q-pa-sm shrink-0"
                    data-test="sudz-pmt-upl-sf-work-empty"
                  >
                    Очередь пуста (InvNot/TwoLoad → sync при выборе пакета).
                  </div>
                </QTabPanel>

                <QTabPanel name="cst-new" class="q-pa-none fill-pane column no-wrap">
                  <QSplitter
                    v-model="cstSplit"
                    :limits="[25, 70]"
                    separator-class="sudz-split-sep"
                    class="sudz-cst-splitter"
                    data-test="sudz-pmt-upl-cst-split"
                  >
                    <template #before>
                      <div class="fill-pane column no-wrap">
                        <FemsqTable
                          class="col"
                          :rows="store.cstNew"
                          :columns="cstNewColumns"
                          row-key="cacOrNull"
                          dense
                          flat
                          :loading="store.cstNewLoading"
                          selection="single"
                          v-model:selected="cstSelected"
                          hide-bottom
                          :rows-per-page-options="[0]"
                          data-test="sudz-pmt-upl-cst-new"
                        />
                        <div
                          v-if="!store.cstNewLoading && store.cstNew.length === 0"
                          class="text-grey-6 q-pa-sm shrink-0"
                          data-test="sudz-pmt-upl-cst-new-empty"
                        >
                          Новых строек нет.
                        </div>
                      </div>
                    </template>
                    <template #after>
                      <div class="fill-pane column no-wrap" data-test="sudz-pmt-upl-cst-tree-pane">
                        <div
                          v-if="!selectedCst"
                          class="text-grey-6 q-pa-sm"
                          data-test="sudz-pmt-upl-cst-tree-pick"
                        >
                          Выберите строку очереди.
                        </div>
                        <div
                          v-else-if="store.cstMatchLoading"
                          class="text-grey-6 q-pa-sm"
                          data-test="sudz-pmt-upl-cst-tree-loading"
                        >
                          Ищем стройки с хвостом {{ selectedCst.sh }}…
                        </div>
                        <div
                          v-else-if="store.cstMatch.length === 0"
                          class="q-pa-sm"
                          data-test="sudz-pmt-upl-cst-tree-empty"
                        >
                          <div class="text-grey-8">
                            Стройки с хвостом {{ selectedCst.sh }} в каталоге нет.
                            Создайте стройку на экране «Стройки».
                          </div>
                          <QBtn
                            class="q-mt-sm"
                            flat
                            dense
                            no-caps
                            color="primary"
                            label="Стройки"
                            data-test="sudz-pmt-upl-cst-open-sites"
                            @click="openConstructionSites"
                          />
                        </div>
                        <FemsqWalkTree
                          v-else
                          class="col"
                          :spec="cstMatchSpec"
                          :root-id="null"
                          :roots-token="cstRootsToken"
                          :fetch-node="fetchCstMatchNode"
                          :fetch-expand="fetchCstMatchExpand"
                          :fetch-query="fetchCstMatchQuery"
                          :fetch-roots="fetchCstMatchRoots"
                          data-test="sudz-pmt-upl-cst-tree"
                          root-class="sudz-pmt-upl-cst-walk"
                          @action="onCstWalkAction"
                        />
                      </div>
                    </template>
                  </QSplitter>
                </QTabPanel>
              </QTabPanels>
            </QCard>
          </template>
        </QSplitter>
      </template>
    </QSplitter>
    </div>

    <QDialog v-model="createDialog.open" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-subtitle1">Новая выгрузка платежей</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="createDialog.name" dense outlined label="имя" />
          <QInput v-model="createDialog.date" dense outlined type="date" label="дата" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать"
            :loading="store.saving"
            data-test="sudz-pmt-upl-create-submit"
            @click="onCreateUpl"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="agentDialog.open" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-subtitle1">Агент стройки</QCardSection>
        <QCardSection class="q-gutter-sm">
          <div>{{ agentDialog.cstName }}</div>
          <div v-if="agentDialog.options.length === 0" class="text-negative" data-test="sudz-pmt-upl-agent-missing">
            Агента с кодом {{ agentDialog.code }} в каталоге нет. Нового агента здесь не создают.
          </div>
          <QSelect
            v-else
            v-model="agentDialog.cstaAg"
            dense
            outlined
            emit-value
            map-options
            label="агент"
            :options="agentDialog.options"
            :hint="`подсказка по коду ${agentDialog.code}`"
            data-test="sudz-pmt-upl-agent-select"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Добавить"
            :disable="agentDialog.cstaAg == null"
            :loading="cstActionBusy"
            data-test="sudz-pmt-upl-agent-submit"
            @click="saveAgent"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="pointDialog.open" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-subtitle1">Код САК</QCardSection>
        <QCardSection class="q-gutter-sm">
          <div>{{ pointDialog.agentLabel }}</div>
          <QInput
            :model-value="pointDialog.code"
            dense
            outlined
            readonly
            label="код"
            data-test="sudz-pmt-upl-point-code"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Добавить"
            :disable="!pointDialog.code || cstActionBusy"
            :loading="cstActionBusy"
            data-test="sudz-pmt-upl-point-submit"
            @click="savePoint"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
import {
  QBadge,
  QBanner,
  QBtn,
  QBtnToggle,
  QCard,
  QCardActions,
  QCardSection,
  QCheckbox,
  QDialog,
  QInput,
  QPage,
  QSelect,
  QSeparator,
  QSpace,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QToggle,
  useQuasar
} from 'quasar';
import { FemsqTable, FemsqWalkTree, type FemsqTableColumn, type FemsqWalkActionContext, type FemsqWalkTreeSpec } from 'fequlib';

import { createCstAgent, createCstAgPoint, getOgAgCsLookups } from '@/api/construction-sites-api';
import { useConnectionStore } from '@/stores/connection';
import { useSudzPmtUplStore } from '@/stores/sudz-pmt-upl';
import { useSudzSfDoubleSessionStore } from '@/stores/sudz-sf-double-session';
import {
  lookupsForAgentCode,
  pmtCstMatchQueryRows,
  pmtCstMatchRootRows,
  pmtCstMatchRootsToken,
  queueAgentCode
} from '@/sudz/pmt-cst-match-tree';
import * as cstMatchSpecJson from '@/trees/pmt-cst-match.tree.json';
import {
  SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS,
  SUDZ_PMT_UPL_FUNNEL_STEPS,
  pmtFunnelPrefixIds
} from '@/sudz/pmt-upl-funnel-steps';
import { buildPmtSfWorklist, type SudzPmtSfWorkRow } from '@/sudz/pmt-sf-worklist';
import { normalizeExplorerPath } from '@/utils/explorer-path';
import type { SudzPmUplLookup, SudzPmtUplCstNew } from '@/types/sudz';

const $q = useQuasar();
const store = useSudzPmtUplStore();
const sfSession = useSudzSfDoubleSessionStore();
const connection = useConnectionStore();

/** Доля высоты списка выгрузок (%). */
const listSplit = ref(28);
/** Доля высоты панели «загрузка» внутри деталей (%). */
const detailSplit = ref(34);
/** Доля ширины очереди «стройки новые» (%). */
const cstSplit = ref(40);

const mainTab = ref('load');
const subTab = ref('progress');
/** Фильтр единого грида повторов: все / только InvNot / только TwoLoad. */
const doublesFilter = ref<'all' | 'invNot' | 'twoLoad'>('all');
const doublesFilterOptions = [
  { label: 'Все', value: 'all' },
  { label: 'InvNot', value: 'invNot' },
  { label: 'TwoLoad', value: 'twoLoad' }
];
/** Черновик пути Excel; в БД — по blur / Enter. */
const pathDraft = ref('');
/** Черновик cipufSheet (у pmt нет FileSh). */
const sheetDraft = ref('');
const progressPane = ref<HTMLElement | null>(null);
/** Длина префикса среди enabled-шагов (по умолчанию — ничего). */
const funnelPrefixLen = ref(0);
const funnelSteps = SUDZ_PMT_UPL_FUNNEL_STEPS;

const selectedStepIds = computed(() => pmtFunnelPrefixIds(funnelPrefixLen.value));
const flLoad = computed(() => store.file?.cipufFlLoad ?? false);
const flTbl = computed(() => store.file?.cipufFlTbl ?? false);
const progressHtml = computed(() => store.file?.cipufLoadingProgress?.trim() || '');

watch(
  () => store.file?.cipufPath ?? '',
  (path) => {
    pathDraft.value = path;
  }
);

watch(
  () => store.file?.cipufSheet ?? '',
  (sheet) => {
    sheetDraft.value = sheet || '';
  }
);

watch(progressHtml, async () => {
  await nextTick();
  const el = progressPane.value;
  if (el) {
    el.scrollTop = el.scrollHeight;
  }
});

const sfWorkRows = computed<SudzPmtSfWorkRow[]>(() =>
  buildPmtSfWorklist(store.sfDoubles, store.invNot, store.twoLoad)
);

const sfWorkFilteredRows = computed<SudzPmtSfWorkRow[]>(() => {
  const rows = sfWorkRows.value;
  if (doublesFilter.value === 'invNot') {
    return rows.filter((r) => r.fromInvNot);
  }
  if (doublesFilter.value === 'twoLoad') {
    return rows.filter((r) => r.fromTwoLoad);
  }
  return rows;
});

const sfWorkSelected = ref<SudzPmtSfWorkRow[]>([]);

const sfWorkOpenCount = computed(
  () => sfWorkRows.value.filter((r) => r.ciusStatus === 'open').length
);

/**
 * Якорь КСДСФ: выбранная строка worklist → ciusKey (зерно = очередь).
 */
function resolveSfDoubleAnchor(): number | null {
  return sfWorkSelected.value[0]?.ciusKey ?? null;
}

/**
 * Открывает экран КСДСФ для текущего пакета платежей.
 */
function openSfDouble(): void {
  sfSession.openFromPmt(resolveSfDoubleAnchor());
  connection.navigate('sudz-sf-double');
}

/** Число строек: бейдж API, пока он не пришёл — длина грида. */
const cstNewCount = computed<number | null>(() => {
  if (store.badges) {
    return store.badges.cstNew;
  }
  if (store.cstNewLoading) {
    return null;
  }
  return store.cstNew.length;
});

const createDialog = reactive({
  open: false,
  name: '',
  date: ''
});

const uplColumns: FemsqTableColumn<SudzPmUplLookup>[] = [
  {
    name: 'date',
    label: 'Дата',
    field: 'date',
    align: 'left',
    format: (v) => formatDate(v as string | null)
  },
  { name: 'name', label: 'Имя', field: 'name', align: 'left' },
  { name: 'pmKey', label: 'pm_key', field: 'pmKey', align: 'right' }
];

const sfWorkColumns: FemsqTableColumn<SudzPmtSfWorkRow>[] = [
  {
    name: 'fromInvNot',
    label: 'Inv',
    field: 'fromInvNot',
    align: 'center',
    format: (v) => ((v as boolean) ? '✓' : '')
  },
  {
    name: 'fromTwoLoad',
    label: 'Two',
    field: 'fromTwoLoad',
    align: 'center',
    format: (v) => ((v as boolean) ? '✓' : '')
  },
  { name: 'ciusStatus', label: 'статус', field: 'ciusStatus', align: 'left' },
  { name: 'ciusCnNum', label: 'Договор', field: 'ciusCnNum', align: 'left' },
  { name: 'ciusCnKey', label: 'cn', field: 'ciusCnKey', align: 'right' },
  { name: 'ciusInvNum', label: 'СФ', field: 'ciusInvNum', align: 'left' },
  {
    name: 'ciusInvNumCount',
    label: 'совпад.',
    field: 'ciusInvNumCount',
    align: 'right'
  },
  {
    name: 'twoLoadCiCount',
    label: 'ci×',
    field: 'twoLoadCiCount',
    align: 'right'
  }
];

const cstNewColumns: FemsqTableColumn<SudzPmtUplCstNew>[] = [
  { name: 'cacOrNull', label: 'САК', field: 'cacOrNull', align: 'left' },
  { name: 'sh', label: 'sh', field: 'sh', align: 'left' },
  {
    name: 'ipCode',
    label: 'ipCode',
    field: 'ipCode',
    align: 'left',
    format: (value) => (value ? String(value) : '—')
  }
];

const cstSelected = ref<SudzPmtUplCstNew[]>([]);

const selectedCst = computed(() => cstSelected.value[0] ?? null);

const cstMatchSpec = cstMatchSpecJson as FemsqWalkTreeSpec;

const cstRootsToken = computed(() =>
  pmtCstMatchRootsToken(selectedCst.value?.sh, store.cstMatch)
);

/**
 * Лес не зовёт fetchNode; заглушка для обязательного пропа.
 */
async function fetchCstMatchNode(): Promise<null> {
  return null;
}

/**
 * Рёбра каталога на этой вкладке не используются.
 */
async function fetchCstMatchExpand(): Promise<[]> {
  return [];
}

/**
 * Корни леса из кэша sudzPmtUplCstMatch (хвост — у хоста).
 */
async function fetchCstMatchRoots(): Promise<ReturnType<typeof pmtCstMatchRootRows>> {
  return pmtCstMatchRootRows(store.cstMatch);
}

/**
 * Агенты стройки или коды агента из того же кэша.
 */
async function fetchCstMatchQuery(
  queryId: string,
  fromId: number
): Promise<ReturnType<typeof pmtCstMatchQueryRows>> {
  return pmtCstMatchQueryRows(queryId, fromId, store.cstMatch);
}

watch(selectedCst, (row) => {
  if (!row?.sh) {
    store.clearCstMatch();
    return;
  }
  void store.loadCstMatch(row.sh);
});

watch(
  () => store.cstNew,
  (rows) => {
    const current = selectedCst.value;
    if (!current) {
      return;
    }
    if (!rows.some((row) => row.cacOrNull === current.cacOrNull)) {
      cstSelected.value = [];
    }
  }
);

/**
 * Переход на экран «Стройки», где создаётся новая cst.
 */
function openConstructionSites(): void {
  connection.navigate('construction-sites');
}

const cstActionBusy = ref(false);
const agentLookups = ref<Array<{ ogaKey: number; ogaNm: string }>>([]);
const agentDialog = reactive({
  open: false,
  cstKey: 0,
  cstName: '',
  code: '',
  cstaAg: null as number | null,
  options: [] as Array<{ label: string; value: number }>
});
const pointDialog = reactive({
  open: false,
  cstaKey: 0,
  agentLabel: '',
  code: ''
});

/**
 * Кнопки обходчика: агент у стройки, код у агента.
 */
function onCstWalkAction(context: FemsqWalkActionContext): void {
  if (context.actionId === 'pmt.cst.agent') {
    void openAgentDialog(context);
    return;
  }
  if (context.actionId === 'pmt.cst.code') {
    openPointDialog(context);
  }
}

/**
 * Агент существующего ogAg с тем же трёхсимвольным кодом, что в начале cacOrNull.
 */
async function openAgentDialog(context: FemsqWalkActionContext): Promise<void> {
  const row = selectedCst.value;
  const cstKey = context.node.rowKey;
  if (!row || cstKey == null || context.node.table !== 'cst') {
    return;
  }
  const code = queueAgentCode(row.cacOrNull);
  try {
    if (agentLookups.value.length === 0) {
      agentLookups.value = await getOgAgCsLookups();
    }
  } catch (e) {
    $q.notify({ type: 'negative', message: e instanceof Error ? e.message : String(e) });
    return;
  }
  const matches = lookupsForAgentCode(agentLookups.value, code);
  agentDialog.cstKey = cstKey;
  agentDialog.cstName = context.node.fields.label ?? context.node.title;
  agentDialog.code = code;
  agentDialog.options = matches.map((item) => ({ label: item.ogaNm, value: item.ogaKey }));
  agentDialog.cstaAg = matches.length === 1 ? matches[0].ogaKey : null;
  agentDialog.open = true;
}

/**
 * Код САК фиксирован кодом выбранной строки очереди.
 */
function openPointDialog(context: FemsqWalkActionContext): void {
  const row = selectedCst.value;
  const cstaKey = context.node.rowKey;
  if (!row || cstaKey == null || context.node.table !== 'cstAg') {
    return;
  }
  pointDialog.cstaKey = cstaKey;
  pointDialog.agentLabel = context.node.fields.label || context.node.title || `агент ${cstaKey}`;
  pointDialog.code = row.cacOrNull;
  pointDialog.open = true;
}

/**
 * Добавляет cstAg и оставляет строку в очереди: кода САК ещё нет.
 */
async function saveAgent(): Promise<void> {
  const row = selectedCst.value;
  if (agentDialog.cstaAg == null || !row) {
    return;
  }
  cstActionBusy.value = true;
  try {
    await createCstAgent({ cstaAg: agentDialog.cstaAg, cstaCst: agentDialog.cstKey });
    agentDialog.open = false;
    await store.loadCstMatch(row.sh);
    $q.notify({ type: 'positive', message: 'Агент добавлен. Строка очереди ждёт код САК.' });
  } catch (e) {
    $q.notify({ type: 'negative', message: e instanceof Error ? e.message : String(e) });
  } finally {
    cstActionBusy.value = false;
  }
}

/**
 * Добавляет cstAgPn с кодом очереди. После этого строка уходит из cipuCacNot.
 */
async function savePoint(): Promise<void> {
  const row = selectedCst.value;
  const code = pointDialog.code;
  if (!row || !code || cstActionBusy.value) {
    return;
  }
  cstActionBusy.value = true;
  try {
    await createCstAgPoint({ cstapCsta: pointDialog.cstaKey, cstapIpgPnN: code });
    pointDialog.open = false;
    await store.refreshQueues();
    $q.notify({ type: 'positive', message: 'Код добавлен. Строка ушла из очереди.' });
  } catch (e) {
    await store.refreshQueues();
    const stillQueued = store.cstNew.some((item) => item.cacOrNull === code);
    if (!stillQueued) {
      pointDialog.open = false;
      await store.loadCstMatch(row.sh);
      $q.notify({ type: 'positive', message: 'Код уже в каталоге. Строка ушла из очереди.' });
      return;
    }
    $q.notify({ type: 'negative', message: e instanceof Error ? e.message : String(e) });
  } finally {
    cstActionBusy.value = false;
  }
}

/**
 * Подпись бейджа: число или многоточие, пока счётчик грузится.
 */
function badgeText(value: number | null | undefined, loading: boolean): string {
  if (value == null) {
    return loading ? '…' : '0';
  }
  return String(value);
}

/**
 * Цвет бейджа: акцент, если очередь не пуста.
 */
function badgeColor(value: number | null | undefined): string {
  return value != null && value > 0 ? 'primary' : 'grey-7';
}

const selectedRows = ref<SudzPmUplLookup[]>([]);

watch(
  () => store.selectedUpl,
  (upl) => {
    selectedRows.value = upl ? [upl] : [];
  }
);

/**
 * Форматирует дату YYYY-MM-DD → ДД.ММ.ГГГГ.
 */
function formatDate(value: string | null | undefined): string {
  if (!value) {
    return '—';
  }
  const iso = value.slice(0, 10);
  const [y, m, d] = iso.split('-');
  if (!y || !m || !d) {
    return value;
  }
  return `${d}.${m}.${y}`;
}

/**
 * Выбор строки списка выгрузок.
 */
function onUplClick(_evt: Event, row: SudzPmUplLookup): void {
  if (row.pmKey !== store.selectedPmKey) {
    void store.selectUpl(row.pmKey);
  }
}

/**
 * Сохраняет путь из поля в cipufPath.
 */
async function onPathCommit(): Promise<boolean> {
  if (!store.selectedUpl) {
    return false;
  }
  const next = normalizeExplorerPath(pathDraft.value);
  const current = store.file?.cipufPath ?? '';
  if (next !== pathDraft.value) {
    pathDraft.value = next;
  }
  if (next === current) {
    return true;
  }
  const ok = await store.saveFile({ path: next });
  if (ok) {
    $q.notify({ type: 'positive', message: 'Путь сохранён в БД', timeout: 1200 });
  }
  return ok;
}

/**
 * Сохраняет имя листа в cipufSheet.
 */
async function onSheetCommit(): Promise<boolean> {
  if (!store.selectedUpl) {
    return false;
  }
  const next = sheetDraft.value.trim();
  const current = store.file?.cipufSheet ?? '';
  if (next !== sheetDraft.value) {
    sheetDraft.value = next;
  }
  if (next === (current || '')) {
    return true;
  }
  const ok = await store.saveFile({ sheet: next });
  if (ok) {
    $q.notify({ type: 'positive', message: 'Лист сохранён в БД', timeout: 1200 });
  }
  return ok;
}

/**
 * Открывает диалог создания пакета платежей.
 */
function openCreateDialog(): void {
  const today = new Date().toISOString().slice(0, 10);
  createDialog.name = '';
  createDialog.date = today;
  createDialog.open = true;
}

/**
 * Создаёт пакет cn_inv_pm_upl и выбирает его.
 */
async function onCreateUpl(): Promise<void> {
  if (!createDialog.date) {
    $q.notify({ type: 'warning', message: 'Укажите дату выгрузки' });
    return;
  }
  const created = await store.createUpl({
    name: createDialog.name.trim() || null,
    date: createDialog.date
  });
  if (created) {
    createDialog.open = false;
    $q.notify({ type: 'positive', message: `Создана выгрузка pm_key=${created.pmKey}` });
  }
}

/**
 * Чекбокс отмечен, если шаг enabled и входит в выбранный префикс.
 */
function isStepChecked(stepIndex: number): boolean {
  const step = funnelSteps[stepIndex];
  if (!step?.enabled) {
    return false;
  }
  const enabledPos = SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS.indexOf(step.id);
  return enabledPos >= 0 && enabledPos < funnelPrefixLen.value;
}

/**
 * Клик по шагу: включает префикс до этого шага включительно (или снимает, если уже последний).
 */
function onStepToggle(stepIndex: number, checked: boolean): void {
  const step = funnelSteps[stepIndex];
  if (!step?.enabled) {
    return;
  }
  const enabledPos = SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS.indexOf(step.id);
  if (enabledPos < 0) {
    return;
  }
  if (checked) {
    funnelPrefixLen.value = enabledPos + 1;
  } else if (funnelPrefixLen.value === enabledPos + 1) {
    funnelPrefixLen.value = Math.max(0, enabledPos);
  } else {
    funnelPrefixLen.value = enabledPos;
  }
}

/**
 * Запуск воронки: Excel→Tbl при flTbl + stub cipu* по префиксу.
 */
async function onRunLoad(): Promise<void> {
  if (!store.selectedUpl) {
    $q.notify({ type: 'warning', message: 'Выберите выгрузку' });
    return;
  }
  const pathOk = await onPathCommit();
  if (!pathOk) {
    return;
  }
  const sheetOk = await onSheetCommit();
  if (!sheetOk) {
    return;
  }
  if (!store.file) {
    $q.notify({ type: 'warning', message: 'Нет записи File для выбранной выгрузки' });
    return;
  }
  if (flTbl.value && !pathDraft.value.trim()) {
    $q.notify({
      type: 'warning',
      message: 'Вставьте путь к xlsx как в Проводнике и сохраните поле.'
    });
    return;
  }
  if (flTbl.value && !sheetDraft.value.trim()) {
    $q.notify({
      type: 'warning',
      message: 'Укажите имя листа Excel (cipufSheet) и сохраните поле.'
    });
    return;
  }
  if (!flTbl.value && selectedStepIds.value.length === 0) {
    $q.notify({
      type: 'warning',
      message: 'Включите «обнов. по исх?» или отметьте шаг воронки'
    });
    return;
  }
  const result = await store.runFunnelStub(selectedStepIds.value);
  if (result) {
    subTab.value = 'progress';
    $q.notify({
      type: result.ok ? 'positive' : 'warning',
      message: result.message
    });
  } else if (store.error) {
    $q.notify({ type: 'negative', message: store.error });
  }
}

onMounted(() => {
  void store.loadUpls();
});
</script>

<style scoped>
/* QPage position:relative — absolute-full заполняет его ровно; padding внутри box-sizing. */
.sudz-pmt-upl-view {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  align-items: stretch;
  width: 100%;
  min-height: 0;
  overflow: hidden;
  box-sizing: border-box;
}

.shrink-0 {
  flex-shrink: 0;
}

.min-h-0 {
  min-height: 0;
}

.sudz-main-splitter,
.sudz-detail-splitter,
.sudz-cst-splitter {
  flex: 1 1 auto;
  min-height: 0;
  width: 100%;
}

.sudz-main-splitter :deep(> .q-splitter__panel),
.sudz-detail-splitter :deep(> .q-splitter__panel),
.sudz-cst-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  width: 100%;
}

.sudz-cst-splitter {
  height: 100%;
}

.sudz-cst-splitter :deep(.q-splitter__separator) {
  width: 5px;
  background: transparent;
}

.fill-pane {
  width: 100%;
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.sudz-split-sep {
  background: var(--femsq-border, rgba(127, 127, 127, 0.45));
}

.sudz-main-splitter :deep(.q-splitter__separator),
.sudz-detail-splitter :deep(.q-splitter__separator) {
  height: 5px;
  background: transparent;
}

.sudz-main-splitter :deep(.q-splitter__separator-area),
.sudz-detail-splitter :deep(.q-splitter__separator-area) {
  height: 5px;
  background: color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
  border-radius: 2px;
  opacity: 0.85;
}

.sudz-main-splitter :deep(.q-splitter__separator-area:hover),
.sudz-detail-splitter :deep(.q-splitter__separator-area:hover) {
  opacity: 1;
  background: var(--q-primary);
}

.sudz-tab-panels {
  min-height: 0;
  overflow: hidden;
}

.sudz-tab-panels :deep(.q-panel),
.sudz-tab-panels :deep(.q-tab-panel) {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.sudz-funnel-scroll {
  overflow-x: auto;
  overflow-y: hidden;
  max-width: 100%;
  padding-bottom: 4px;
}

.sudz-funnel-table {
  border-collapse: collapse;
  width: max-content;
  min-width: 100%;
}

.sudz-funnel-table th,
.sudz-funnel-table td {
  vertical-align: top;
  text-align: center;
  padding: 4px 8px;
  min-width: 7.25rem;
  max-width: 9.5rem;
  border-right: 1px solid color-mix(in srgb, var(--femsq-border, #666) 55%, transparent);
}

.sudz-funnel-table th:last-child,
.sudz-funnel-table td:last-child {
  border-right: none;
}

.sudz-funnel-table thead th {
  padding-bottom: 2px;
}

.sudz-funnel-caption {
  font-size: 11px;
  line-height: 1.25;
  white-space: normal;
  word-break: break-word;
  text-align: left;
}

.sudz-pmt-upl-progress {
  height: 100%;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.35;
  white-space: normal;
  word-break: break-word;
}

.sudz-pmt-upl-progress :deep(p) {
  margin: 0 0 2px;
}

/* Как экран C (свод): свёртка шагов +/− */
.sudz-pmt-upl-progress :deep(.sudz-funnel-log-block) {
  margin: 4px 0 6px 2px;
  padding-left: 6px;
  border-left: 1px solid color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
}

.sudz-pmt-upl-progress :deep(.sudz-funnel-log-block > summary) {
  cursor: pointer;
  list-style: none;
  user-select: none;
  padding: 2px 0;
}

.sudz-pmt-upl-progress :deep(.sudz-funnel-log-block > summary::-webkit-details-marker) {
  display: none;
}

.sudz-pmt-upl-progress :deep(.sudz-funnel-log-pm)::before {
  content: '+';
  display: inline-block;
  width: 1.1em;
  font-weight: 700;
  color: var(--q-primary);
}

.sudz-pmt-upl-progress :deep(details[open] > summary .sudz-funnel-log-pm)::before {
  content: '\2212';
}

.sudz-pmt-upl-progress :deep(.sudz-funnel-log-body) {
  padding: 2px 0 4px 10px;
}

.sudz-upl-table {
  min-height: 0;
  height: 100%;
}
</style>

<!--
  Без scoped: v-html не получает data-v-*, а хеш scoped меняется между сборками.
  Те же селекторы, что у свода — чтобы +/− всегда рисовались у summary.
-->
<style>
.sudz-pmt-upl-progress .sudz-funnel-log-pm::before {
  content: '+';
  display: inline-block;
  width: 1.1em;
  font-weight: 700;
  color: var(--q-primary);
}

.sudz-pmt-upl-progress details[open] > summary .sudz-funnel-log-pm::before {
  content: '\2212';
}
</style>
