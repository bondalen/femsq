<template>
  <QPage class="sudz-debts-view q-pa-md column no-wrap" data-test="sudz-debts-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Долги / мероприятия</div>
        <div class="femsq-page-subtitle">
          СУДЗ · Rslt
          <span v-if="store.selectedYear">· yr {{ store.selectedYear.yrKey }}</span>
        </div>
      </div>
      <QBtn
        flat
        dense
        icon="refresh"
        :loading="store.loading"
        aria-label="Обновить"
        data-test="sudz-refresh"
        @click="reload"
      />
    </div>

    <div class="row q-col-gutter-sm q-mb-sm items-end">
      <div class="col-12 col-sm-3 col-md-2">
        <QSelect
          v-model="yearModel"
          :options="yearOptions"
          emit-value
          map-options
          dense
          outlined
          label="Год-вариант"
          :disable="store.loading"
          data-test="sudz-year-select"
        />
      </div>
      <div class="col-12 col-sm-3 col-md-2">
        <QSelect
          v-model="store.accountFilter"
          :options="store.accountOptions"
          emit-value
          map-options
          dense
          outlined
          clearable
          label="Счёт ГК"
          :disable="store.loading"
          data-test="sudz-account-filter"
        />
      </div>
      <div class="col-12 col-sm-4 col-md-5">
        <QInput
          v-model="store.searchTerm"
          dense
          outlined
          clearable
          debounce="300"
          label="Поиск контрагент / договор / СФ"
          :disable="store.loading"
          data-test="sudz-search"
        />
      </div>
      <div class="col-auto">
        <QBtn flat dense no-caps label="Сброс" data-test="sudz-reset-filters" @click="store.resetFilters()" />
      </div>
      <div v-if="store.selectedYear" class="col-12 text-caption text-grey-7">
        База upl {{ store.selectedYear.baseUpl ?? '—' }}
        · группа комментариев {{ store.selectedYear.cmmGr ?? '—' }}
        · yyyy {{ store.selectedYear.yyyy ?? '—' }}
      </div>
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>
      {{ store.error }}
    </QBanner>

    <div class="row q-col-gutter-md col">
      <div class="col-12 col-lg-7 column">
        <FemsqTable
          class="portfolio-table"
          root-class="portfolio-table"
          row-key="dbtKey"
          :rows="store.filteredRows"
          :columns="columns"
          :loading="store.loading"
          v-model:filter="tableFilter"
          v-model:pagination="pagination"
          v-model:selected="selectedRows"
          selection="single"
          filter-label="Фильтр таблицы"
          filter-test-id="sudz-table-filter"
          data-test="sudz-debts-table"
          @row-click="onRowClick"
        />
      </div>

      <div class="col-12 col-lg-5">
        <QCard v-if="store.selectedDebt" flat bordered class="detail-card" data-test="sudz-debt-detail">
          <QCardSection>
            <div class="text-subtitle1">
              {{ store.selectedDebt.dbtKey }}
              <span class="text-grey-7"> · {{ store.selectedRow?.accountNum ?? '—' }}</span>
            </div>
            <div class="text-body2">{{ store.selectedRow?.counterpart ?? '—' }}</div>
            <div class="text-caption text-grey-7">
              {{ store.selectedDebt.cstCode ?? '—' }} · {{ store.selectedDebt.cstName ?? '—' }}
            </div>
          </QCardSection>
          <QSeparator />
          <QCardSection>
            <div class="text-caption text-grey-7 q-mb-xs">Реквизиты по срезам (чтение)</div>
            <div class="periods-scroll">
              <div
                v-for="period in store.selectedDebt.periods"
                :key="period.uplKey"
                class="period-row q-mb-sm"
              >
                <div class="text-caption text-weight-medium">
                  {{ period.uplDate ?? '—' }} · upl {{ period.uplKey }}
                </div>
                <div class="text-caption">
                  СФ {{ period.invNumEnum ?? '—' }} · договор {{ period.cnNumEnum ?? '—' }} · Overd
                  {{ formatMoney(period.overd) }}
                  <span v-if="period.pogasheno != null"> · погашено {{ formatMoney(period.pogasheno) }}</span>
                </div>
              </div>
            </div>
          </QCardSection>
          <QSeparator />
          <QCardSection>
            <div class="text-subtitle2 q-mb-sm">Сбор на дату отчёта</div>
            <QInput
              v-model="form.curator"
              dense
              outlined
              class="q-mb-sm"
              label="Куратор"
              data-test="sudz-curator"
            />
            <QInput
              v-model="form.mery"
              dense
              outlined
              type="textarea"
              autogrow
              class="q-mb-sm"
              label="Мероприятия"
              data-test="sudz-mery"
            />
            <QInput
              v-model="form.cstCode"
              dense
              outlined
              class="q-mb-sm"
              label="Код стройки (cstAgPn)"
              hint="Напр. 051-2001061"
              data-test="sudz-cst-code"
            />
            <div class="row items-center q-gutter-sm">
              <QBtn
                color="primary"
                unelevated
                no-caps
                label="Сохранить"
                :loading="store.saving"
                data-test="sudz-save"
                @click="onSave"
              />
              <span v-if="store.saveStatus" class="text-caption text-positive">{{ store.saveStatus }}</span>
            </div>
          </QCardSection>
          <QSeparator />
          <QCardSection>
            <div class="row items-center q-gutter-sm q-mb-sm">
              <div class="text-subtitle2">Превью D644</div>
              <QSpace />
              <QInput
                v-model.number="currUpl"
                dense
                outlined
                type="number"
                style="max-width: 110px"
                label="currUpl"
                data-test="sudz-curr-upl"
              />
              <QBtn
                flat
                dense
                no-caps
                label="Загрузить"
                :loading="store.d644Loading"
                data-test="sudz-d644-preview"
                @click="store.loadD644Preview(currUpl)"
              />
            </div>
            <div v-if="store.d644Preview" class="text-caption" data-test="sudz-d644-comment">
              <div><strong>СФ:</strong> {{ store.d644Preview.invoice }}</div>
              <div class="q-mt-xs"><strong>Комментарий 644:</strong></div>
              <pre class="d644-comment">{{ store.d644Preview.comment644 }}</pre>
            </div>
            <div v-else class="text-caption text-grey-7">После сохранения загрузите превью — mery должен совпасть с комментарием 644.</div>
          </QCardSection>
        </QCard>
        <div v-else class="text-grey-7 q-pa-md">Выберите долг в списке.</div>
      </div>
    </div>
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardSection,
  QInput,
  QPage,
  QSelect,
  QSeparator,
  QSpace,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { useSudzDebtsStore } from '@/stores/sudz-debts';
import type { SudzPortfolioRow } from '@/types/sudz';

const store = useSudzDebtsStore();
const $q = useQuasar();

const tableFilter = ref('');
const pagination = ref({ page: 1, rowsPerPage: 25 });
const selectedRows = ref<SudzPortfolioRow[]>([]);
const currUpl = ref(902);

const form = reactive({
  curator: '',
  mery: '',
  cstCode: ''
});

const columns: FemsqTableColumn<SudzPortfolioRow>[] = [
  { name: 'dbtKey', label: 'dbtKey', field: 'dbtKey', align: 'right', style: 'width: 72px', sortable: true },
  {
    name: 'accountNum',
    label: 'СГК',
    field: 'accountNum',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.accountNum ?? '')
  },
  {
    name: 'counterpart',
    label: 'Контрагент',
    field: 'counterpart',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.counterpart ?? '')
  },
  {
    name: 'baseOverd',
    label: 'Overd base',
    field: 'baseOverd',
    align: 'right',
    sortable: true,
    format: (val: unknown) => formatMoney(typeof val === 'number' ? val : null)
  },
  {
    name: 'invoice',
    label: 'Документ',
    field: 'invoice',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.invoice ?? '')
  },
  {
    name: 'cstCode',
    label: 'Стройка',
    field: 'cstCode',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.cstCode ?? '')
  },
  {
    name: 'curator',
    label: 'Куратор',
    field: 'curator',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.curator ?? '')
  }
];

const yearOptions = computed(() =>
  store.years.map((y) => ({
    label: `${y.yrKey}${y.yyyy != null ? ` (${y.yyyy})` : ''}`,
    value: y.yrKey
  }))
);

const yearModel = computed({
  get: () => store.selectedYr,
  set: (value: number | null) => {
    if (value != null) {
      void store.selectYear(value);
    }
  }
});

watch(
  () => store.selectedDebt,
  (debt) => {
    selectedRows.value = store.selectedRow ? [store.selectedRow] : [];
    form.curator = debt?.curator ?? '';
    form.mery = debt?.mery ?? '';
    form.cstCode = debt?.cstCode ?? '';
  },
  { immediate: true }
);

onMounted(async () => {
  await store.loadYears();
  await store.loadPortfolio();
});

/**
 * Обновляет портфель.
 */
async function reload(): Promise<void> {
  await store.loadPortfolio();
}

/**
 * Выбор строки master.
 */
function onRowClick(_evt: Event, row: SudzPortfolioRow): void {
  store.selectDebt(row.dbtKey);
}

/**
 * Сохраняет сбор.
 */
async function onSave(): Promise<void> {
  const ok = await store.saveCollection({
    curator: form.curator,
    mery: form.mery,
    cstCode: form.cstCode
  });
  if (ok) {
    $q.notify({ type: 'positive', message: 'Сбор сохранён', timeout: 1500 });
  }
}

/**
 * Форматирует денежную сумму.
 */
function formatMoney(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) {
    return '—';
  }
  return new Intl.NumberFormat('ru-RU', { maximumFractionDigits: 2 }).format(value);
}
</script>

<style scoped>
.sudz-debts-view {
  min-height: 0;
}

.portfolio-table {
  min-height: 280px;
}

.detail-card {
  max-height: calc(100vh - 160px);
  overflow: auto;
}

.periods-scroll {
  max-height: 160px;
  overflow: auto;
}

.period-row {
  border-left: 2px solid var(--femsq-border, #ddd);
  padding-left: 8px;
}

.d644-comment {
  white-space: pre-wrap;
  font-family: inherit;
  margin: 0;
  max-height: 180px;
  overflow: auto;
}
</style>
