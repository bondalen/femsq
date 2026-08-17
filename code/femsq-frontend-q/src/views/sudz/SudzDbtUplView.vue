<template>
  <!-- absolute-full: высота = область между header/footer; без calc(100vh) — нет лишнего скролла страницы -->
  <QPage class="q-pa-none" data-test="sudz-dbt-upl-view">
    <div class="absolute-full q-pa-md column no-wrap sudz-dbt-upl-view">
    <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
      <div class="text-h6 col">Загрузка свода</div>
      <QBtn
        color="primary"
        unelevated
        no-caps
        dense
        icon="add"
        label="Выгрузка"
        data-test="sudz-dbt-upl-create"
        @click="openCreateDialog"
      />
      <QBtn
        flat
        dense
        no-caps
        icon="refresh"
        label="Обновить"
        :loading="store.loading"
        data-test="sudz-dbt-upl-refresh"
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
      data-test="sudz-dbt-upl-main-splitter"
    >
      <template #before>
        <section class="fill-pane column no-wrap" data-test="sudz-dbt-upl-list-pane">
          <QCard flat bordered class="fill-pane column no-wrap">
            <QCardSection class="q-pa-none col column no-wrap min-h-0">
              <FemsqTable
                class="sudz-upl-table col"
                root-class="sudz-upl-table"
                :rows="store.upls"
                :columns="uplColumns"
                row-key="uplKey"
                dense
                flat
                :loading="store.loading"
                selection="single"
                v-model:selected="selectedRows"
                hide-bottom
                :rows-per-page-options="[0]"
                data-test="sudz-dbt-upl-table"
                @row-click="onUplClick"
              />
            </QCardSection>
            <QCardSection class="q-py-xs q-px-sm shrink-0 text-caption">
              <template v-if="store.selectedUpl">
                <span data-test="sudz-dbt-upl-header">
                  Выбрано:
                  {{ formatDate(store.selectedUpl.uplDate) }}
                  ·
                  {{ store.selectedUpl.uplName || '—' }}
                  <span class="text-grey-7">(upl_key={{ store.selectedUpl.uplKey }})</span>
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

        <!-- Управление / воронка ↔ ход загрузки -->
        <QSplitter
          v-else
          v-model="detailSplit"
          horizontal
          :limits="[20, 80]"
          separator-class="sudz-split-sep"
          class="sudz-detail-splitter fill-pane"
          data-test="sudz-dbt-upl-detail-splitter"
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
                <QTab name="load" label="загрузка" data-test="sudz-dbt-upl-tab-load" />
                <QTab name="pm" label="выгрузки платежей" disable />
                <QTab name="acc" label="счета, сумма" disable />
                <QTab name="debt-edit" label="задолженности, правка" disable />
                <QTab name="debt-read" label="задолженности, чтение" disable />
              </QTabs>
              <QSeparator />

              <QTabPanels v-model="mainTab" animated class="col min-h-0 sudz-tab-panels">
                <QTabPanel name="load" class="q-pa-sm column no-wrap fill-pane">
                  <div class="row q-col-gutter-sm items-center q-mb-xs shrink-0">
                    <div class="col-12">
                      <QInput
                        v-model="pathDraft"
                        dense
                        outlined
                        label="Файл"
                        hint="Путь как в Проводнике. Сохраняется в БД при потере фокуса или Enter."
                        hint-persistent
                        :disable="store.saving || !store.selectedUpl"
                        data-test="sudz-dbt-upl-file-name"
                        @blur="onPathCommit"
                        @keyup.enter="onPathCommit"
                      />
                    </div>
                  </div>
                  <div class="row q-col-gutter-sm items-center q-mb-sm shrink-0">
                    <div class="col-auto">
                      <QToggle
                        :model-value="flLoad"
                        label="Обновлять"
                        dense
                        data-test="sudz-dbt-upl-fl-load"
                        @update:model-value="(v) => store.patchFileFlags({ flLoad: !!v })"
                      />
                    </div>
                    <div class="col-auto">
                      <QToggle
                        :model-value="flTbl"
                        label="обнов. по исх.?"
                        dense
                        data-test="sudz-dbt-upl-fl-tbl"
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
                        :loading="store.funnelRunning"
                        :disable="!store.selectedUpl"
                        data-test="sudz-dbt-upl-run"
                        @click="onRunLoad"
                      />
                    </div>
                  </div>

                  <QSeparator class="q-mb-sm shrink-0" />

                  <div class="text-subtitle2 q-mb-xs shrink-0">Шаги воронки (S61f)</div>
                  <div class="row q-gutter-xs q-mb-sm shrink-0" data-test="sudz-dbt-upl-funnel-presets">
                    <QBtn
                      outline
                      dense
                      no-caps
                      size="sm"
                      label="только org"
                      data-test="sudz-dbt-upl-preset-org"
                      @click="applyPreset('org')"
                    />
                    <QBtn
                      outline
                      dense
                      no-caps
                      size="sm"
                      label="до договоров"
                      data-test="sudz-dbt-upl-preset-cn"
                      @click="applyPreset('cnDry')"
                    />
                    <QBtn
                      outline
                      dense
                      no-caps
                      size="sm"
                      label="полная dry-run"
                      data-test="sudz-dbt-upl-preset-full-dry"
                      @click="applyPreset('fullDry')"
                    />
                    <QBtn
                      unelevated
                      dense
                      no-caps
                      size="sm"
                      color="warning"
                      text-color="dark"
                      label="полная + apply*"
                      data-test="sudz-dbt-upl-preset-full-apply"
                      @click="applyPreset('fullApply')"
                    />
                  </div>

                  <div
                    class="sudz-funnel-scroll shrink-0"
                    data-test="sudz-dbt-upl-funnel-steps"
                  >
                    <table class="sudz-funnel-table">
                      <thead>
                        <tr>
                          <th
                            v-for="(step, idx) in funnelSteps"
                            :key="`chk-${step.id}`"
                            :class="{ 'sudz-funnel-cell--off': !step.enabled }"
                            :title="step.id"
                          >
                            <QCheckbox
                              dense
                              :disable="!step.enabled"
                              :model-value="isStepChecked(idx)"
                              :data-test="`sudz-dbt-upl-step-${step.id}`"
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
                            :class="{ 'sudz-funnel-cell--off': !step.enabled }"
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
                    Stub не пишет в домен. Наведите на ячейку — id процедуры.
                  </div>
                </QTabPanel>
              </QTabPanels>
            </QCard>
          </template>

          <template #after>
            <QCard flat bordered class="fill-pane column no-wrap" data-test="sudz-dbt-upl-bottom">
              <QTabs
                v-model="subTab"
                dense
                class="text-primary shrink-0"
                active-color="primary"
                indicator-color="primary"
                align="left"
              >
                <QTab name="progress" label="ход загрузки" data-test="sudz-dbt-upl-tab-progress" />
                <QTab name="sheets" label="перечень листов" data-test="sudz-dbt-upl-tab-sheets" />
                <QTab name="doubles" label="повторяющиеся СФ" data-test="sudz-dbt-upl-tab-doubles" />
              </QTabs>
              <QSeparator />

              <QTabPanels v-model="subTab" animated class="col min-h-0 sudz-tab-panels">
                <QTabPanel name="progress" class="q-pa-none fill-pane">
                  <div
                    v-if="progressHtml"
                    ref="progressPane"
                    class="sudz-dbt-upl-progress q-pa-sm"
                    data-test="sudz-dbt-upl-progress"
                    v-html="progressHtml"
                  />
                  <div
                    v-else
                    class="text-grey-6 q-pa-sm"
                    data-test="sudz-dbt-upl-progress-empty"
                  >
                    Лог хода пуст (заполнится при «загрузка» / stub воронки).
                  </div>
                </QTabPanel>

                <QTabPanel name="sheets" class="q-pa-none fill-pane column no-wrap">
                  <FemsqTable
                    class="col"
                    :rows="store.sheets"
                    :columns="sheetColumns"
                    row-key="cidufsKey"
                    dense
                    flat
                    :loading="store.loading"
                    data-test="sudz-dbt-upl-sheets"
                  />
                  <div v-if="!store.sheets.length" class="text-grey-6 q-pa-sm shrink-0">
                    Листов нет (появятся после чтения Excel).
                  </div>
                </QTabPanel>

                <QTabPanel name="doubles" class="q-pa-none fill-pane column no-wrap">
                  <FemsqTable
                    class="col"
                    :rows="store.sfDoubles"
                    :columns="sfDoubleColumns"
                    row-key="ciusKey"
                    dense
                    flat
                    :loading="store.loading"
                    data-test="sudz-dbt-upl-doubles"
                  />
                  <div class="row items-center q-pa-sm q-gutter-sm shrink-0">
                    <div v-if="!store.sfDoubles.length" class="text-grey-6 col">
                      Очередь неоднозначностей пуста (после шага CnCtptExistInvNotLoad).
                    </div>
                    <QSpace v-else />
                    <QBtn
                      flat
                      dense
                      no-caps
                      color="primary"
                      label="Разбор повторяющихся СФ…"
                      :disable="!store.sfDoubles.length"
                      data-test="sudz-dbt-upl-open-sf-double"
                      @click="openSfDouble"
                    />
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
        <QCardSection class="text-subtitle1">Новая выгрузка ДЗ</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="createDialog.name" dense outlined label="upl_name" />
          <QInput v-model="createDialog.uplDate" dense outlined type="date" label="upl_date" />
          <QInput
            v-model="createDialog.statusOnDate"
            dense
            outlined
            type="date"
            label="uplStatusOnDate"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать"
            :loading="store.saving"
            data-test="sudz-dbt-upl-create-submit"
            @click="onCreateUpl"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
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
  QSpace,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QToggle,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { useConnectionStore } from '@/stores/connection';
import { useSudzDbtUplStore } from '@/stores/sudz-dbt-upl';
import {
  SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS,
  SUDZ_DBT_UPL_FUNNEL_STEPS,
  funnelPrefixIds,
  funnelPresetPrefixCount,
  type FunnelPresetId
} from '@/sudz/dbt-upl-funnel-steps';
import type { SudzCnInvUplSfDouble, SudzDbtUplFileSh, SudzUplLookup } from '@/types/sudz';

const $q = useQuasar();
const store = useSudzDbtUplStore();
const connection = useConnectionStore();

/** Доля высоты списка выгрузок (%). */
const listSplit = ref(28);
/** Доля высоты панели «загрузка/воронка» внутри деталей (%). */
const detailSplit = ref(34);

const mainTab = ref('load');
const subTab = ref('progress');
const progressPane = ref<HTMLElement | null>(null);
/** Черновик cidufPath (как в Проводнике); в БД — по blur / Enter / «загрузка». */
const pathDraft = ref('');
/** Длина префикса среди enabled-шагов (по умолчанию — org = 2). */
const funnelPrefixLen = ref(1);
const funnelSteps = SUDZ_DBT_UPL_FUNNEL_STEPS;

const selectedStepIds = computed(() => funnelPrefixIds(funnelPrefixLen.value));

const createDialog = reactive({
  open: false,
  name: '',
  uplDate: '',
  statusOnDate: ''
});

const uplColumns: FemsqTableColumn<SudzUplLookup>[] = [
  {
    name: 'uplDate',
    label: 'Дата',
    field: 'uplDate',
    align: 'left',
    format: (v) => formatDate(v as string | null)
  },
  { name: 'uplName', label: 'Имя', field: 'uplName', align: 'left' },
  { name: 'uplKey', label: 'upl_key', field: 'uplKey', align: 'right' },
  {
    name: 'uplStatusOnDate',
    label: 'Срез',
    field: 'uplStatusOnDate',
    align: 'left',
    format: (v) => formatDate(v as string | null)
  }
];

const sheetColumns: FemsqTableColumn<SudzDbtUplFileSh>[] = [
  { name: 'cidufsSheet', label: 'Лист', field: 'cidufsSheet', align: 'left' },
  { name: 'cidufsAccount', label: 'Счёт', field: 'cidufsAccount', align: 'right' },
  {
    name: 'cidufsTest',
    label: 'проверять?',
    field: 'cidufsTest',
    align: 'center',
    format: (v) => (v ? 'да' : '')
  }
];

const sfDoubleColumns: FemsqTableColumn<SudzCnInvUplSfDouble>[] = [
  { name: 'ciusStatus', label: 'статус', field: 'ciusStatus', align: 'left' },
  { name: 'ciusCnNum', label: 'Договор', field: 'ciusCnNum', align: 'left' },
  { name: 'ciusInvNum', label: 'СФ', field: 'ciusInvNum', align: 'left' },
  { name: 'ciusInvNumCount', label: 'совпад.', field: 'ciusInvNumCount', align: 'right' }
];

/**
 * Открывает экран КСДСФ для текущей выгрузки.
 */
function openSfDouble(): void {
  connection.navigate('sudz-sf-double');
}

const selectedRows = ref<SudzUplLookup[]>([]);

watch(
  () => store.selectedUpl,
  (upl) => {
    selectedRows.value = upl ? [upl] : [];
  }
);

watch(
  () => store.file?.cidufPath ?? '',
  (path) => {
    pathDraft.value = path;
  }
);

const flLoad = computed(() => store.file?.cidufFlLoad ?? false);
const flTbl = computed(() => store.file?.cidufFlTbl ?? false);
const progressHtml = computed(() => store.file?.cidufLoadingProgress?.trim() || '');

watch(progressHtml, async () => {
  await nextTick();
  const el = progressPane.value;
  if (el) {
    el.scrollTop = el.scrollHeight;
  }
});

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
 * Снимает кавычки «Копировать как путь» — в БД путь как в адресной строке Проводника.
 */
function stripExplorerPath(raw: string): string {
  let trimmed = raw.trim();
  if (trimmed.length >= 2) {
    const first = trimmed[0];
    const last = trimmed[trimmed.length - 1];
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      trimmed = trimmed.slice(1, -1).trim();
    }
  }
  return trimmed;
}

/**
 * Сохраняет путь из поля в cidufPath (как вставил пользователь).
 */
async function onPathCommit(): Promise<boolean> {
  if (!store.selectedUpl) {
    return false;
  }
  const next = stripExplorerPath(pathDraft.value);
  const current = store.file?.cidufPath ?? '';
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
 * Выбор строки списка выгрузок.
 */
function onUplClick(_evt: Event, row: SudzUplLookup): void {
  if (row.uplKey !== store.selectedUplKey) {
    void store.selectUpl(row.uplKey);
  }
}

/**
 * Открывает диалог создания выгрузки.
 */
function openCreateDialog(): void {
  const today = new Date().toISOString().slice(0, 10);
  createDialog.name = '';
  createDialog.uplDate = today;
  createDialog.statusOnDate = today;
  createDialog.open = true;
}

/**
 * Создаёт выгрузку и выбирает её.
 */
async function onCreateUpl(): Promise<void> {
  const created = await store.createUpl({
    uplName: createDialog.name.trim() || null,
    uplDate: createDialog.uplDate || null,
    uplStatusOnDate: createDialog.statusOnDate || null
  });
  if (created) {
    createDialog.open = false;
    $q.notify({ type: 'positive', message: `Создана выгрузка upl_key=${created.uplKey}` });
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
  const enabledPos = SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS.indexOf(step.id);
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
  const enabledPos = SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS.indexOf(step.id);
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
 * Применяет пресет длины префикса.
 */
function applyPreset(id: FunnelPresetId): void {
  funnelPrefixLen.value = funnelPresetPrefixCount(id);
}

/**
 * Запуск stub-воронки по выбранному префиксу.
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
  }
}

onMounted(() => {
  void store.loadUpls();
});
</script>

<style scoped>
/* QPage position:relative — absolute-full заполняет его ровно; padding внутри box-sizing. */
.sudz-dbt-upl-view {
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

.sudz-funnel-cell--off {
  opacity: 0.45;
}

.sudz-dbt-upl-progress {
  height: 100%;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.35;
  white-space: normal;
  word-break: break-word;
}

.sudz-dbt-upl-progress :deep(p) {
  margin: 0 0 2px;
}

.sudz-dbt-upl-progress :deep(.sudz-funnel-log-block) {
  margin: 4px 0 6px 2px;
  padding-left: 6px;
  border-left: 1px solid color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
}

.sudz-dbt-upl-progress :deep(.sudz-funnel-log-block > summary) {
  cursor: pointer;
  list-style: none;
  user-select: none;
  padding: 2px 0;
}

.sudz-dbt-upl-progress :deep(.sudz-funnel-log-block > summary::-webkit-details-marker) {
  display: none;
}

.sudz-dbt-upl-progress :deep(.sudz-funnel-log-pm)::before {
  content: '+';
  display: inline-block;
  width: 1.1em;
  font-weight: 700;
  color: var(--q-primary);
}

.sudz-dbt-upl-progress :deep(details[open] > summary .sudz-funnel-log-pm)::before {
  content: '\2212';
}

.sudz-dbt-upl-progress :deep(.sudz-funnel-log-body) {
  padding: 2px 0 4px 10px;
}

.sudz-upl-table {
  min-height: 0;
  height: 100%;
}

.hidden {
  display: none;
}
</style>
