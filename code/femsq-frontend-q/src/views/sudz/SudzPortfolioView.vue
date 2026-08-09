<template>
  <QPage class="q-pa-none sudz-yr-page" data-test="sudz-portfolio-view">
    <!-- absolute-full: область = viewport; широкая таблица не раздувает страницу -->
    <div class="absolute-full q-pa-md column no-wrap sudz-yr-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Портфель года</div>
        <div class="femsq-page-subtitle">СУДЗ · год-вариант (yr)</div>
      </div>
      <QBtn flat dense no-caps color="primary" icon="add" label="Год" data-test="sudz-yr-add" @click="openCreateYear" />
      <QBtn flat dense icon="refresh" :loading="store.loading" aria-label="Обновить" @click="store.loadYears()" />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>{{ store.error }}</QBanner>

    <div class="row col no-wrap sudz-yr-body">
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
      <div class="col column no-wrap yr-detail" data-test="sudz-yr-detail">
        <template v-if="store.selectedYear">
          <QCard flat bordered class="q-mb-sm yr-header-card">
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

          <QTabPanels v-model="tab" :animated="false" class="yr-detail-panels">
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

            <QTabPanel name="progress" class="q-pa-none column progress-tab">
              <div class="row q-col-gutter-sm items-end q-mb-sm" data-test="sudz-progress-launcher">
                <div class="col-12 col-md-5">
                  <QSelect
                    v-model="progress.operation"
                    :options="operationOptions"
                    emit-value
                    map-options
                    dense
                    outlined
                    label="Операция"
                    data-test="sudz-progress-operation"
                  />
                </div>
                <div v-if="isExportOp" class="col-12 col-md-3">
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
                <div v-if="isPovtorExport" class="col-12 col-md-4">
                  <QInput
                    :model-value="cmmGrNewReadOnlyLabel"
                    dense
                    outlined
                    readonly
                    label="Группа новых (yr_CmmGr_New)"
                    hint="Источник колонок *_new (только чтение)"
                    data-test="sudz-progress-cmm-new-ro"
                  />
                </div>
                <div v-if="isExportOp" class="col-12 col-md-3">
                  <QOptionGroup
                    v-model="progress.resultMode"
                    :options="resultModeOptions"
                    type="radio"
                    dense
                    inline
                    data-test="sudz-progress-result-mode"
                  />
                </div>
                <div
                  v-if="isExportOp && progress.resultMode === 'excel' && !isImportOp"
                  class="col-12 col-md-4"
                >
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
                <template v-if="isImportOp">
                    <div class="col-12 col-md-5">
                    <div class="row q-gutter-xs items-end no-wrap">
                      <div class="col">
                        <QSelect
                          v-model="progress.cmmGrNewKey"
                          :options="cmmOptions"
                          emit-value
                          map-options
                          dense
                          outlined
                          clearable
                          label="Группа новых (yr_CmmGr_New)"
                          data-test="sudz-progress-cmm-new"
                        />
                      </div>
                      <QBtn
                        flat
                        dense
                        no-caps
                        icon="add"
                        label="Создать"
                        class="q-mb-xs"
                        data-test="sudz-progress-cmm-new-create"
                        @click="openCreateCmmGr"
                      />
                    </div>
                  </div>
                  <div class="col-12 col-md-4">
                    <QFile
                      v-model="progress.returnFile"
                      dense
                      outlined
                      clearable
                      accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                      label="Файл возврата (.xlsx)"
                      data-test="sudz-progress-return-file"
                    />
                  </div>
                </template>
                <div class="col-auto">
                  <QBtn
                    color="primary"
                    unelevated
                    no-caps
                    label="Выполнить"
                    :loading="progress.busy"
                    :disable="!canRunProgress"
                    data-test="sudz-progress-run"
                    @click="onRunProgress"
                  />
                </div>
              </div>
              <div
                v-if="
                  isExportOp &&
                  progress.resultMode === 'excel' &&
                  !directoryPickerSupported
                "
                class="text-caption text-grey-7 q-mb-sm"
              >
                Выбор папки недоступен в этом браузере (нужен Chrome/Edge). Excel сохранится через
                обычную загрузку браузера.
              </div>
              <QBanner v-if="progress.error" class="bg-negative text-white q-mb-sm" rounded>
                {{ progress.error }}
              </QBanner>
              <QTabs v-model="progress.subTab" dense align="left" class="q-mb-sm">
                <QTab name="log" label="Лог (yr_Progress)" />
                <QTab name="proto" label="Предпросмотр" data-test="sudz-progress-tab-proto" />
              </QTabs>
              <!-- Без QTabPanels: .q-panel.scroll раздувает ширину после proto-таблицы и «сдвигает» лог. -->
              <div class="progress-subpanels">
                <div
                  v-if="progress.subTab === 'log'"
                  class="progress-log-panel"
                >
                  <div class="text-caption text-grey-7 q-mb-xs">
                    yr_Progress (только чтение) · новые сверху · до 100 строк
                  </div>
                  <pre class="progress-log-pre" data-test="sudz-yr-progress">{{
                    store.selectedYear.progress ?? ''
                  }}</pre>
                </div>
                <div
                  v-else
                  class="progress-proto-panel"
                >
                  <div v-if="!progress.protoRows.length" class="text-grey-7 q-pa-sm">
                    Выполните «Rslt … / D644 / Свод · Выгрузить» в режиме «Предпросмотр» —
                    таблица как в Excel (фильтр; у Rslt сбора колонки *_new пустые).
                  </div>
                  <div v-else class="progress-proto-body">
                      <div class="progress-proto-toolbar">
                        <div class="progress-proto-caption text-caption">
                          Предпросмотр Excel · {{ operationLabel }} · yr
                          {{ store.selectedYear.yrKey }} · до upl {{ progress.asOfUpl }} · долгов:
                          {{ filteredProtoRows.length }}/{{ progress.protoRows.length }} · срезов:
                          {{ progress.protoSliceCount }}
                          <span v-if="!progress.protoFillNew"> · *_new пустые (сбор)</span>
                          · клик по ячейке — полный текст внизу
                        </div>
                        <QBtn
                          dense
                          unelevated
                          no-caps
                          color="primary"
                          label="Выгрузить в Excel"
                          :loading="progress.busy"
                          data-test="sudz-progress-proto-to-excel"
                          @click="onProtoToExcel"
                        />
                      </div>
                      <QInput
                        v-model="progress.protoFilter"
                        dense
                        clearable
                        outlined
                        debounce="200"
                        class="progress-proto-filter"
                        label="Фильтр по всем колонкам"
                        data-test="sudz-progress-proto-filter"
                      >
                        <template #prepend>
                          <QIcon name="search" />
                        </template>
                      </QInput>
                      <div ref="protoScrollFrameEl" class="progress-proto-frame" data-test="sudz-progress-proto-scroll">
                        <div class="progress-proto-scroll">
                          <table class="progress-proto-native" data-test="sudz-progress-proto-table">
                            <thead>
                              <tr class="proto-header-row">
                                <th
                                  v-for="col in progress.protoColumns"
                                  :key="col.name"
                                  :title="col.label"
                                  :class="
                                    typeof col.headerClasses === 'string' ? col.headerClasses : undefined
                                  "
                                >
                                  <div class="proto-header-label">{{ col.label }}</div>
                                </th>
                              </tr>
                              <tr class="proto-filter-row">
                                <th v-for="col in progress.protoColumns" :key="'f-' + col.name">
                                  <input
                                    v-model="progress.protoColumnFilters[col.name]"
                                    type="search"
                                    class="proto-col-filter"
                                    :aria-label="'Фильтр: ' + col.label"
                                    data-test="sudz-progress-proto-col-filter"
                                    @click.stop
                                    @keydown.stop
                                  />
                                </th>
                              </tr>
                            </thead>
                            <tbody>
                              <tr v-for="row in filteredProtoRows" :key="row.dbtKey">
                                <td
                                  v-for="col in progress.protoColumns"
                                  :key="col.name"
                                  :class="{
                                    'proto-td--selected':
                                      protoCell.dbtKey === row.dbtKey &&
                                      protoCell.colName === col.name,
                                    'proto-c--overd':
                                      typeof col.classes === 'string' && col.classes.includes('overd')
                                  }"
                                  @click="onProtoCellSelect(row, col)"
                                >
                                  <div class="proto-cell-one-line">{{ formatProtoCell(row, col) }}</div>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                      </div>
                      <div class="proto-cell-detail" data-test="sudz-progress-proto-detail">
                        <div class="text-caption text-grey-7 q-mb-xs">
                          <template v-if="protoCell.dbtKey != null">
                            dbtKey {{ protoCell.dbtKey }} · {{ protoCell.colLabel }}
                          </template>
                          <template v-else>Выберите ячейку таблицы</template>
                        </div>
                        <div class="proto-cell-detail__body">{{ protoCell.text || '—' }}</div>
                      </div>
                    </div>
                </div>
              </div>
            </QTabPanel>
          </QTabPanels>
        </template>
        <div v-else class="text-grey-7 q-pa-md">Выберите год-вариант слева или создайте новый.</div>
      </div>
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

    <!-- Create CmmGr for yr_CmmGr_New -->
    <QDialog v-model="cmmGrDialog.open" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-subtitle1">Новая группа комментариев</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="cmmGrDialog.name" dense outlined label="Имя группы" data-test="sudz-cmmgr-name" />
          <QInput
            v-model="cmmGrDialog.date"
            dense
            outlined
            type="date"
            label="Дата"
            data-test="sudz-cmmgr-date"
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
            data-test="sudz-cmmgr-create"
            @click="onCreateCmmGr"
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
  QDialog,
  QFile,
  QIcon,
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

import {
  appendSudzYearProgress,
  downloadSudzD644Excel,
  downloadSudzD644SvodExcel,
  downloadSudzRsltExcel,
  getSudzD644,
  getSudzD644Svod,
  getSudzYrDbtChanges,
  uploadSudzRsltReturn
} from '@/api/sudz-api';
import { useSudzPortfolioStore } from '@/stores/sudz-portfolio';
import type { SudzYear } from '@/types/sudz';
import {
  getRememberedDirectoryName,
  pickExportDirectory,
  saveBlobToExportFolder,
  supportsDirectoryPicker
} from '@/utils/export-folder';
import { buildSudzD644Preview } from '@/utils/sudz-d644-preview';
import {
  buildSudzRsltPreview,
  type SudzRsltPreviewRow
} from '@/utils/sudz-rslt-preview';
import { buildSudzSvodPreview } from '@/utils/sudz-svod-preview';

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

type ProgressOperation =
  | 'rslt_sborn_export'
  | 'rslt_povtor_export'
  | 'rslt_povtor_import'
  | 'd644_export'
  | 'svod_export';
type ResultMode = 'proto' | 'excel';

const progress = reactive({
  operation: 'rslt_sborn_export' as ProgressOperation,
  asOfUpl: null as number | null,
  resultMode: 'proto' as ResultMode,
  cmmGrNewKey: null as number | null,
  returnFile: null as File | null,
  subTab: 'log' as 'log' | 'proto',
  busy: false,
  error: '' as string,
  protoRows: [] as SudzRsltPreviewRow[],
  protoColumns: [] as FemsqTableColumn<SudzRsltPreviewRow>[],
  protoFilter: '',
  /** Поколоночные фильтры (AND с глобальным). */
  protoColumnFilters: {} as Record<string, string>,
  protoFillNew: false,
  protoSliceCount: 0
});

/** Выбранная ячейка предпросмотра — полный текст в нижней панели. */
const protoCell = reactive({
  dbtKey: null as number | null,
  colName: '',
  colLabel: '',
  text: ''
});

const protoScrollFrameEl = ref<HTMLElement | null>(null);

/**
 * Метка времени для yr_Progress: локальное время, формат как у backend Excel.
 */
function progressTimestamp(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

const operationOptions = [
  { label: 'Rslt сбор · Выгрузить', value: 'rslt_sborn_export' },
  { label: 'Rslt повтор · Выгрузить', value: 'rslt_povtor_export' },
  { label: 'Rslt повтор · Загрузить', value: 'rslt_povtor_import' },
  { label: 'D644 · Выгрузить', value: 'd644_export' },
  { label: 'Свод · Выгрузить', value: 'svod_export' }
];

const resultModeOptions = [
  { label: 'Предпросмотр', value: 'proto' },
  { label: 'Excel', value: 'excel' }
];

const isExportOp = computed(
  () =>
    progress.operation === 'rslt_sborn_export' ||
    progress.operation === 'rslt_povtor_export' ||
    progress.operation === 'd644_export' ||
    progress.operation === 'svod_export'
);
const isImportOp = computed(() => progress.operation === 'rslt_povtor_import');
const isPovtorExport = computed(() => progress.operation === 'rslt_povtor_export');
const isRsltExport = computed(
  () => progress.operation === 'rslt_sborn_export' || progress.operation === 'rslt_povtor_export'
);
const isD644Export = computed(() => progress.operation === 'd644_export');
const isSvodExport = computed(() => progress.operation === 'svod_export');
const isD644OrSvodExport = computed(() => isD644Export.value || isSvodExport.value);
const operationLabel = computed(
  () => operationOptions.find((o) => o.value === progress.operation)?.label ?? progress.operation
);

const cmmGrNewReadOnlyLabel = computed(() => {
  const year = store.selectedYear;
  if (!year?.cmmGrNew) {
    return 'не задана — сначала «Rslt повтор · Загрузить» / привязка New';
  }
  return `${year.cmmGrNew}: ${year.cmmGrNewName ?? '—'} (${year.cmmGrNewDate ?? '—'})`;
});

const yearUplOptions = computed(() =>
  (store.yearUpls ?? []).map((u) => ({
    label: `${u.uplKey}: ${u.uplName ?? '—'} (${u.uplDate ?? '—'})`,
    value: u.uplKey
  }))
);

const canRunProgress = computed(() => {
  if (!store.selectedYear?.yrKey || progress.busy) {
    return false;
  }
  if (isImportOp.value) {
    return progress.cmmGrNewKey != null && progress.returnFile != null;
  }
  if (isRsltExport.value || isD644OrSvodExport.value) {
    return progress.asOfUpl != null;
  }
  return false;
});

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

const cmmGrDialog = reactive({
  open: false,
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
  (year, prevYear) => {
    selectedYearRows.value = year ? [year] : [];
    form.variant = year?.yrVariant ?? '';
    form.baseUplKey = year?.baseUpl ?? null;
    form.yKey = year?.yyyy ?? null;
    form.cmmGrKey = year?.cmmGr ?? null;
    // Не сбрасывать New/файл при refresh того же года (после предпросмотра → append Progress).
    const yearChanged = year?.yrKey !== prevYear?.yrKey;
    if (yearChanged) {
      progress.cmmGrNewKey = year?.cmmGrNew ?? null;
      progress.protoRows = [];
      progress.protoColumns = [];
      progress.protoFilter = '';
      progress.protoColumnFilters = {};
      progress.protoSliceCount = 0;
      progress.protoFillNew = false;
      progress.error = '';
      progress.returnFile = null;
      clearProtoCell();
    } else if (year != null && progress.cmmGrNewKey == null && year.cmmGrNew != null) {
      progress.cmmGrNewKey = year.cmmGrNew;
    }
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
 * Открывает диалог создания группы для yr_CmmGr_New.
 */
function openCreateCmmGr(): void {
  const today = new Date();
  const p = (n: number) => String(n).padStart(2, '0');
  cmmGrDialog.name = '';
  cmmGrDialog.date = `${today.getFullYear()}-${p(today.getMonth() + 1)}-${p(today.getDate())}`;
  cmmGrDialog.open = true;
}

/**
 * Создаёт группу и привязывает к yr_CmmGr_New выбранного года.
 */
async function onCreateCmmGr(): Promise<void> {
  if (!cmmGrDialog.name.trim() || !cmmGrDialog.date) {
    $q.notify({ type: 'warning', message: 'Укажите имя и дату группы' });
    return;
  }
  const created = await store.createCmmGr({
    name: cmmGrDialog.name.trim(),
    date: cmmGrDialog.date
  });
  if (!created) {
    return;
  }
  progress.cmmGrNewKey = created.cmmGrKey;
  cmmGrDialog.open = false;
  const yr = store.selectedYear;
  if (
    yr != null &&
    form.baseUplKey != null &&
    form.yKey != null &&
    form.variant.trim()
  ) {
    await store.saveYear({
      yrKey: yr.yrKey,
      variant: form.variant.trim(),
      baseUplKey: form.baseUplKey,
      yKey: form.yKey,
      cmmGrKey: form.cmmGrKey,
      cmmGrNewKey: created.cmmGrKey
    });
  }
  $q.notify({ type: 'positive', message: `Группа ${created.cmmGrKey} создана`, timeout: 1500 });
}

/**
 * Запуск лаунчера Progress: выгрузка или загрузка возврата.
 */
async function onRunProgress(): Promise<void> {
  const yr = store.selectedYear?.yrKey;
  if (yr == null || !canRunProgress.value) {
    return;
  }
  progress.busy = true;
  progress.error = '';
  try {
    if (isImportOp.value) {
      await runImportReturn(yr);
      return;
    }
    if (isRsltExport.value && progress.asOfUpl != null) {
      await runRsltExport(yr, progress.asOfUpl, progress.operation === 'rslt_povtor_export');
      return;
    }
    if (isD644OrSvodExport.value && progress.asOfUpl != null) {
      await runD644OrSvodExport(yr, progress.asOfUpl);
    }
  } catch (error) {
    progress.error = error instanceof Error ? error.message : String(error);
  } finally {
    progress.busy = false;
  }
}

/**
 * Импорт возврата: при необходимости сохраняет yr_CmmGr_New, затем POST Excel.
 */
async function runImportReturn(yr: number): Promise<void> {
  if (progress.cmmGrNewKey == null || progress.returnFile == null) {
    return;
  }
  if (
    store.selectedYear?.cmmGrNew !== progress.cmmGrNewKey &&
    form.baseUplKey != null &&
    form.yKey != null &&
    form.variant.trim()
  ) {
    const saved = await store.saveYear({
      yrKey: yr,
      variant: form.variant.trim(),
      baseUplKey: form.baseUplKey,
      yKey: form.yKey,
      cmmGrKey: form.cmmGrKey,
      cmmGrNewKey: progress.cmmGrNewKey
    });
    if (!saved) {
      throw new Error(store.error ?? 'Не удалось сохранить yr_CmmGr_New');
    }
  }
  const result = await uploadSudzRsltReturn(yr, progress.returnFile);
  await store.selectYear(yr);
  progress.subTab = 'log';
  $q.notify({
    type: 'positive',
    message: `Загружено долгов: ${result.imported} (из ${result.parsed})`,
    timeout: 2000
  });
}

/**
 * Выгрузка D644 или годового свода (предпросмотр или Excel).
 */
async function runD644OrSvodExport(yr: number, currUpl: number): Promise<void> {
  const isSvod = progress.operation === 'svod_export';
  const label = isSvod ? 'Свод · Выгрузить' : 'D644 · Выгрузить';

  if (progress.resultMode === 'proto') {
    if (isSvod) {
      const svod = await getSudzD644Svod(yr, currUpl);
      const preview = buildSudzSvodPreview(svod);
      progress.protoRows = preview.rows as unknown as SudzRsltPreviewRow[];
      progress.protoColumns = preview.columns as unknown as FemsqTableColumn<SudzRsltPreviewRow>[];
      progress.protoFillNew = false;
      progress.protoSliceCount = 0;
      progress.protoFilter = '';
      progress.protoColumnFilters = Object.fromEntries(preview.columns.map((c) => [c.name, '']));
      clearProtoCell();
      progress.subTab = 'proto';
      await nextTick();
      const scrollRoot = protoScrollFrameEl.value?.querySelector('.progress-proto-scroll');
      if (scrollRoot instanceof HTMLElement) {
        scrollRoot.scrollLeft = 0;
        scrollRoot.scrollTop = 0;
      }
      const line = `[${progressTimestamp()}] Свод · предпросмотр | yr=${yr} | currUpl=${currUpl} | счетов=${preview.rows.length} | ok`;
      await appendSudzYearProgress(yr, line);
      await store.selectYear(yr);
      $q.notify({
        type: 'positive',
        message: `Предпросмотр Свод: ${preview.rows.length} строк(и)`,
        timeout: 1500
      });
      return;
    }

    const rows = await getSudzD644(yr, currUpl);
    const preview = buildSudzD644Preview(rows);
    progress.protoRows = preview.rows as unknown as SudzRsltPreviewRow[];
    progress.protoColumns = preview.columns as unknown as FemsqTableColumn<SudzRsltPreviewRow>[];
    progress.protoFillNew = false;
    progress.protoSliceCount = 0;
    progress.protoFilter = '';
    progress.protoColumnFilters = Object.fromEntries(preview.columns.map((c) => [c.name, '']));
    clearProtoCell();
    progress.subTab = 'proto';
    await nextTick();
    const scrollRoot = protoScrollFrameEl.value?.querySelector('.progress-proto-scroll');
    if (scrollRoot instanceof HTMLElement) {
      scrollRoot.scrollLeft = 0;
      scrollRoot.scrollTop = 0;
    }
    const line = `[${progressTimestamp()}] D644 · предпросмотр | yr=${yr} | currUpl=${currUpl} | строк=${rows.length} | ok`;
    await appendSudzYearProgress(yr, line);
    await store.selectYear(yr);
    $q.notify({
      type: 'positive',
      message: `Предпросмотр D644: ${rows.length} строк(и)`,
      timeout: 1500
    });
    return;
  }

  const { blob, fileName } = isSvod
    ? await downloadSudzD644SvodExcel(yr, currUpl)
    : await downloadSudzD644Excel(yr, currUpl);
  const saved = await saveBlobToExportFolder(blob, fileName);
  await store.selectYear(yr);
  progress.subTab = 'log';
  if (saved.method === 'directory') {
    exportFolderName.value = saved.folderName;
    $q.notify({
      type: 'positive',
      message: `${label}: сохранён в «${saved.folderName}»`,
      timeout: 2000
    });
  } else {
    $q.notify({
      type: 'positive',
      message: `${label}: скачан через браузер`,
      timeout: 2000
    });
  }
}

/**
 * Выгрузка Rslt (предпросмотр или Excel).
 */
async function runRsltExport(yr: number, asOfUpl: number, isPovtor: boolean): Promise<void> {
  const label = isPovtor ? 'Rslt повтор · Выгрузить' : 'Rslt сбор · Выгрузить';
  if (progress.resultMode === 'proto') {
    const debts = await getSudzYrDbtChanges(yr, asOfUpl);
    const preview = buildSudzRsltPreview(debts, isPovtor);
    progress.protoRows = preview.rows;
    progress.protoColumns = preview.columns;
    progress.protoFillNew = isPovtor;
    progress.protoSliceCount = preview.sliceDates.length;
    progress.protoFilter = '';
    progress.protoColumnFilters = Object.fromEntries(preview.columns.map((c) => [c.name, '']));
    clearProtoCell();
    progress.subTab = 'proto';
    await nextTick();
    const scrollRoot = protoScrollFrameEl.value?.querySelector('.progress-proto-scroll');
    if (scrollRoot instanceof HTMLElement) {
      scrollRoot.scrollLeft = 0;
      scrollRoot.scrollTop = 0;
    }
    const line = `[${progressTimestamp()}] ${label} · предпросмотр | yr=${yr} | asOfUpl=${asOfUpl} | долгов=${preview.rows.length} | срезов=${preview.sliceDates.length} | ok`;
    await appendSudzYearProgress(yr, line);
    await store.selectYear(yr);
    $q.notify({
      type: 'positive',
      message: `Предпросмотр ${label}: ${preview.rows.length} долг(ов)`,
      timeout: 1500
    });
    return;
  }
  const { blob, fileName } = await downloadSudzRsltExcel(yr, asOfUpl, isPovtor ? 'povtor' : 'sborn');
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

/**
 * Текст ячейки предпросмотра (как в Excel-колонке).
 */
function formatProtoCell(
  row: SudzRsltPreviewRow,
  col: FemsqTableColumn<SudzRsltPreviewRow>
): string {
  const raw = row[col.name as keyof SudzRsltPreviewRow];
  if (col.format) {
    return col.format(raw, row);
  }
  return raw == null || raw === '' ? '' : String(raw);
}

/** Строки предпросмотра: глобальный фильтр AND поколоночные. */
const filteredProtoRows = computed(() => {
  const globalNeedle = progress.protoFilter.trim().toLowerCase();
  const colNeedles = progress.protoColumns
    .map((col) => ({
      col,
      needle: (progress.protoColumnFilters[col.name] ?? '').trim().toLowerCase()
    }))
    .filter((x) => x.needle.length > 0);

  if (!globalNeedle && colNeedles.length === 0) {
    return progress.protoRows;
  }

  return progress.protoRows.filter((row) => {
    if (globalNeedle) {
      const hitGlobal = progress.protoColumns.some((col) =>
        formatProtoCell(row, col).toLowerCase().includes(globalNeedle)
      );
      if (!hitGlobal) {
        return false;
      }
    }
    for (const { col, needle } of colNeedles) {
      if (!formatProtoCell(row, col).toLowerCase().includes(needle)) {
        return false;
      }
    }
    return true;
  });
});

/**
 * Выбор ячейки → полный текст в нижней панели.
 */
function onProtoCellSelect(
  row: SudzRsltPreviewRow,
  col: FemsqTableColumn<SudzRsltPreviewRow>
): void {
  protoCell.dbtKey = row.dbtKey;
  protoCell.colName = col.name;
  protoCell.colLabel = col.label;
  protoCell.text = formatProtoCell(row, col);
}

function clearProtoCell(): void {
  protoCell.dbtKey = null;
  protoCell.colName = '';
  protoCell.colLabel = '';
  protoCell.text = '';
}

/**
 * Из предпросмотра — сразу Excel с тем же срезом/операцией.
 */
async function onProtoToExcel(): Promise<void> {
  const yr = store.selectedYear?.yrKey;
  if (yr == null || progress.asOfUpl == null) {
    return;
  }
  if (!isRsltExport.value && !isD644OrSvodExport.value) {
    return;
  }
  progress.busy = true;
  progress.error = '';
  try {
    progress.resultMode = 'excel';
    if (isRsltExport.value) {
      await runRsltExport(yr, progress.asOfUpl, progress.operation === 'rslt_povtor_export');
    } else {
      await runD644OrSvodExport(yr, progress.asOfUpl);
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
    cmmGrKey: form.cmmGrKey,
    cmmGrNewKey: progress.cmmGrNewKey ?? store.selectedYear?.cmmGrNew ?? null
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
.sudz-yr-page {
  overflow: hidden;
}

.sudz-yr-view {
  min-width: 0;
  width: 100%;
  max-width: 100%;
  min-height: 0;
  overflow: hidden;
  box-sizing: border-box;
}

.sudz-yr-body {
  min-width: 0;
  min-height: 0;
  flex: 1 1 auto;
  overflow: hidden;
  width: 100%;
  max-width: 100%;
  gap: 12px;
}

.yr-header-card {
  flex: 0 0 auto;
  min-width: 0;
  max-width: 100%;
}

.yr-detail {
  min-width: 0;
  min-height: 0;
  flex: 1 1 auto;
  overflow: hidden;
}

.yr-detail-panels {
  flex: 1 1 auto;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
}

/* Quasar вешает .scroll на обёртку панели — горизонтальный скролл ломает лог после proto. */
.yr-detail-panels :deep(.q-panel) {
  box-sizing: border-box;
  width: 100% !important;
  max-width: 100%;
  min-width: 0;
  min-height: 0;
  height: 100%;
  overflow: hidden !important;
}

.yr-detail-panels :deep(.q-tab-panel) {
  box-sizing: border-box;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  min-height: 0;
  height: 100%;
  overflow: hidden;
  padding: 0;
}

.yr-master {
  width: 15%;
  min-width: 160px;
  max-width: 240px;
  flex-shrink: 0;
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

.progress-tab {
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  width: 100%;
  min-width: 0;
  min-height: 0;
  height: 100%;
  overflow: hidden;
  max-width: 100%;
}

.progress-subpanels {
  position: relative;
  flex: 1 1 auto;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
}

.progress-log-panel {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  width: auto;
  max-width: none;
  min-width: 0;
  height: auto;
  overflow: hidden;
}

.progress-log-pre {
  flex: 1 1 auto;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  min-height: 0;
  margin: 0;
  padding: 8px 12px;
  box-sizing: border-box;
  overflow: auto;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  word-break: break-word;
  border: 1px solid var(--femsq-border, rgba(255, 255, 255, 0.35));
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.12);
  font-family: inherit;
  font-size: 12px;
  line-height: 1.35;
}

.progress-proto-panel {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  width: auto;
  height: auto;
  max-width: none;
  overflow: hidden;
}

.progress-proto-body {
  display: flex;
  flex-direction: column;
  flex: 1 1 auto;
  min-width: 0;
  min-height: 0;
  width: 100%;
  overflow: hidden;
  gap: 6px;
}

.progress-proto-toolbar {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 8px;
  flex: 0 0 auto;
  width: 100%;
  min-width: 0;
}

.progress-proto-caption {
  flex: 1 1 auto;
  min-width: 0;
}

.progress-proto-filter {
  flex: 0 0 auto;
  width: 100%;
}

/*
 * Рамка занимает оставшееся место МЕЖДУ фильтром и панелью ячейки.
 * Скролл — абсолютный inset, таблица не раздувает layout.
 */
.progress-proto-frame {
  position: relative;
  flex: 1 1 auto;
  min-width: 0;
  min-height: 120px;
  width: 100%;
  overflow: hidden;
  border: 1px solid var(--femsq-border, rgba(255, 255, 255, 0.35));
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.12);
}

.progress-proto-scroll {
  position: absolute;
  inset: 0;
  overflow: auto;
  overscroll-behavior: contain;
}

/*
 * sticky + border-collapse:collapse ломает выравнивание th/td при scroll.
 * separate + одинаковый max-width у th и td — колонки совпадают.
 * Две sticky-строки thead: заголовок (top:0) + фильтры (top: высота шапки).
 */
.progress-proto-native {
  --proto-header-h: 3.75rem;
  --proto-filter-h: 2rem;
  border-collapse: separate;
  border-spacing: 0;
  width: max-content;
}

.progress-proto-native th,
.progress-proto-native td {
  box-sizing: border-box;
  font-size: 12px;
  vertical-align: middle;
  max-width: 220px;
  min-width: 88px;
  padding: 4px 8px;
  overflow: hidden;
  border-right: 1px solid rgba(128, 128, 128, 0.35);
  border-bottom: 1px solid rgba(128, 128, 128, 0.35);
}

.progress-proto-native th:first-child,
.progress-proto-native td:first-child {
  border-left: 1px solid rgba(128, 128, 128, 0.35);
}

.progress-proto-native thead .proto-header-row th {
  position: sticky;
  top: 0;
  z-index: 3;
  height: var(--proto-header-h);
  max-height: var(--proto-header-h);
  font-weight: 600;
  vertical-align: bottom;
  white-space: normal;
  border-top: 1px solid rgba(128, 128, 128, 0.35);
  background: #2a2a2a;
}

.progress-proto-native thead .proto-filter-row th {
  position: sticky;
  top: var(--proto-header-h);
  z-index: 2;
  height: var(--proto-filter-h);
  max-height: var(--proto-filter-h);
  padding: 2px 4px;
  font-weight: 400;
  vertical-align: middle;
  /* нейтральный фон (без band-цветов), иначе sticky «просвечивает» */
  background: #242424 !important;
  color: inherit !important;
}

.proto-header-label {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
  white-space: normal;
  word-break: break-word;
  line-height: 1.2;
  max-height: 3.6em;
}

.proto-col-filter {
  box-sizing: border-box;
  display: block;
  width: 100%;
  min-width: 0;
  height: 1.5rem;
  margin: 0;
  padding: 0 4px;
  border: 1px solid rgba(128, 128, 128, 0.45);
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.08);
  color: inherit;
  font-size: 11px;
  outline: none;
}

.proto-col-filter:focus {
  border-color: var(--q-primary);
}

.progress-proto-native td {
  white-space: nowrap;
  text-overflow: ellipsis;
  cursor: pointer;
}

.proto-cell-one-line {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100%;
}

.progress-proto-native .proto-td--selected {
  outline: 2px solid var(--q-primary);
  outline-offset: -2px;
}

.proto-cell-detail {
  flex: 0 0 auto;
  width: 100%;
  min-width: 0;
  border: 1px solid var(--femsq-border, rgba(255, 255, 255, 0.2));
  border-radius: 4px;
  padding: 6px 8px;
  background: rgba(0, 0, 0, 0.15);
}

.proto-cell-detail__body {
  height: 4.5em;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 13px;
  line-height: 1.35;
}

.progress-proto-native .proto-h--overd,
.progress-proto-native .proto-c--overd {
  background: #ffff99 !important;
  color: #222;
}

.progress-proto-native .proto-h--new {
  background: #f2dcdb !important;
  color: #222;
}

.progress-proto-native .proto-h--curator {
  background: #d7e4bd !important;
  color: #222;
}

.progress-proto-native .proto-h--inv {
  background: #e8b4b3 !important;
  color: #222;
}

.progress-proto-native .proto-h--base,
.progress-proto-native .proto-h--key {
  background: #fdeada !important;
  color: #222;
}

.progress-proto-native .proto-h--quarter {
  background: #f5f5f0 !important;
  color: #222;
}
</style>
