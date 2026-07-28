<template>
  <div class="cst-reports-tab fill-pane" data-test="cst-reports-tab">
    <QSplitter
      v-model="reportsSplit"
      horizontal
      :limits="[20, 85]"
      class="reports-splitter fill-pane"
      separator-class="cst-split-sep"
      data-test="cst-reports-splitter"
    >
      <template #before>
        <div class="reports-list-pane fill-pane column no-wrap">
          <div class="row items-center q-mb-xs">
            <div class="femsq-section-title col">Отчёты · изменения (fnRRcList)</div>
            <QBtn
              flat
              dense
              no-caps
              color="primary"
              icon="add"
              label="Отчёт"
              :disable="!store.selectedCstKey"
              @click="openReportDialog()"
            />
            <QBtn flat dense icon="refresh" :loading="store.loadingRaList" aria-label="Обновить" @click="reload()" />
          </div>

          <FemsqTable
            flat
            bordered
            dense
            class="ra-list-table col"
            root-class="ra-list-table col"
            row-key="rowKey"
            :rows="listRows"
            :columns="listColumns"
            :loading="store.loadingRaList"
            v-model:filter="listFilter"
            v-model:pagination="listPagination"
            filter-label="Фильтр по полям списка"
            filter-test-id="cst-ra-list-filter"
            @row-click="onListRowClick"
          />

          <div v-if="changeHint" class="text-caption femsq-text-muted q-mt-xs">{{ changeHint }}</div>
        </div>
      </template>

      <template #after>
        <div class="reports-detail-pane fill-pane">
          <template v-if="store.selectedReport">
            <div class="report-card" data-test="cst-ra-detail">
              <div class="row items-center q-mb-sm">
                <div class="femsq-section-title col">Отчёт {{ store.selectedReport.raNum }}</div>
                <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click="openReportDialog(store.selectedReport)" />
                <QBtn
                  flat
                  dense
                  icon="delete"
                  size="sm"
                  color="negative"
                  aria-label="Удалить"
                  @click="confirmDeleteReport()"
                />
              </div>

              <div class="row q-col-gutter-sm">
                <div class="col-12 col-md-4">
                  <div class="field-line"><span class="field-label">№</span> {{ store.selectedReport.raNum }}</div>
                  <div class="field-line"><span class="field-label">период</span> {{ periodLabel(store.selectedReport.raPeriod) }}</div>
                  <div class="field-line"><span class="field-label">создан</span> {{ formatDateTime(store.selectedReport.raCreated) }}</div>
                  <div class="field-line">
                    <span class="field-label">поступил</span>
                    {{ store.selectedReport.raArrived || '—' }} {{ formatDate(store.selectedReport.raArrivedDate) }}
                  </div>
                  <div class="field-line">
                    <span class="field-label">возвращён</span>
                    {{ store.selectedReport.raReturned || '—' }} {{ formatDate(store.selectedReport.raReturnedDate) }}
                  </div>
                  <div class="field-line">
                    <span class="field-label">направлен</span>
                    {{ store.selectedReport.raSent || '—' }} {{ formatDate(store.selectedReport.raSentDate) }}
                  </div>
                </div>
                <div class="col-12 col-md-4">
                  <div class="field-line"><span class="field-label">дата</span> {{ formatDate(store.selectedReport.raDate) }}</div>
                  <div class="field-line"><span class="field-label">тип</span> {{ store.selectedReport.raType }}</div>
                  <div class="field-line"><span class="field-label">работа</span> {{ store.selectedReport.raWorkType || '—' }}</div>
                  <div class="field-line"><span class="field-label">стройка</span> {{ cacLabel(store.selectedReport.raCac) }}</div>
                  <div class="field-line"><span class="field-label">ra_key</span> {{ store.selectedReport.raKey }}</div>
                  <div class="field-line"><span class="field-label">отправитель</span> {{ orgLabel(store.selectedReport.raOrgSender) }}</div>
                </div>
              </div>

              <QTabs v-model="detailTab" dense align="left" class="q-mt-md q-mb-sm">
                <QTab name="sums" label="суммы" />
                <QTab name="changes" label="изменения" />
                <QTab name="notes" label="примечания" />
              </QTabs>

              <QTabPanels v-model="detailTab">
                <QTabPanel name="sums" class="q-pa-none">
                  <div class="row items-center q-mb-xs">
                    <div class="col text-caption">Версии сумм (ags.ra_summ)</div>
                    <QBtn flat dense no-caps color="primary" icon="add" label="Суммы" @click="openSummDialog()" />
                  </div>
                  <FemsqTable
                    flat
                    bordered
                    dense
                    row-key="rasKey"
                    :rows="store.raSums"
                    :columns="summColumns"
                    :loading="store.loadingRaSums"
                    :show-filter="false"
                    hide-pagination
                    :pagination="{ rowsPerPage: 0 }"
                  >
                    <template #body-cell-actions="slotProps">
                      <QTd :props="slotProps" auto-width>
                        <QBtn flat dense icon="edit" size="sm" @click="openSummDialog(slotProps.row)" />
                        <QBtn
                          flat
                          dense
                          icon="delete"
                          size="sm"
                          color="negative"
                          @click="confirmDeleteSumm(slotProps.row)"
                        />
                      </QTd>
                    </template>
                  </FemsqTable>
                </QTabPanel>
                <QTabPanel name="changes" class="q-pa-none">
                  <div class="text-caption femsq-text-muted">
                    CRUD изменений (ags.ra_change) — в следующей итерации. Строки видны в списке выше.
                  </div>
                </QTabPanel>
                <QTabPanel name="notes" class="q-pa-none">
                  <div class="field-line"><span class="field-label">примечание</span></div>
                  <div class="note-box">{{ store.selectedReport.raNote || '—' }}</div>
                  <div class="field-line q-mt-sm"><span class="field-label">примечание (техн.)</span></div>
                  <div class="note-box">{{ store.selectedReport.raNoteT || '—' }}</div>
                </QTabPanel>
              </QTabPanels>
            </div>
          </template>
          <div v-else-if="!store.loadingReport" class="text-caption femsq-text-muted q-pa-sm">
            Выберите базовый отчёт в списке (строки изменений только для просмотра).
          </div>
        </div>
      </template>
    </QSplitter>

    <QDialog v-model="reportDialog" persistent>
      <QCard style="min-width: 520px; max-width: 720px">
        <QCardSection class="text-h6">{{ reportEditId == null ? 'Новый отчёт' : 'Отчёт' }}</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="reportForm.raNum" dense outlined label="№ *" />
          <div class="row q-col-gutter-sm">
            <div class="col-6">
              <QInput v-model="reportForm.raDate" dense outlined type="date" label="дата" />
            </div>
            <div class="col-6">
              <QInput v-model="reportForm.raType" dense outlined label="тип *" />
            </div>
          </div>
          <QSelect
            v-model="reportForm.raCac"
            dense
            outlined
            emit-value
            map-options
            :options="cacOptions"
            label="стройка (САК) *"
          />
          <QSelect
            v-model="reportForm.raPeriod"
            dense
            outlined
            emit-value
            map-options
            :options="periodOptions"
            label="период *"
            use-input
            input-debounce="200"
            @filter="filterPeriods"
          />
          <QInput v-model="reportForm.raWorkType" dense outlined label="работа" />
          <QSelect
            v-model="reportForm.raOrgSender"
            dense
            outlined
            emit-value
            map-options
            :options="orgOptions"
            label="отправитель *"
            use-input
            input-debounce="200"
            @filter="filterOrgs"
          />
          <div class="row q-col-gutter-sm">
            <div class="col-7"><QInput v-model="reportForm.raArrived" dense outlined label="поступил" /></div>
            <div class="col-5"><QInput v-model="reportForm.raArrivedDate" dense outlined type="date" label="дата" /></div>
          </div>
          <div class="row q-col-gutter-sm">
            <div class="col-7"><QInput v-model="reportForm.raReturned" dense outlined label="возвращён" /></div>
            <div class="col-5"><QInput v-model="reportForm.raReturnedDate" dense outlined type="date" label="дата" /></div>
          </div>
          <div class="row q-col-gutter-sm">
            <div class="col-7"><QInput v-model="reportForm.raSent" dense outlined label="направлен" /></div>
            <div class="col-5"><QInput v-model="reportForm.raSentDate" dense outlined type="date" label="дата" /></div>
          </div>
          <QInput v-model="reportForm.raNote" dense outlined type="textarea" autogrow label="примечание" />
          <QInput v-model="reportForm.raNoteT" dense outlined type="textarea" autogrow label="примечание (техн.)" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat label="Отмена" v-close-popup />
          <QBtn color="primary" label="Сохранить" :loading="store.saving" @click="saveReport()" />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="summDialog" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-h6">{{ summEditId == null ? 'Новые суммы' : 'Суммы' }}</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model.number="summForm.rasTotal" dense outlined type="number" label="всего" />
          <QInput v-model.number="summForm.rasWork" dense outlined type="number" label="СМР" />
          <QInput v-model.number="summForm.rasEquip" dense outlined type="number" label="оборудование" />
          <QInput v-model.number="summForm.rasOthers" dense outlined type="number" label="прочее" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat label="Отмена" v-close-popup />
          <QBtn color="primary" label="Сохранить" :loading="store.saving" @click="saveSumm()" />
        </QCardActions>
      </QCard>
    </QDialog>
  </div>
</template>

<script setup lang="ts">
/**
 * Вкладка «отчёты» формы cst: список fnRRcList (Access cst>ra_t) + карточка ra (cst>ra_f) + суммы.
 * Синхронизация как VBA Form_cst_gt_ra_t.Form_Current: выбор строки списка → деталь по ra_key.
 */
import { computed, reactive, ref, watch } from 'vue';
import {
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QSelect,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QTd,
  useQuasar
} from 'quasar';

import { FemsqTable, actionsColumn, type FemsqTableColumn } from 'fequlib';
import { useConstructionSitesStore } from '@/stores/construction-sites';
import type { CstRaListEntryDto, RaReportDto, RaSummDto } from '@/types/construction-sites';

const store = useConstructionSitesStore();
const $q = useQuasar();

const detailTab = ref('sums');
const changeHint = ref('');
const listFilter = ref('');
const reportDialog = ref(false);
const reportEditId = ref<number | null>(null);
const summDialog = ref(false);
const summEditId = ref<number | null>(null);

const REPORTS_SPLIT_KEY = 'femsq.cst.reportsSplit';
const reportsSplit = ref(readSplit(REPORTS_SPLIT_KEY, 48));
watch(reportsSplit, (value) => {
  localStorage.setItem(REPORTS_SPLIT_KEY, String(value));
});

function readSplit(key: string, fallback: number): number {
  const raw = localStorage.getItem(key);
  if (raw == null) {
    return fallback;
  }
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

const listPagination = ref({ page: 1, rowsPerPage: 25 });

type ListRow = CstRaListEntryDto & { rowKey: string };

const listRows = computed<ListRow[]>(() =>
  store.raList.map((row) => ({
    ...row,
    rowKey: `${row.raKey}-${row.raChKey ?? 'base'}`
  }))
);

const listColumns: FemsqTableColumn<ListRow>[] = [
  { name: 'yyyy', label: 'год', field: 'yyyy', sortable: true, style: 'width: 4rem' },
  { name: 'mNum', label: 'месяц', field: 'mNum', sortable: true, style: 'width: 4rem' },
  { name: 'p', label: 'период', field: 'p', style: 'min-width: 10rem' },
  { name: 'ogaNm', label: 'агент', field: 'ogaNm', style: 'min-width: 10rem' },
  { name: 'cstapIpgPnN', label: 'стройки', field: 'cstapIpgPnN', style: 'min-width: 8rem' },
  { name: 'raNum', label: 'отчёт', field: 'raNum', style: 'min-width: 9rem' },
  { name: 'raDate', label: 'отчёт, дата', field: 'raDate', style: 'width: 6.5rem' },
  { name: 'raType', label: 'тип', field: 'raType', style: 'width: 3.5rem' },
  { name: 'raChNum', label: 'изм.', field: 'raChNum', style: 'width: 4rem' },
  { name: 'raChDate', label: 'изм., дата', field: 'raChDate', style: 'width: 6.5rem' },
  { name: 'ogNm', label: 'отправитель', field: 'ogNm', style: 'min-width: 10rem' },
  {
    name: 'rasTotal',
    label: 'всего',
    field: 'rasTotal',
    format: (val: unknown) => formatMoney(val),
    align: 'right',
    style: 'width: 6rem'
  },
  {
    name: 'rasWork',
    label: 'СМР',
    field: 'rasWork',
    format: (val: unknown) => formatMoney(val),
    align: 'right',
    style: 'width: 6rem'
  },
  {
    name: 'rasEquip',
    label: 'оборудование',
    field: 'rasEquip',
    format: (val: unknown) => formatMoney(val),
    align: 'right',
    style: 'width: 6rem'
  },
  {
    name: 'rasOthers',
    label: 'прочее',
    field: 'rasOthers',
    format: (val: unknown) => formatMoney(val),
    align: 'right',
    style: 'width: 6rem'
  },
  { name: 'raArrived', label: 'получено', field: 'raArrived', style: 'min-width: 8rem' },
  { name: 'raArrivedDate', label: 'получено, дата', field: 'raArrivedDate', style: 'width: 6.5rem' },
  { name: 'raReturned', label: 'возврат', field: 'raReturned', style: 'min-width: 6rem' },
  { name: 'raSent', label: 'в бухгалтерию', field: 'raSent', style: 'min-width: 8rem' },
  { name: 'raSentDate', label: 'в бух., дата', field: 'raSentDate', style: 'width: 6.5rem' }
];

const summColumns: FemsqTableColumn<RaSummDto>[] = [
  { name: 'rasKey', label: 'ras_key', field: 'rasKey', style: 'width: 5rem' },
  {
    name: 'rasTotal',
    label: 'всего',
    field: 'rasTotal',
    format: (val: unknown) => formatMoney(val),
    align: 'right'
  },
  {
    name: 'rasWork',
    label: 'СМР',
    field: 'rasWork',
    format: (val: unknown) => formatMoney(val),
    align: 'right'
  },
  {
    name: 'rasEquip',
    label: 'оборудование',
    field: 'rasEquip',
    format: (val: unknown) => formatMoney(val),
    align: 'right'
  },
  {
    name: 'rasOthers',
    label: 'прочее',
    field: 'rasOthers',
    format: (val: unknown) => formatMoney(val),
    align: 'right'
  },
  {
    name: 'rasDate',
    label: 'дата',
    field: 'rasDate',
    format: (val: unknown) => formatDateTime(val as string | null | undefined),
    style: 'min-width: 9rem'
  },
  actionsColumn()
];

const reportForm = reactive({
  raNum: '',
  raDate: '',
  raCac: null as number | null,
  raType: '',
  raWorkType: '',
  raPeriod: null as number | null,
  raArrived: '',
  raArrivedDate: '',
  raReturned: '',
  raReturnedDate: '',
  raSent: '',
  raSentDate: '',
  raNoteT: '',
  raOrgSender: null as number | null,
  raNote: ''
});

const summForm = reactive({
  rasTotal: null as number | null,
  rasWork: null as number | null,
  rasEquip: null as number | null,
  rasOthers: null as number | null
});

const periodFilter = ref('');
const orgFilter = ref('');

const cacOptions = computed(() =>
  store.sitePnLookups.map((item) => ({
    label: item.agentLabel || item.cstapIpgPnN,
    value: item.cstapKey
  }))
);

const periodOptions = computed(() => {
  const q = periodFilter.value.trim().toLowerCase();
  return store.raPeriodLookups
    .filter((item) => !q || item.p.toLowerCase().includes(q) || String(item.key).includes(q))
    .slice(0, 80)
    .map((item) => ({ label: item.p, value: item.key }));
});

const orgOptions = computed(() => {
  const q = orgFilter.value.trim().toLowerCase();
  return store.organizationLookups
    .filter((item) => !q || item.ogNm.toLowerCase().includes(q))
    .slice(0, 80)
    .map((item) => ({ label: item.ogNm, value: item.ogKey }));
});

watch(
  () => store.selectedCstKey,
  (key) => {
    if (key != null) {
      void store.loadRaList(key);
    }
  },
  { immediate: true }
);

function reload(): void {
  void store.loadRaList();
}

function onListRowClick(_evt: Event, row: ListRow): void {
  if (row.raChKey != null) {
    changeHint.value = `Строка изменения ${row.raChNum || row.raChKey}: CRUD изменений — позже. Выберите базовый отчёт.`;
    return;
  }
  changeHint.value = '';
  void store.selectRa(row.raKey);
}

function formatMoney(value: unknown): string {
  if (value == null || value === '') {
    return '';
  }
  const num = Number(value);
  if (Number.isNaN(num)) {
    return String(value);
  }
  return new Intl.NumberFormat('ru-RU', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(num);
}

function formatDate(value?: string | null): string {
  if (!value) {
    return '';
  }
  return value.length >= 10 ? value.slice(0, 10) : value;
}

function formatDateTime(value?: string | null): string {
  if (!value) {
    return '—';
  }
  return value.replace('T', ' ').slice(0, 19);
}

function periodLabel(key: number): string {
  return store.raPeriodLookups.find((item) => item.key === key)?.p || String(key);
}

function cacLabel(key: number): string {
  const found = store.sitePnLookups.find((item) => item.cstapKey === key);
  return found ? found.agentLabel || found.cstapIpgPnN : String(key);
}

function orgLabel(key: number): string {
  return store.organizationLookups.find((item) => item.ogKey === key)?.ogNm || String(key);
}

function emptyReportForm(): void {
  reportForm.raNum = '';
  reportForm.raDate = '';
  reportForm.raCac = store.sitePnLookups[0]?.cstapKey ?? null;
  reportForm.raType = '';
  reportForm.raWorkType = '';
  reportForm.raPeriod = store.raPeriodLookups[0]?.key ?? null;
  reportForm.raArrived = '';
  reportForm.raArrivedDate = '';
  reportForm.raReturned = '';
  reportForm.raReturnedDate = '';
  reportForm.raSent = '';
  reportForm.raSentDate = '';
  reportForm.raNoteT = '';
  reportForm.raOrgSender = null;
  reportForm.raNote = '';
}

function openReportDialog(report?: RaReportDto | null): void {
  if (report) {
    reportEditId.value = report.raKey;
    reportForm.raNum = report.raNum;
    reportForm.raDate = formatDate(report.raDate);
    reportForm.raCac = report.raCac;
    reportForm.raType = report.raType;
    reportForm.raWorkType = report.raWorkType || '';
    reportForm.raPeriod = report.raPeriod;
    reportForm.raArrived = report.raArrived || '';
    reportForm.raArrivedDate = formatDate(report.raArrivedDate);
    reportForm.raReturned = report.raReturned || '';
    reportForm.raReturnedDate = formatDate(report.raReturnedDate);
    reportForm.raSent = report.raSent || '';
    reportForm.raSentDate = formatDate(report.raSentDate);
    reportForm.raNoteT = report.raNoteT || '';
    reportForm.raOrgSender = report.raOrgSender;
    reportForm.raNote = report.raNote || '';
  } else {
    reportEditId.value = null;
    emptyReportForm();
  }
  reportDialog.value = true;
}

async function saveReport(): Promise<void> {
  if (
    !reportForm.raNum.trim() ||
    reportForm.raCac == null ||
    !reportForm.raType.trim() ||
    reportForm.raPeriod == null ||
    reportForm.raOrgSender == null
  ) {
    $q.notify({
      type: 'negative',
      message: 'Заполните обязательные поля: №, САК, тип, период, отправитель'
    });
    return;
  }
  await store.saveReport(
    {
      raNum: reportForm.raNum.trim(),
      raDate: reportForm.raDate || null,
      raCac: reportForm.raCac,
      raType: reportForm.raType.trim(),
      raWorkType: reportForm.raWorkType.trim() || null,
      raPeriod: reportForm.raPeriod,
      raArrived: reportForm.raArrived.trim() || null,
      raArrivedDate: reportForm.raArrivedDate || null,
      raReturned: reportForm.raReturned.trim() || null,
      raReturnedDate: reportForm.raReturnedDate || null,
      raSent: reportForm.raSent.trim() || null,
      raSentDate: reportForm.raSentDate || null,
      raNoteT: reportForm.raNoteT.trim() || null,
      raOrgSender: reportForm.raOrgSender,
      raNote: reportForm.raNote.trim() || null
    },
    reportEditId.value ?? undefined
  );
  reportDialog.value = false;
}

function confirmDeleteReport(): void {
  const report = store.selectedReport;
  if (!report) {
    return;
  }
  $q.dialog({
    title: 'Удалить отчёт?',
    message: `${report.raNum} (ra_key=${report.raKey})`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeReport(report.raKey);
  });
}

function openSummDialog(row?: RaSummDto): void {
  if (row) {
    summEditId.value = row.rasKey;
    summForm.rasTotal = row.rasTotal ?? null;
    summForm.rasWork = row.rasWork ?? null;
    summForm.rasEquip = row.rasEquip ?? null;
    summForm.rasOthers = row.rasOthers ?? null;
  } else {
    summEditId.value = null;
    summForm.rasTotal = null;
    summForm.rasWork = null;
    summForm.rasEquip = null;
    summForm.rasOthers = null;
  }
  summDialog.value = true;
}

async function saveSumm(): Promise<void> {
  if (store.selectedRaKey == null) {
    return;
  }
  await store.saveSumm(
    {
      rasRa: store.selectedRaKey,
      rasTotal: summForm.rasTotal,
      rasWork: summForm.rasWork,
      rasEquip: summForm.rasEquip,
      rasOthers: summForm.rasOthers,
      rasDate: null
    },
    summEditId.value ?? undefined
  );
  summDialog.value = false;
}

function confirmDeleteSumm(row: RaSummDto): void {
  $q.dialog({
    title: 'Удалить суммы?',
    message: `ras_key=${row.rasKey}`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeSumm(row.rasKey);
  });
}

function filterPeriods(val: string, update: (fn: () => void) => void): void {
  update(() => {
    periodFilter.value = val;
  });
}

function filterOrgs(val: string, update: (fn: () => void) => void): void {
  update(() => {
    orgFilter.value = val;
  });
}
</script>

<style scoped>
.cst-reports-tab {
  height: 100%;
  min-height: 0;
  overflow: hidden;
  width: 100%;
}

.fill-pane {
  width: 100%;
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.reports-splitter {
  width: 100%;
  height: 100%;
}

.reports-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  width: 100%;
}

.reports-list-pane {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  box-sizing: border-box;
  padding: 2px 4px;
  overflow: hidden;
  min-height: 0;
  width: 100%;
}

.reports-detail-pane {
  box-sizing: border-box;
  padding: 2px 4px;
  overflow: auto;
  min-height: 0;
  width: 100%;
}

.ra-list-table {
  flex: 1 1 auto;
  min-height: 0;
  height: 0;
}

.reports-splitter :deep(.q-splitter__separator) {
  height: 5px;
  background: transparent;
}

.reports-splitter :deep(.q-splitter__separator-area) {
  height: 5px;
  background: color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
  border-radius: 2px;
  opacity: 0.85;
}

.reports-splitter :deep(.q-splitter__separator-area:hover) {
  opacity: 1;
  background: var(--q-primary);
}

.field-line {
  font-size: 12px;
  line-height: 1.45;
  margin-bottom: 0.15rem;
}
.field-label {
  display: inline-block;
  min-width: 6.5rem;
  color: var(--femsq-text-muted, #888);
  margin-right: 0.35rem;
}
.note-box {
  font-size: 12px;
  white-space: pre-wrap;
  border: 1px solid color-mix(in srgb, currentColor 18%, transparent);
  padding: 0.4rem 0.5rem;
  border-radius: var(--femsq-control-radius, 2px);
  min-height: 2.5rem;
}
.report-card {
  padding-top: 0.25rem;
}
</style>
