<template>
  <QPage class="sudz-yr-view q-pa-md column no-wrap" data-test="sudz-portfolio-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Портфель года</div>
        <div class="femsq-page-subtitle">СУДЗ · год-вариант (yr)</div>
      </div>
      <QBtn flat dense no-caps color="primary" icon="add" label="Год" data-test="sudz-yr-add" @click="openCreateYear" />
      <QBtn flat dense icon="refresh" :loading="store.loading" aria-label="Обновить" @click="store.loadYears()" />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>{{ store.error }}</QBanner>

    <div class="row col no-wrap q-col-gutter-md">
      <!-- Master ~15% -->
      <div class="col-auto yr-master column" data-test="sudz-yr-master">
        <FemsqTable
          class="yr-list-table"
          root-class="yr-list-table"
          row-key="yrKey"
          :rows="store.years"
          :columns="yearColumns"
          :loading="store.loading"
          selection="single"
          v-model:selected="selectedYearRows"
          hide-bottom
          :rows-per-page-options="[0]"
          @row-click="onYearClick"
        />
      </div>

      <!-- Detail -->
      <div class="col column no-wrap" data-test="sudz-yr-detail">
        <template v-if="store.selectedYear">
          <QCard flat bordered class="q-mb-sm">
            <QCardSection>
              <div class="row q-col-gutter-sm items-end">
                <div class="col-12 col-md-4">
                  <QInput v-model="form.variant" dense outlined label="yr_variant" data-test="sudz-yr-variant" />
                </div>
                <div class="col-12 col-md-4">
                  <QSelect
                    v-model="form.baseUplKey"
                    :options="uplOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    label="База (cn_inv_dbt_upl)"
                    data-test="sudz-yr-base-upl"
                  />
                </div>
                <div class="col-6 col-md-2">
                  <QSelect
                    v-model="form.yKey"
                    :options="yyyyOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    label="yyyy"
                    data-test="sudz-yr-yyyy"
                  />
                </div>
                <div class="col-6 col-md-2">
                  <QSelect
                    v-model="form.cmmGrKey"
                    :options="cmmOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    clearable
                    label="yr_CmmGr"
                    data-test="sudz-yr-cmm"
                  />
                </div>
              </div>
              <div class="row q-gutter-sm q-mt-sm">
                <QBtn
                  color="primary"
                  unelevated
                  no-caps
                  label="Сохранить"
                  :loading="store.saving"
                  data-test="sudz-yr-save"
                  @click="onSaveYear"
                />
                <QBtn
                  flat
                  dense
                  no-caps
                  color="negative"
                  label="Удалить год"
                  :disable="store.saving"
                  @click="onDeleteYear"
                />
              </div>
            </QCardSection>
          </QCard>

          <QTabs v-model="tab" dense align="left" class="q-mb-sm">
            <QTab name="upls" label="Выгрузки" data-test="sudz-yr-tab-upls" />
            <QTab name="progress" label="Ход (Progress)" data-test="sudz-yr-tab-progress" />
          </QTabs>

          <QTabPanels v-model="tab" class="col">
            <QTabPanel name="upls" class="q-pa-none">
              <div class="row items-center q-mb-sm q-gutter-sm">
                <QSelect
                  v-model="addUplKey"
                  :options="uplOptions"
                  emit-value
                  map-options
                  dense
                  outlined
                  clearable
                  label="Добавить существующую upl"
                  style="min-width: 280px"
                />
                <QBtn flat dense no-caps color="primary" label="Добавить" :disable="addUplKey == null" @click="onAddExistingUpl" />
                <QBtn flat dense no-caps label="Новая выгрузка…" @click="uplDialog.open = true" />
              </div>

              <div class="upls-tree" data-test="sudz-yr-upls-tree">
                <table>
                  <thead>
                    <tr>
                      <th class="col-expand" />
                      <th>upl_name</th>
                      <th>upl_date</th>
                      <th>uplStatusOnDate</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    <template v-if="store.yearUpls.length === 0">
                      <tr>
                        <td colspan="5" class="text-grey-7 q-pa-md">Выгрузки не привязаны</td>
                      </tr>
                    </template>
                    <template v-for="upl in store.yearUpls" :key="upl.yrUplPKey">
                      <tr
                        class="tree-row"
                        :class="{ 'tree-row--expanded': store.isUplExpanded(upl.uplKey) }"
                      >
                        <td class="col-expand">
                          <QBtn
                            flat
                            dense
                            round
                            size="sm"
                            :icon="store.isUplExpanded(upl.uplKey) ? 'expand_more' : 'chevron_right'"
                            @click="store.toggleUplExpanded(upl.uplKey)"
                          />
                        </td>
                        <td>{{ upl.uplName ?? '—' }}</td>
                        <td>{{ upl.uplDate ?? '—' }}</td>
                        <td>{{ upl.uplStatusOnDate ?? '—' }}</td>
                        <td>
                          <QBtn flat dense icon="delete" size="sm" color="negative" @click="onRemoveUpl(upl.yrUplPKey)" />
                        </td>
                      </tr>
                      <template v-if="store.isUplExpanded(upl.uplKey)">
                        <tr v-for="link in upl.pmLinks" :key="link.gPKey" class="tree-row tree-row--l2">
                          <td class="col-expand" />
                          <td colspan="2">{{ link.pmName ?? '—' }}</td>
                          <td>{{ link.pmDate ?? '—' }}</td>
                          <td>
                            <QBtn flat dense icon="link_off" size="sm" @click="onUnlinkPm(link.gPKey)" />
                          </td>
                        </tr>
                        <tr class="tree-row tree-row--l2">
                          <td class="col-expand" />
                          <td colspan="4">
                            <div class="row q-gutter-sm items-center">
                              <QSelect
                                v-model="pmPick[upl.uplKey]"
                                :options="pmOptions"
                                emit-value
                                map-options
                                dense
                                outlined
                                clearable
                                label="Платёжная выгрузка"
                                style="min-width: 220px"
                              />
                              <QBtn
                                flat
                                dense
                                no-caps
                                color="primary"
                                label="Связать"
                                :disable="pmPick[upl.uplKey] == null"
                                @click="onLinkPm(upl.uplKey)"
                              />
                              <QBtn flat dense no-caps label="Новая pm…" @click="openPmDialog(upl.uplKey)" />
                            </div>
                          </td>
                        </tr>
                      </template>
                    </template>
                  </tbody>
                </table>
              </div>
            </QTabPanel>

            <QTabPanel name="progress" class="q-pa-none column">
              <div class="row q-col-gutter-sm items-end q-mb-sm" data-test="sudz-progress-launcher">
                <div class="col-12 col-md-3">
                  <QSelect
                    v-model="progress.docType"
                    :options="docTypeOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    label="Тип документа"
                    data-test="sudz-progress-doc-type"
                  />
                </div>
                <div class="col-12 col-md-3">
                  <QSelect
                    v-model="progress.asOfUpl"
                    :options="yearUplOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    label="Срез / до выгрузки"
                    data-test="sudz-progress-as-of"
                  />
                </div>
                <div class="col-12 col-md-4">
                  <QInput
                    :model-value="exportFolderLabel"
                    dense
                    outlined
                    readonly
                    label="Папка выгрузки Excel"
                    data-test="sudz-progress-export-folder"
                  >
                    <template #append>
                      <QBtn
                        flat
                        dense
                        no-caps
                        icon="folder_open"
                        :disable="!directoryPickerSupported"
                        :title="
                          directoryPickerSupported
                            ? 'Выбрать папку'
                            : 'Браузер не поддерживает выбор папки — файл уйдёт в Загрузки'
                        "
                        data-test="sudz-progress-pick-folder"
                        @click="onPickExportFolder"
                      />
                    </template>
                  </QInput>
                </div>
                <div class="col-12 col-md-3">
                  <QOptionGroup
                    v-model="progress.resultMode"
                    :options="resultModeOptions"
                    type="radio"
                    dense
                    inline
                    data-test="sudz-progress-result-mode"
                  />
                </div>
                <div class="col-auto">
                  <QBtn
                    color="primary"
                    unelevated
                    no-caps
                    label="Сформировать"
                    :loading="progress.busy"
                    :disable="!canRunProgress"
                    data-test="sudz-progress-run"
                    @click="onRunProgress"
                  />
                </div>
              </div>
              <div v-if="!directoryPickerSupported" class="text-caption text-grey-7 q-mb-sm">
                Выбор папки недоступен в этом браузере (нужен Chrome/Edge). Excel сохранится через
                обычную загрузку браузера.
              </div>
              <QBanner v-if="progress.error" class="bg-negative text-white q-mb-sm" rounded>
                {{ progress.error }}
              </QBanner>
              <QTabs v-model="progress.subTab" dense align="left" class="q-mb-sm">
                <QTab name="log" label="Лог (yr_Progress)" />
                <QTab name="proto" label="Прототип" data-test="sudz-progress-tab-proto" />
              </QTabs>
              <QTabPanels v-model="progress.subTab" class="col">
                <QTabPanel name="log" class="q-pa-none">
                  <QInput
                    :model-value="store.selectedYear.progress ?? ''"
                    type="textarea"
                    autogrow
                    outlined
                    readonly
                    label="yr_Progress (только чтение)"
                    data-test="sudz-yr-progress"
                  />
                </QTabPanel>
                <QTabPanel name="proto" class="q-pa-none">
                  <div v-if="!progress.protoRows.length" class="text-grey-7 q-pa-sm">
                    Сформируйте «Rslt сбор» в режиме прототипа.
                  </div>
                  <div v-else class="text-caption q-mb-xs">
                    Rslt сбор · yr {{ store.selectedYear.yrKey }} · до upl {{ progress.asOfUpl }} ·
                    долгов: {{ progress.protoRows.length }}
                  </div>
                  <FemsqTable
                    v-if="progress.protoRows.length"
                    class="progress-proto-table"
                    root-class="progress-proto-table"
                    row-key="dbtKey"
                    :rows="progress.protoRows"
                    :columns="protoColumns"
                    dense
                    hide-bottom
                    :rows-per-page-options="[0]"
                    data-test="sudz-progress-proto-table"
                  />
                </QTabPanel>
              </QTabPanels>
            </QTabPanel>
          </QTabPanels>
        </template>
        <div v-else class="text-grey-7 q-pa-md">Выберите год-вариант слева или создайте новый.</div>
      </div>
    </div>

    <!-- Create year dialog -->
    <QDialog v-model="createDialog.open" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-subtitle1">Новый год-вариант</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="createDialog.variant" dense outlined label="yr_variant" />
          <QSelect
            v-model="createDialog.yKey"
            :options="yyyyOptions"
            emit-value
            map-options
            dense
            outlined
            label="yyyy"
          />
          <QSelect
            v-model="createDialog.cmmGrKey"
            :options="cmmOptions"
            emit-value
            map-options
            dense
            outlined
            clearable
            label="yr_CmmGr"
          />
          <QSelect
            v-model="createDialog.baseUplKey"
            :options="uplOptions"
            emit-value
            map-options
            dense
            outlined
            clearable
            label="Существующая база upl (или заполните новую ниже)"
          />
          <QSeparator />
          <div class="text-caption text-grey-7">Новая базовая выгрузка (если не выбрана существующая)</div>
          <QInput v-model="createDialog.newUplName" dense outlined label="upl_name" />
          <QInput v-model="createDialog.newUplDate" dense outlined type="date" label="upl_date" />
          <QInput v-model="createDialog.newUplStatusOnDate" dense outlined type="date" label="uplStatusOnDate" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn color="primary" unelevated no-caps label="Создать" :loading="store.saving" @click="onCreateYear" />
        </QCardActions>
      </QCard>
    </QDialog>

    <!-- New upl dialog -->
    <QDialog v-model="uplDialog.open" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-subtitle1">Новая выгрузка ДЗ</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="uplDialog.name" dense outlined label="upl_name" />
          <QInput v-model="uplDialog.uplDate" dense outlined type="date" label="upl_date" />
          <QInput v-model="uplDialog.statusOnDate" dense outlined type="date" label="uplStatusOnDate" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn color="primary" unelevated no-caps label="Создать и добавить" :loading="store.saving" @click="onCreateUpl" />
        </QCardActions>
      </QCard>
    </QDialog>

    <!-- New pm dialog -->
    <QDialog v-model="pmDialog.open" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-subtitle1">Новая платёжная выгрузка</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="pmDialog.name" dense outlined label="cn_inv_pm_name" />
          <QInput v-model="pmDialog.date" dense outlined type="date" label="cn_inv_pm_date" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn color="primary" unelevated no-caps label="Создать и связать" :loading="store.saving" @click="onCreatePm" />
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
  QDialog,
  QInput,
  QOptionGroup,
  QPage,
  QSelect,
  QSeparator,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { appendSudzYearProgress, downloadSudzRsltSbornExcel, getSudzYrDbtChanges } from '@/api/sudz-api';
import { useSudzPortfolioStore } from '@/stores/sudz-portfolio';
import type { SudzRsltDebt, SudzYear } from '@/types/sudz';
import {
  getRememberedDirectoryName,
  pickExportDirectory,
  saveBlobToExportFolder,
  supportsDirectoryPicker
} from '@/utils/export-folder';

const store = useSudzPortfolioStore();
const $q = useQuasar();

const tab = ref<'upls' | 'progress'>('upls');
const selectedYearRows = ref<SudzYear[]>([]);
const addUplKey = ref<number | null>(null);
const pmPick = reactive<Record<number, number | null>>({});

const directoryPickerSupported = supportsDirectoryPicker();
const exportFolderName = ref<string | null>(null);

const exportFolderLabel = computed(() => {
  if (!directoryPickerSupported) {
    return 'Загрузки браузера (выбор папки недоступен)';
  }
  return exportFolderName.value
    ? exportFolderName.value
    : 'Не выбрана — спросим при первой выгрузке Excel';
});

type DocType = 'rslt_sborn' | 'rslt_povtor' | 'd644' | 'svod';
type ResultMode = 'proto' | 'excel';

const progress = reactive({
  docType: 'rslt_sborn' as DocType,
  asOfUpl: null as number | null,
  resultMode: 'proto' as ResultMode,
  subTab: 'log' as 'log' | 'proto',
  busy: false,
  error: '' as string,
  protoRows: [] as SudzRsltDebt[]
});

const docTypeOptions = [
  { label: 'Rslt сбор', value: 'rslt_sborn' },
  { label: 'Rslt повтор (скоро)', value: 'rslt_povtor', disable: true },
  { label: 'D644 (скоро)', value: 'd644', disable: true },
  { label: 'Свод (скоро)', value: 'svod', disable: true }
];

const resultModeOptions = [
  { label: 'Прототип UI', value: 'proto' },
  { label: 'Excel', value: 'excel' }
];

const yearUplOptions = computed(() =>
  (store.yearUpls ?? []).map((u) => ({
    label: `${u.uplKey}: ${u.uplName ?? '—'} (${u.uplDate ?? '—'})`,
    value: u.uplKey
  }))
);

const canRunProgress = computed(
  () =>
    Boolean(store.selectedYear?.yrKey) &&
    progress.docType === 'rslt_sborn' &&
    progress.asOfUpl != null &&
    !progress.busy
);

const protoColumns: FemsqTableColumn<SudzRsltDebt>[] = [
  { name: 'dbtKey', label: 'dbtKey', field: 'dbtKey', align: 'right', sortable: true },
  { name: 'accountNum', label: 'СГК', field: 'accountNum', align: 'left' },
  { name: 'curator', label: 'Куратор', field: 'curator', align: 'left' },
  { name: 'mery', label: 'Мероприятия', field: 'mery', align: 'left' },
  { name: 'cstCode', label: 'Код стройки', field: 'cstCode', align: 'left' },
  { name: 'cstName', label: 'Стройка', field: 'cstName', align: 'left' }
];

const form = reactive({
  variant: '',
  baseUplKey: null as number | null,
  yKey: null as number | null,
  cmmGrKey: null as number | null
});

const createDialog = reactive({
  open: false,
  variant: '',
  yKey: null as number | null,
  cmmGrKey: null as number | null,
  baseUplKey: null as number | null,
  newUplName: '',
  newUplDate: '',
  newUplStatusOnDate: ''
});

const uplDialog = reactive({
  open: false,
  name: '',
  uplDate: '',
  statusOnDate: ''
});

const pmDialog = reactive({
  open: false,
  dbtUplKey: null as number | null,
  name: '',
  date: ''
});

const yearColumns: FemsqTableColumn<SudzYear>[] = [
  {
    name: 'yrVariant',
    label: 'yr_variant',
    field: 'yrVariant',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.yrVariant ?? '')
  }
];

const uplOptions = computed(() =>
  store.uplLookups.map((u) => ({
    label: `${u.uplKey}: ${u.uplName ?? '—'} (${u.uplDate ?? '—'})`,
    value: u.uplKey
  }))
);

const yyyyOptions = computed(() =>
  store.yyyyLookups.map((y) => ({
    label: String(y.yyyy),
    value: y.yKey
  }))
);

const cmmOptions = computed(() =>
  store.cmmGrLookups.map((c) => ({
    label: `${c.cmmGrKey}: ${c.name ?? '—'} (${c.date ?? '—'})`,
    value: c.cmmGrKey
  }))
);

const pmOptions = computed(() =>
  store.pmLookups.map((p) => ({
    label: `${p.pmKey}: ${p.name ?? '—'} (${p.date ?? '—'})`,
    value: p.pmKey
  }))
);

watch(
  () => store.selectedYear,
  (year) => {
    selectedYearRows.value = year ? [year] : [];
    form.variant = year?.yrVariant ?? '';
    form.baseUplKey = year?.baseUpl ?? null;
    form.yKey = year?.yyyy ?? null;
    form.cmmGrKey = year?.cmmGr ?? null;
    progress.protoRows = [];
    progress.error = '';
  },
  { immediate: true }
);

watch(
  () => store.yearUpls,
  (upls) => {
    if (!upls.length) {
      progress.asOfUpl = null;
      return;
    }
    const stillValid = upls.some((u) => u.uplKey === progress.asOfUpl);
    if (!stillValid) {
      const last = upls[upls.length - 1];
      progress.asOfUpl = last?.uplKey ?? null;
    }
  },
  { immediate: true }
);

/**
 * Выбор папки для Excel (системный диалог Win/Linux).
 */
async function onPickExportFolder(): Promise<void> {
  if (!directoryPickerSupported) {
    $q.notify({
      type: 'info',
      message: 'Выбор папки доступен в Chrome/Edge. Иначе файл уйдёт в Загрузки браузера.'
    });
    return;
  }
  try {
    const name = await pickExportDirectory();
    if (name) {
      exportFolderName.value = name;
      $q.notify({ type: 'positive', message: `Папка выгрузки: ${name}`, timeout: 1500 });
    }
  } catch (error) {
    progress.error = error instanceof Error ? error.message : String(error);
  }
}

/**
 * Запуск лаунчера Progress: Rslt сбор → прототип или Excel.
 */
async function onRunProgress(): Promise<void> {
  const yr = store.selectedYear?.yrKey;
  if (yr == null || progress.asOfUpl == null || progress.docType !== 'rslt_sborn') {
    return;
  }
  progress.busy = true;
  progress.error = '';
  try {
    if (progress.resultMode === 'proto') {
      progress.protoRows = await getSudzYrDbtChanges(yr, progress.asOfUpl);
      progress.subTab = 'proto';
      const line = `[${new Date().toISOString().slice(0, 19).replace('T', ' ')}] Rslt сбор · прототип | yr=${yr} | asOfUpl=${progress.asOfUpl} | долгов=${progress.protoRows.length} | ok`;
      await appendSudzYearProgress(yr, line);
      await store.selectYear(yr);
      $q.notify({
        type: 'positive',
        message: `Прототип Rslt: ${progress.protoRows.length} долг(ов)`,
        timeout: 1500
      });
    } else {
      const { blob, fileName } = await downloadSudzRsltSbornExcel(yr, progress.asOfUpl);
      const saved = await saveBlobToExportFolder(blob, fileName);
      await store.selectYear(yr);
      if (saved.method === 'directory') {
        exportFolderName.value = saved.folderName;
        $q.notify({
          type: 'positive',
          message: `Excel сохранён в «${saved.folderName}»`,
          timeout: 2000
        });
      } else {
        $q.notify({
          type: 'positive',
          message: 'Excel скачан через браузер (Загрузки / Сохранить как)',
          timeout: 2000
        });
      }
    }
  } catch (error) {
    progress.error = error instanceof Error ? error.message : String(error);
  } finally {
    progress.busy = false;
  }
}

onMounted(() => {
  void store.loadYears();
  void getRememberedDirectoryName().then((name) => {
    exportFolderName.value = name;
  });
});

function onYearClick(_evt: Event, row: SudzYear): void {
  void store.selectYear(row.yrKey);
}

function openCreateYear(): void {
  createDialog.variant = '';
  createDialog.yKey = store.yyyyLookups[0]?.yKey ?? null;
  createDialog.cmmGrKey = null;
  createDialog.baseUplKey = null;
  createDialog.newUplName = '';
  createDialog.newUplDate = '';
  createDialog.newUplStatusOnDate = '';
  createDialog.open = true;
}

async function onSaveYear(): Promise<void> {
  if (store.selectedYrKey == null || form.baseUplKey == null || form.yKey == null || !form.variant.trim()) {
    $q.notify({ type: 'warning', message: 'Заполните variant, базу upl и yyyy' });
    return;
  }
  const ok = await store.saveYear({
    yrKey: store.selectedYrKey,
    variant: form.variant.trim(),
    baseUplKey: form.baseUplKey,
    yKey: form.yKey,
    cmmGrKey: form.cmmGrKey
  });
  if (ok) $q.notify({ type: 'positive', message: 'Год сохранён', timeout: 1200 });
}

function onDeleteYear(): void {
  if (store.selectedYrKey == null) return;
  $q.dialog({
    title: 'Удалить год-вариант?',
    message: form.variant || String(store.selectedYrKey),
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeYear(store.selectedYrKey!);
  });
}

async function onCreateYear(): Promise<void> {
  if (!createDialog.variant.trim() || createDialog.yKey == null) {
    $q.notify({ type: 'warning', message: 'Укажите variant и yyyy' });
    return;
  }
  if (createDialog.baseUplKey == null && (!createDialog.newUplName.trim() || !createDialog.newUplStatusOnDate)) {
    $q.notify({ type: 'warning', message: 'Выберите базу upl или заполните новую выгрузку' });
    return;
  }
  const ok = await store.createYear({
    variant: createDialog.variant.trim(),
    yKey: createDialog.yKey,
    cmmGrKey: createDialog.cmmGrKey,
    baseUplKey: createDialog.baseUplKey,
    newUplName: createDialog.baseUplKey == null ? createDialog.newUplName.trim() : null,
    newUplDate: createDialog.baseUplKey == null ? createDialog.newUplDate || null : null,
    newUplStatusOnDate: createDialog.baseUplKey == null ? createDialog.newUplStatusOnDate : null
  });
  if (ok) {
    createDialog.open = false;
    $q.notify({ type: 'positive', message: 'Год создан', timeout: 1200 });
  }
}

async function onAddExistingUpl(): Promise<void> {
  if (store.selectedYrKey == null || addUplKey.value == null) return;
  const ok = await store.addUpl(store.selectedYrKey, addUplKey.value);
  if (ok) {
    addUplKey.value = null;
    $q.notify({ type: 'positive', message: 'Выгрузка добавлена', timeout: 1200 });
  }
}

async function onCreateUpl(): Promise<void> {
  if (store.selectedYrKey == null || !uplDialog.name.trim() || !uplDialog.statusOnDate) {
    $q.notify({ type: 'warning', message: 'Укажите name и uplStatusOnDate' });
    return;
  }
  const ok = await store.createAndAddUpl(store.selectedYrKey, {
    name: uplDialog.name.trim(),
    uplDate: uplDialog.uplDate || null,
    statusOnDate: uplDialog.statusOnDate
  });
  if (ok) {
    uplDialog.open = false;
    $q.notify({ type: 'positive', message: 'Выгрузка создана', timeout: 1200 });
  }
}

function onRemoveUpl(yrUplPKey: number): void {
  $q.dialog({
    title: 'Убрать выгрузку из года?',
    cancel: true
  }).onOk(() => {
    void store.removeUpl(yrUplPKey);
  });
}

function openPmDialog(dbtUplKey: number): void {
  pmDialog.dbtUplKey = dbtUplKey;
  pmDialog.name = '';
  pmDialog.date = '';
  pmDialog.open = true;
}

async function onLinkPm(dbtUplKey: number): Promise<void> {
  const pmKey = pmPick[dbtUplKey];
  if (pmKey == null) return;
  const ok = await store.linkPm(dbtUplKey, pmKey);
  if (ok) {
    pmPick[dbtUplKey] = null;
    $q.notify({ type: 'positive', message: 'Связь добавлена', timeout: 1200 });
  }
}

async function onCreatePm(): Promise<void> {
  if (pmDialog.dbtUplKey == null || !pmDialog.date) {
    $q.notify({ type: 'warning', message: 'Укажите дату платёжной выгрузки' });
    return;
  }
  const ok = await store.createAndLinkPm(pmDialog.dbtUplKey, {
    name: pmDialog.name.trim() || null,
    date: pmDialog.date
  });
  if (ok) {
    pmDialog.open = false;
    $q.notify({ type: 'positive', message: 'Платёжная выгрузка создана', timeout: 1200 });
  }
}

function onUnlinkPm(gPKey: number): void {
  void store.unlinkPm(gPKey);
}
</script>

<style scoped>
.sudz-yr-view {
  min-height: 0;
}

.yr-master {
  width: 15%;
  min-width: 160px;
  max-width: 240px;
}

.yr-list-table {
  min-height: 240px;
}

.upls-tree {
  overflow: auto;
  max-height: calc(100vh - 320px);
}

.upls-tree table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.upls-tree th,
.upls-tree td {
  border-bottom: 1px solid var(--femsq-border, #e0e0e0);
  padding: 4px 8px;
  text-align: left;
}

.col-expand {
  width: 36px;
}

.tree-row--l2 td {
  background: rgba(0, 0, 0, 0.02);
  padding-left: 12px;
}
</style>
