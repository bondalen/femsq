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
                        hint="Путь как в Проводнике. Visual v1 — не сохраняется в БД."
                        hint-persistent
                        :disable="!store.selectedUpl"
                        data-test="sudz-pmt-upl-file-name"
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
                        data-test="sudz-pmt-upl-sheet"
                      />
                    </div>
                  </div>
                  <div class="row q-col-gutter-sm items-center q-mb-sm shrink-0">
                    <div class="col-auto">
                      <QToggle
                        v-model="flLoad"
                        label="Обновлять"
                        dense
                        data-test="sudz-pmt-upl-fl-load"
                      />
                    </div>
                    <div class="col-auto">
                      <QToggle
                        v-model="flTbl"
                        label="обнов. по исх?"
                        dense
                        data-test="sudz-pmt-upl-fl-tbl"
                      />
                    </div>
                    <div class="col-auto">
                      <QBtn
                        color="primary"
                        unelevated
                        no-caps
                        dense
                        label="загрузка"
                        :disable="!store.selectedUpl"
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
                    Кнопка «загрузка» — stub (воронка и Excel вне v1). Наведите на ячейку — id процедуры.
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
                <QTab name="doubles" label="повторяющиеся СФ" data-test="sudz-pmt-upl-tab-doubles" />
                <QTab name="cst-new" label="стройки новые" data-test="sudz-pmt-upl-tab-cst-new" />
              </QTabs>
              <QSeparator />

              <QTabPanels v-model="subTab" animated class="col min-h-0 sudz-tab-panels">
                <QTabPanel name="progress" class="q-pa-none fill-pane relative-position">
                  <div
                    class="sudz-pmt-upl-progress q-pa-sm"
                    data-test="sudz-pmt-upl-progress"
                  />
                  <div
                    v-if="!progressLog"
                    class="text-grey-6 q-pa-sm absolute-top"
                    data-test="sudz-pmt-upl-progress-empty"
                  >
                    Лог хода пуст (заполнится при воронке cipu*).
                  </div>
                </QTabPanel>

                <QTabPanel name="doubles" class="q-pa-none fill-pane column no-wrap">
                  <FemsqTable
                    class="col"
                    :rows="invDoubleRows"
                    :columns="invDoubleColumns"
                    row-key="rowKey"
                    dense
                    flat
                    data-test="sudz-pmt-upl-doubles"
                  />
                  <div class="text-grey-6 q-pa-sm shrink-0">
                    Каркас (данные появятся после шага cipuCn_CtptCnOneInvTwoLoad).
                  </div>
                </QTabPanel>

                <QTabPanel name="cst-new" class="q-pa-none fill-pane column no-wrap">
                  <FemsqTable
                    class="col"
                    :rows="cstNewRows"
                    :columns="cstNewColumns"
                    row-key="rowKey"
                    dense
                    flat
                    data-test="sudz-pmt-upl-cst-new"
                  />
                  <div class="text-grey-6 q-pa-sm shrink-0">
                    Каркас (данные появятся после шага cipuCacNot).
                  </div>
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
  QCheckbox,
  QDialog,
  QInput,
  QPage,
  QSeparator,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QToggle,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { useSudzPmtUplStore } from '@/stores/sudz-pmt-upl';
import {
  SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS,
  SUDZ_PMT_UPL_FUNNEL_STEPS,
  pmtFunnelPrefixIds
} from '@/sudz/pmt-upl-funnel-steps';
import type { SudzPmUplLookup } from '@/types/sudz';

const $q = useQuasar();
const store = useSudzPmtUplStore();

/** Доля высоты списка выгрузок (%). */
const listSplit = ref(28);
/** Доля высоты панели «загрузка» внутри деталей (%). */
const detailSplit = ref(34);

const mainTab = ref('load');
const subTab = ref('progress');
/** Черновик пути Excel (visual v1 — не пишется в БД). */
const pathDraft = ref('');
/** Имя листа cipufSheet (у pmt нет FileSh). */
const sheetDraft = ref('Sheet1');
const flLoad = ref(true);
const flTbl = ref(true);
/** Пустое поле лога (visual v1). */
const progressLog = ref('');
/** Длина префикса среди enabled-шагов (по умолчанию — ничего). */
const funnelPrefixLen = ref(0);
const funnelSteps = SUDZ_PMT_UPL_FUNNEL_STEPS;

const selectedStepIds = computed(() => pmtFunnelPrefixIds(funnelPrefixLen.value));

interface EmptyGridRow {
  rowKey: number;
}

const invDoubleRows = ref<EmptyGridRow[]>([]);
const cstNewRows = ref<EmptyGridRow[]>([]);

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

const invDoubleColumns: FemsqTableColumn<EmptyGridRow>[] = [
  { name: 'cnNum', label: 'Договор', field: 'rowKey', align: 'left' },
  { name: 'invNum', label: 'СФ', field: 'rowKey', align: 'left' }
];

const cstNewColumns: FemsqTableColumn<EmptyGridRow>[] = [
  { name: 'cstCode', label: 'Код', field: 'rowKey', align: 'left' },
  { name: 'cstName', label: 'Имя', field: 'rowKey', align: 'left' }
];

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
    store.selectUpl(row.pmKey);
  }
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
 * Stub кнопки «загрузка»: Excel и домен не пишутся.
 */
function onRunLoad(): void {
  if (!store.selectedUpl) {
    $q.notify({ type: 'warning', message: 'Выберите выгрузку' });
    return;
  }
  subTab.value = 'progress';
  $q.notify({
    type: 'info',
    message: 'Visual v1: воронка cipu* и Excel не запускаются'
  });
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
.sudz-detail-splitter {
  flex: 1 1 auto;
  min-height: 0;
  width: 100%;
}

.sudz-main-splitter :deep(> .q-splitter__panel),
.sudz-detail-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  width: 100%;
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
  white-space: pre-wrap;
  word-break: break-word;
}

.sudz-upl-table {
  min-height: 0;
  height: 100%;
}
</style>
