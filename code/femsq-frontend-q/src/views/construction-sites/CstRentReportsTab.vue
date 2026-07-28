<template>
  <div class="cst-rent-tab fill-pane" data-test="cst-rent-tab">
    <QSplitter
      v-model="rentSplit"
      horizontal
      :limits="[20, 85]"
      class="rent-splitter fill-pane"
      separator-class="cst-split-sep"
      data-test="cst-rent-splitter"
    >
      <template #before>
        <div class="rent-list-pane fill-pane column no-wrap">
          <div class="row items-center q-mb-xs">
            <div class="femsq-section-title col">Отчёты аренды (ralpRaCst)</div>
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
            <QBtn
              flat
              dense
              icon="refresh"
              :loading="store.loadingRalpRaList"
              aria-label="Обновить"
              @click="reload()"
            />
          </div>

          <div class="row q-col-gutter-sm items-center q-mb-xs">
            <div class="col-auto">
              <QToggle v-model="filterMultiAu" dense label="несколько Au" data-test="cst-rent-filter-multi-au" />
            </div>
            <div class="col-auto">
              <QToggle v-model="filterReturned" dense label="с возвратом" data-test="cst-rent-filter-returned" />
            </div>
          </div>

          <FemsqTable
            flat
            bordered
            dense
            class="ralp-list-table col"
            root-class="ralp-list-table col"
            row-key="ralprKey"
            :rows="presetFilteredList"
            :columns="listColumns"
            :loading="store.loadingRalpRaList"
            v-model:filter="listFilter"
            v-model:pagination="listPagination"
            filter-label="Фильтр: № / САК / отправитель"
            filter-test-id="cst-rent-list-filter"
            @row-click="onListRowClick"
          />
        </div>
      </template>

      <template #after>
        <div class="rent-detail-pane fill-pane">
          <template v-if="store.selectedRalpRa">
            <div class="report-card" data-test="cst-ralp-detail">
              <div class="row items-center q-mb-sm">
                <div class="femsq-section-title col">Отчёт {{ store.selectedRalpRa.ralprNum }}</div>
                <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click="openReportDialog(store.selectedRalpRa)" />
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

              <div class="row q-col-gutter-sm q-mb-md">
                <div class="col-12 col-md-6">
                  <div class="field-line"><span class="field-label">№</span> {{ store.selectedRalpRa.ralprNum }}</div>
                  <div class="field-line"><span class="field-label">дата</span> {{ formatDate(store.selectedRalpRa.ralprDate) }}</div>
                  <div class="field-line"><span class="field-label">САК</span> {{ cacLabel(store.selectedRalpRa.ralprCstAgPn) }}</div>
                  <div class="field-line">
                    <span class="field-label">год/мес</span>
                    {{ store.selectedRalpRa.ralprY ?? '—' }}/{{ store.selectedRalpRa.ralprM ?? '—' }}
                  </div>
                </div>
                <div class="col-12 col-md-6">
                  <div class="field-line"><span class="field-label">отправитель</span> {{ senderLabel(store.selectedRalpRa) }}</div>
                  <div class="field-line"><span class="field-label">ralprKey</span> {{ store.selectedRalpRa.ralprKey }}</div>
                </div>
              </div>

              <div class="row items-center q-mb-xs">
                <div class="femsq-section-title col">Рассмотрение (Au_t)</div>
                <QBtn flat dense no-caps color="primary" icon="add" label="Au" @click="openAuDialog()" />
              </div>

              <FemsqTable
                flat
                bordered
                dense
                row-key="ralpraKey"
                :rows="store.ralpRaAus"
                :columns="auColumns"
                :loading="store.loadingRalpRaAus"
                filter-label="Фильтр Au"
                filter-test-id="cst-rent-au-filter"
                hide-pagination
                :pagination="{ rowsPerPage: 0 }"
              >
                <template #body-cell-actions="slotProps">
                  <QTd :props="slotProps" auto-width>
                    <QBtn flat dense icon="edit" size="sm" @click="openAuDialog(slotProps.row)" />
                    <QBtn
                      flat
                      dense
                      icon="delete"
                      size="sm"
                      color="negative"
                      @click="confirmDeleteAu(slotProps.row)"
                    />
                  </QTd>
                </template>
              </FemsqTable>
            </div>
          </template>
          <div v-else-if="!store.loadingRalpRa" class="text-caption femsq-text-muted q-pa-sm">
            Выберите отчёт аренды в списке.
          </div>
        </div>
      </template>
    </QSplitter>

    <QDialog v-model="reportDialog" persistent>
      <QCard style="min-width: 420px; max-width: 560px">
        <QCardSection class="text-h6">{{ reportEditId == null ? 'Новый отчёт аренды' : 'Отчёт аренды' }}</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="reportForm.ralprNum" dense outlined label="№ *" />
          <QInput v-model="reportForm.ralprDate" dense outlined type="date" label="дата *" />
          <QSelect
            v-model="reportForm.ralprCstAgPn"
            dense
            outlined
            emit-value
            map-options
            :options="pnOptions"
            label="САК *"
            use-input
            input-debounce="0"
            @filter="filterPn"
          />
          <QSelect
            v-model="reportForm.ralprOgSender"
            dense
            outlined
            emit-value
            map-options
            :options="orgOptions"
            label="отправитель *"
            use-input
            input-debounce="0"
            @filter="filterOrgs"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn color="primary" no-caps label="Сохранить" :loading="store.saving" @click="submitReport()" />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="auDialog" persistent>
      <QCard style="min-width: 480px; max-width: 640px">
        <QCardSection class="text-h6">{{ auEditId == null ? 'Новая строка Au' : 'Строка Au' }}</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model.number="auForm.ralpraCostAndVat" dense outlined type="number" label="сумма с НДС" />
          <QSelect
            v-model="auForm.ralpraStatus"
            dense
            outlined
            emit-value
            map-options
            :options="statusOptions"
            label="статус *"
          />
          <div class="row q-col-gutter-sm">
            <div class="col-8"><QInput v-model="auForm.ralpraArrived" dense outlined label="поступил" /></div>
            <div class="col-4"><QInput v-model="auForm.ralpraArrivedDate" dense outlined type="date" label="дата" /></div>
          </div>
          <div class="row q-col-gutter-sm">
            <div class="col-8"><QInput v-model="auForm.ralpraReturned" dense outlined label="возвращён" /></div>
            <div class="col-4"><QInput v-model="auForm.ralpraReturnedDate" dense outlined type="date" label="дата" /></div>
          </div>
          <div class="row q-col-gutter-sm">
            <div class="col-8"><QInput v-model="auForm.ralpraSent" dense outlined label="направлен" /></div>
            <div class="col-4"><QInput v-model="auForm.ralpraSentDate" dense outlined type="date" label="дата" /></div>
          </div>
          <QInput v-model="auForm.ralpraNote" dense outlined type="textarea" autogrow label="примечание" />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn color="primary" no-caps label="Сохранить" :loading="store.saving" @click="submitAu()" />
        </QCardActions>
      </QCard>
    </QDialog>
  </div>
</template>

<script setup lang="ts">
/**
 * Вкладка «отчёты, аренда»: список ralpRaCst + карточка ralpRa + CRUD ralpRaAu (Access Au_t).
 */
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QSelect,
  QSplitter,
  QTd,
  QToggle,
  useQuasar
} from 'quasar';

import { FemsqTable, actionsColumn, type FemsqTableColumn } from 'fequlib';
import { useConstructionSitesStore } from '@/stores/construction-sites';
import type { RalpRaAuDto, RalpRaCstListEntryDto, RalpRaDto } from '@/types/construction-sites';

const store = useConstructionSitesStore();
const $q = useQuasar();

const reportDialog = ref(false);
const reportEditId = ref<number | null>(null);
const auDialog = ref(false);
const auEditId = ref<number | null>(null);
const pnFilter = ref('');
const orgFilter = ref('');
const listFilter = ref('');
const filterMultiAu = ref(false);
const filterReturned = ref(false);

const RENT_SPLIT_KEY = 'femsq.cst.rentSplit';
const rentSplit = ref(readSplit(RENT_SPLIT_KEY, 48));
watch(rentSplit, (value) => {
  localStorage.setItem(RENT_SPLIT_KEY, String(value));
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

const listColumns: FemsqTableColumn<RalpRaCstListEntryDto>[] = [
  { name: 'ralprNum', label: '№', field: 'ralprNum', align: 'left', sortable: true },
  {
    name: 'ralprDate',
    label: 'дата',
    field: 'ralprDate',
    align: 'left',
    sortable: true,
    format: (v: unknown) => formatDate(v as string)
  },
  { name: 'cstapIpgPnN', label: 'САК', field: 'cstapIpgPnN', align: 'left' },
  { name: 'ogaNm', label: 'агент', field: 'ogaNm', align: 'left' },
  {
    name: 'ogNm',
    label: 'отправитель',
    field: 'ogNm',
    align: 'left',
    format: (_v: unknown, row) => senderLabel(row)
  },
  { name: 'auCnt', label: 'Au', field: 'auCnt', align: 'right', sortable: true },
  {
    name: 'hasReturned',
    label: 'возвр.',
    field: 'hasReturned',
    align: 'center',
    format: (v: unknown) => (v ? 'да' : '')
  }
];

const auColumns: FemsqTableColumn<RalpRaAuDto>[] = [
  { name: 'ralpraKey', label: 'key', field: 'ralpraKey', align: 'right' },
  {
    name: 'ralpraCostAndVat',
    label: 'сумма',
    field: 'ralpraCostAndVat',
    align: 'right',
    format: (v: unknown) => (v == null ? '—' : Number(v).toLocaleString('ru-RU', { maximumFractionDigits: 2 }))
  },
  {
    name: 'ralpraStatus',
    label: 'статус',
    field: 'ralpraStatus',
    align: 'left',
    format: (v: unknown) => statusLabel(Number(v))
  },
  { name: 'ralpraArrived', label: 'поступил', field: 'ralpraArrived', align: 'left' },
  { name: 'ralpraReturned', label: 'возвращён', field: 'ralpraReturned', align: 'left' },
  { name: 'ralpraSent', label: 'направлен', field: 'ralpraSent', align: 'left' },
  actionsColumn()
];

const reportForm = reactive({
  ralprNum: '',
  ralprDate: '',
  ralprCstAgPn: null as number | null,
  ralprOgSender: null as number | null
});

const auForm = reactive({
  ralpraCostAndVat: null as number | null,
  ralpraArrived: '',
  ralpraArrivedDate: '',
  ralpraReturned: '',
  ralpraReturnedDate: '',
  ralpraSent: '',
  ralpraSentDate: '',
  ralpraNote: '',
  ralpraStatus: 0
});

/** Пресеты над полями auCnt / hasReturned — не единственный способ фильтрации (текст — в FemsqTable). */
const presetFilteredList = computed(() =>
  store.ralpRaList.filter((row: RalpRaCstListEntryDto) => {
    if (filterMultiAu.value && (row.auCnt ?? 0) < 2) {
      return false;
    }
    if (filterReturned.value && !row.hasReturned) {
      return false;
    }
    return true;
  })
);

const pnOptions = computed(() =>
  store.sitePnLookups
    .filter((row) => {
      if (!pnFilter.value) {
        return true;
      }
      const q = pnFilter.value.toLowerCase();
      return (
        row.cstapIpgPnN.toLowerCase().includes(q) ||
        (row.agentLabel ?? '').toLowerCase().includes(q)
      );
    })
    .map((row) => ({
      label: `${row.cstapIpgPnN}${row.agentLabel ? ` · ${row.agentLabel}` : ''}`,
      value: row.cstapKey
    }))
);

const orgOptions = computed(() => {
  const options = store.organizationLookups
    .filter((row) => {
      if (!orgFilter.value) {
        return true;
      }
      return row.ogNm.toLowerCase().includes(orgFilter.value.toLowerCase());
    })
    .map((row) => ({ label: row.ogNm, value: row.ogKey }));

  // Если ключ не в справочнике организаций (часто это onfKey из ogNmF) — подпись из карточки/списка
  const current = reportForm.ralprOgSender;
  if (current != null && !options.some((opt) => opt.value === current)) {
    const fromCard =
      store.selectedRalpRa?.ralprOgSender === current ? store.selectedRalpRa.ogNm : null;
    const fromList = store.ralpRaList.find((row) => row.ralprOgSender === current)?.ogNm;
    options.unshift({
      label: fromCard || fromList || `ключ=${current}`,
      value: current
    });
  }
  return options;
});

const statusOptions = computed(() =>
  store.ralpRaAuStatusLookups.map((row) => ({ label: row.label, value: row.code }))
);

watch(
  () => store.selectedCstKey,
  (key) => {
    listFilter.value = '';
    filterMultiAu.value = false;
    filterReturned.value = false;
    listPagination.value = { ...listPagination.value, page: 1 };
    if (key != null) {
      void store.loadRalpRaList(key);
    }
  }
);

onMounted(() => {
  void store.loadRalpRaList();
});

function reload(): void {
  void store.loadRalpRaList();
}

function onListRowClick(_evt: Event, row: RalpRaCstListEntryDto): void {
  void store.selectRalpRa(row.ralprKey);
}

function formatDate(value?: string | null): string {
  if (!value) {
    return '—';
  }
  return value.length >= 10 ? value.slice(0, 10) : value;
}

function cacLabel(cstapKey: number): string {
  const row = store.sitePnLookups.find((item) => item.cstapKey === cstapKey);
  if (!row) {
    return String(cstapKey);
  }
  return `${row.cstapIpgPnN}${row.agentLabel ? ` · ${row.agentLabel}` : ''}`;
}

/**
 * Подпись отправителя: наименование из JOIN (og / ogNmF), иначе lookup организаций.
 */
function senderLabel(row: { ogNm?: string | null; ralprOgSender?: number | null } | null | undefined): string {
  if (row == null) {
    return '—';
  }
  if (row.ogNm) {
    return row.ogNm;
  }
  if (row.ralprOgSender == null) {
    return '—';
  }
  const fromOrg = store.organizationLookups.find((item) => item.ogKey === row.ralprOgSender)?.ogNm;
  return fromOrg ?? `ключ=${row.ralprOgSender}`;
}

function statusLabel(code: number): string {
  return store.ralpRaAuStatusLookups.find((item) => item.code === code)?.label ?? String(code);
}

function openReportDialog(row?: RalpRaDto | null): void {
  reportEditId.value = row?.ralprKey ?? null;
  reportForm.ralprNum = row?.ralprNum ?? '';
  reportForm.ralprDate = row?.ralprDate?.slice(0, 10) ?? '';
  reportForm.ralprCstAgPn = row?.ralprCstAgPn ?? null;
  reportForm.ralprOgSender = row?.ralprOgSender ?? null;
  reportDialog.value = true;
}

function openAuDialog(row?: RalpRaAuDto | null): void {
  if (store.selectedRalpRaKey == null) {
    return;
  }
  auEditId.value = row?.ralpraKey ?? null;
  auForm.ralpraCostAndVat = row?.ralpraCostAndVat ?? null;
  auForm.ralpraArrived = row?.ralpraArrived ?? '';
  auForm.ralpraArrivedDate = row?.ralpraArrivedDate?.slice(0, 10) ?? '';
  auForm.ralpraReturned = row?.ralpraReturned ?? '';
  auForm.ralpraReturnedDate = row?.ralpraReturnedDate?.slice(0, 10) ?? '';
  auForm.ralpraSent = row?.ralpraSent ?? '';
  auForm.ralpraSentDate = row?.ralpraSentDate?.slice(0, 10) ?? '';
  auForm.ralpraNote = row?.ralpraNote ?? '';
  auForm.ralpraStatus = row?.ralpraStatus ?? 0;
  auDialog.value = true;
}

async function submitReport(): Promise<void> {
  if (!reportForm.ralprNum.trim() || !reportForm.ralprDate || reportForm.ralprCstAgPn == null || reportForm.ralprOgSender == null) {
    $q.notify({ type: 'warning', message: 'Заполните №, дату, САК и отправителя' });
    return;
  }
  try {
    await store.saveRalpRa(
      {
        ralprNum: reportForm.ralprNum.trim(),
        ralprDate: reportForm.ralprDate,
        ralprCstAgPn: reportForm.ralprCstAgPn,
        ralprOgSender: reportForm.ralprOgSender
      },
      reportEditId.value ?? undefined
    );
    reportDialog.value = false;
  } catch {
    /* store.error */
  }
}

async function submitAu(): Promise<void> {
  if (store.selectedRalpRaKey == null) {
    return;
  }
  try {
    await store.saveRalpRaAu(
      {
        ralpraRa: store.selectedRalpRaKey,
        ralpraCostAndVat: auForm.ralpraCostAndVat,
        ralpraArrived: auForm.ralpraArrived || null,
        ralpraArrivedDate: auForm.ralpraArrivedDate || null,
        ralpraReturned: auForm.ralpraReturned || null,
        ralpraReturnedDate: auForm.ralpraReturnedDate || null,
        ralpraSent: auForm.ralpraSent || null,
        ralpraSentDate: auForm.ralpraSentDate || null,
        ralpraNote: auForm.ralpraNote || null,
        ralpraStatus: auForm.ralpraStatus
      },
      auEditId.value ?? undefined
    );
    auDialog.value = false;
  } catch {
    /* store.error */
  }
}

function confirmDeleteReport(): void {
  if (store.selectedRalpRa == null) {
    return;
  }
  const id = store.selectedRalpRa.ralprKey;
  $q.dialog({
    title: 'Удалить отчёт аренды?',
    message: `${store.selectedRalpRa.ralprNum} (ralprKey=${id})`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeRalpRa(id);
  });
}

function confirmDeleteAu(row: RalpRaAuDto): void {
  $q.dialog({
    title: 'Удалить строку Au?',
    message: `ralpraKey=${row.ralpraKey}`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeRalpRaAu(row.ralpraKey);
  });
}

function filterPn(val: string, update: (fn: () => void) => void): void {
  update(() => {
    pnFilter.value = val;
  });
}

function filterOrgs(val: string, update: (fn: () => void) => void): void {
  update(() => {
    orgFilter.value = val;
  });
}
</script>

<style scoped>
.cst-rent-tab {
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

.rent-splitter {
  width: 100%;
  height: 100%;
}

.rent-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  width: 100%;
}

.rent-list-pane {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  box-sizing: border-box;
  padding: 2px 4px;
  overflow: hidden;
  min-height: 0;
  width: 100%;
}

.rent-detail-pane {
  box-sizing: border-box;
  padding: 2px 4px;
  overflow: auto;
  min-height: 0;
  width: 100%;
}

.ralp-list-table {
  flex: 1 1 auto;
  min-height: 0;
  height: 0;
}

.rent-splitter :deep(.q-splitter__separator) {
  height: 5px;
  background: transparent;
}

.rent-splitter :deep(.q-splitter__separator-area) {
  height: 5px;
  background: color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
  border-radius: 2px;
  opacity: 0.85;
}

.rent-splitter :deep(.q-splitter__separator-area:hover) {
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

.report-card {
  padding-top: 0.25rem;
}
</style>
