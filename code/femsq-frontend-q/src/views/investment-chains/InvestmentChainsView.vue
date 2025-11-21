<template>
  <QPage class="investment-chains-view q-pa-none">
    <div class="q-pa-lg">
      <div class="row items-center q-gutter-md q-mb-md">
        <div>
          <div class="text-h5">Цепочки инвестиционных программ</div>
          <div class="text-caption text-grey-7">Список цепочек и связанные инвестиционные программы</div>
        </div>
        <QSpace />
        <QBtn
          flat
          round
          icon="refresh"
          :loading="store.loading"
          :disable="store.loading"
          @click="handleRefresh"
          aria-label="Обновить"
        />
      </div>

      <div class="row q-col-gutter-md q-mb-md filters">
        <div class="col-12 col-md-6 col-lg-4">
          <QInput
            v-model="searchTerm"
            debounce="400"
            label="Поиск по названию"
            clearable
            dense
            :disable="store.loading"
            placeholder="Введите часть названия"
            data-testid="investment-chains-filter"
          />
        </div>
        <div class="col-12 col-md-3 col-lg-2">
          <QInput
            v-model.number="yearFilter"
            debounce="400"
            label="Год"
            type="number"
            clearable
            dense
            :disable="store.loading"
            placeholder="Год"
            data-testid="investment-chains-year-filter"
          />
        </div>
        <div class="col-6 col-md-3 col-lg-2">
          <QSelect
            v-model="sortOption"
            :options="sortOptions"
            emit-value
            map-options
            dense
            label="Сортировка"
            :disable="store.loading"
          />
        </div>
      </div>

      <QBanner v-if="store.error" class="bg-negative text-white q-mb-md" rounded>
        {{ store.error }}
      </QBanner>
      <QBanner v-else-if="store.relationsError" class="bg-warning text-dark q-mb-md" rounded>
        {{ store.relationsError }}
      </QBanner>
      <QBanner v-if="stNetworksStore.error" class="bg-warning text-dark q-mb-md" rounded>
        Ошибка загрузки справочника структур сетей: {{ stNetworksStore.error }}
      </QBanner>
      <QBanner v-if="investmentProgramsStore.error" class="bg-warning text-dark q-mb-md" rounded>
        Ошибка загрузки справочника инвестиционных программ: {{ investmentProgramsStore.error }}
      </QBanner>
      <QBanner v-if="planGroupsStore.error" class="bg-warning text-dark q-mb-md" rounded>
        Ошибка загрузки справочника групп планов: {{ planGroupsStore.error }}
      </QBanner>
      <div v-if="store.lastUpdatedAt" class="text-caption text-grey-6 q-mb-md">
        Данные актуальны на {{ formatDate(store.lastUpdatedAt) }}
      </div>

      <div class="row q-col-gutter-lg">
        <div class="col-12 col-lg-7">
          <QTable
            flat
            bordered
            title="Список цепочек"
            :rows="store.chains"
            :columns="columns"
            row-key="chainKey"
            :loading="store.loading || stNetworksStore.loading"
            v-model:pagination="tablePagination"
            :rows-per-page-options="rowsPerPageOptionValues"
            selection="single"
            v-model:selected="selectedRows"
            @request="onRequest"
          >
            <template #body-cell-stNetName="props">
              <QTd :props="props">
                <template v-if="stNetworksStore.loading">
                  <QSpinner size="16px" color="primary" />
                </template>
                <template v-else>
                  <template v-if="props.row.stNetKey">
                    <QChip
                      :label="getStNetworkName(props.row.stNetKey, props.row.stNetName)"
                      color="info"
                      text-color="white"
                      dense
                      size="sm"
                    />
                  </template>
                  <template v-else>
                    <span class="text-grey-6">—</span>
                  </template>
                </template>
              </QTd>
            </template>
            <template #body-cell-year="props">
              <QTd :props="props">
                <template v-if="props.row.year">
                  <QChip
                    :label="String(props.row.year)"
                    color="accent"
                    text-color="white"
                    dense
                    size="sm"
                  />
                </template>
                <template v-else>
                  <span class="text-grey-6">—</span>
                </template>
              </QTd>
            </template>
            <template #body-cell-relationsCount="props">
              <QTd :props="props">
                <QChip color="primary" text-color="white" dense>
                  {{ props.row.relationsCount }}
                </QChip>
              </QTd>
            </template>
            <template #loading>
              <QInnerLoading showing>
                <QSpinner color="primary" size="2.5em" />
              </QInnerLoading>
            </template>
            <template #no-data>
              <div class="text-grey-7 q-pa-lg">
                <span v-if="searchTerm || yearFilter">По указанному фильтру цепочки не найдены.</span>
                <span v-else>Данные отсутствуют.</span>
              </div>
            </template>
          </QTable>
        </div>

        <div class="col-12 col-lg-5">
          <transition name="fade">
            <QCard v-if="store.selectedChain" class="chain-card" flat bordered>
              <QCardSection>
                <div class="text-h6 q-mb-xs">{{ store.selectedChain.name }}</div>
                <div class="text-caption text-grey-7">Ключ: {{ store.selectedChain.chainKey }}</div>
              </QCardSection>
              <QSeparator />
              <QCardSection>
                <div class="row q-col-gutter-md">
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">Структура сети</div>
                    <div class="text-body2">
                      <template v-if="stNetworksStore.loading">
                        <QSpinner size="16px" color="primary" />
                      </template>
                      <template v-else>
                        {{ getStNetworkName(store.selectedChain.stNetKey, store.selectedChain.stNetName) }}
                      </template>
                    </div>
                  </div>
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">Год</div>
                    <div class="text-body2">{{ store.selectedChain.year ?? '—' }}</div>
                  </div>
                </div>
              </QCardSection>

              <QSeparator />
              <QCardSection>
                <div class="row items-center q-mb-sm">
                  <div class="text-subtitle2">Инвестиционные программы</div>
                  <QSpace />
                  <template v-if="store.relationsLoading">
                    <QSpinner size="18px" color="primary" />
                  </template>
                  <template v-else>
                    <QBadge color="primary" align="middle">{{ store.relations.length }}</QBadge>
                  </template>
                </div>
                <div v-if="!store.relationsLoading && store.relations.length === 0" class="text-caption text-grey-6">
                  Инвестиционные программы не указаны.
                </div>
                <QTable
                  v-if="!store.relationsLoading && store.relations.length > 0"
                  flat
                  bordered
                  :rows="filteredRelations"
                  :columns="relationColumns"
                  row-key="relationKey"
                  :loading="investmentProgramsStore.loading || planGroupsStore.loading"
                  :pagination="{ rowsPerPage: 0 }"
                  hide-pagination
                >
                  <template #body-cell-investmentProgramName="props">
                    <QTd :props="props">
                      <template v-if="investmentProgramsStore.loading">
                        <QSpinner size="16px" color="primary" />
                      </template>
                      <template v-else>
                        <QChip
                          :label="getInvestmentProgramName(props.row.investmentProgramKey, props.row.investmentProgramName)"
                          color="primary"
                          text-color="white"
                          dense
                          size="sm"
                        />
                      </template>
                    </QTd>
                  </template>
                  <template #body-cell-planGroupName="props">
                    <QTd :props="props">
                      <template v-if="planGroupsStore.loading">
                        <QSpinner size="16px" color="primary" />
                      </template>
                      <template v-else>
                        <template v-if="props.row.planGroupKey">
                          <QChip
                            :label="getPlanGroupName(props.row.planGroupKey, props.row.planGroupName)"
                            color="secondary"
                            text-color="white"
                            dense
                            size="sm"
                          />
                        </template>
                        <template v-else>
                          <span class="text-grey-6">—</span>
                        </template>
                      </template>
                    </QTd>
                  </template>
                  <template #no-data>
                    <div class="text-grey-7 q-pa-lg text-center">
                      <template v-if="relationSearchTerm || relationPlanGroupFilter !== null">
                        <div class="q-mb-sm">
                          <QIcon name="search_off" size="2em" color="grey-6" />
                        </div>
                        <div>По указанным фильтрам программы не найдены.</div>
                        <div class="text-caption q-mt-xs">
                          <QBtn
                            flat
                            dense
                            size="sm"
                            label="Сбросить фильтры"
                            @click="resetRelationFilters"
                            color="primary"
                          />
                        </div>
                      </template>
                      <template v-else>
                        <div>Программы отсутствуют.</div>
                      </template>
                    </div>
                  </template>
                </QTable>
                <div v-if="!store.relationsLoading && store.relations.length > 0" class="q-mt-sm">
                  <div class="row q-col-gutter-sm">
                    <div class="col-12 col-md-6">
                      <QInput
                        v-model="relationSearchTerm"
                        debounce="300"
                        label="Поиск по программе"
                        clearable
                        dense
                        placeholder="Введите часть названия программы"
                      />
                    </div>
                    <div class="col-12 col-md-6">
                      <QSelect
                        v-model="relationPlanGroupFilter"
                        :options="planGroupFilterOptions"
                        emit-value
                        map-options
                        label="Фильтр по группе планов"
                        clearable
                        dense
                        placeholder="Все группы"
                      />
                    </div>
                  </div>
                </div>
              </QCardSection>
            </QCard>
          </transition>

          <QBanner v-if="!store.selectedChain" class="bg-grey-2" rounded>
            Выберите цепочку из списка, чтобы увидеть детали и связанные программы.
          </QBanner>
        </div>
      </div>
    </div>
  </QPage>
</template>
<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import {
  QPage,
  QTable,
  QTd,
  QBanner,
  QBadge,
  QCard,
  QCardSection,
  QBtn,
  QSpace,
  QChip,
  QInnerLoading,
  QSpinner,
  QSeparator,
  QInput,
  QSelect,
  QIcon
} from 'quasar';
import type { QTableColumn } from 'quasar';

import { useInvestmentChainsStore } from '@/stores/investment-chains';
import type { InvestmentChain, InvestmentChainRelation } from '@/stores/investment-chains';
import { useStNetworksStore } from '@/stores/lookups/st-networks';
import { useInvestmentProgramsStore } from '@/stores/lookups/investment-programs';
import { usePlanGroupsStore } from '@/stores/lookups/plan-groups';

const store = useInvestmentChainsStore();
const stNetworksStore = useStNetworksStore();
const investmentProgramsStore = useInvestmentProgramsStore();
const planGroupsStore = usePlanGroupsStore();

const relationSearchTerm = ref('');
const relationPlanGroupFilter = ref<number | null>(null);

const columns: QTableColumn<InvestmentChain>[] = [
  { name: 'name', field: 'name', label: 'Название', align: 'left', sortable: true },
  {
    name: 'stNetName',
    label: 'Структура сети',
    field: 'stNetName',
    align: 'left'
  },
  {
    name: 'year',
    label: 'Год',
    field: 'year',
    align: 'center',
    sortable: true,
    format: (val: number | null) => val ?? '—'
  },
  { name: 'relationsCount', field: 'relationsCount', label: 'Программ', align: 'center', sortable: true }
];

const relationColumns: QTableColumn<InvestmentChainRelation>[] = [
  {
    name: 'investmentProgramName',
    label: 'Инвестиционная программа',
    field: 'investmentProgramName',
    align: 'left'
  },
  {
    name: 'planGroupName',
    label: 'Группа планов',
    field: 'planGroupName',
    align: 'left'
  }
];

const rowsPerPageOptions = [
  { label: '5', value: 5 },
  { label: '10', value: 10 },
  { label: '25', value: 25 }
];
const rowsPerPageOptionValues = rowsPerPageOptions.map((item) => item.value);

const sortOptions = [
  { label: 'Название ↑', value: 'name,asc' },
  { label: 'Название ↓', value: 'name,desc' },
  { label: 'Год ↑', value: 'year,asc' },
  { label: 'Год ↓', value: 'year,desc' }
];

const searchTerm = computed({
  get: () => store.filters.name,
  set: (value: string) => {
    void store.updateNameFilter(value);
  }
});

const yearFilter = computed({
  get: () => store.filters.year,
  set: (value: number | null) => {
    // Валидация: год должен быть в разумных пределах (1900-2100)
    if (value !== null && (value < 1900 || value > 2100)) {
      console.warn('[investment-chains-view] Invalid year filter:', value);
      return;
    }
    void store.updateYearFilter(value);
  }
});

const sortOption = computed({
  get: () => store.pagination.sort,
  set: (value: string) => {
    void store.setSort(value);
  }
});

const tablePagination = ref({
  page: store.pagination.page,
  rowsPerPage: store.pagination.size,
  rowsNumber: store.pagination.totalElements
});

// Синхронизация tablePagination с store (store → UI)
watch(
  () => ({ page: store.pagination.page, size: store.pagination.size, total: store.pagination.totalElements }),
  (newVal) => {
    tablePagination.value.page = newVal.page;
    tablePagination.value.rowsPerPage = newVal.size;
    tablePagination.value.rowsNumber = newVal.total;
  }
);

async function onRequest(props: { pagination: { page: number; rowsPerPage: number } }): Promise<void> {
  const { page, rowsPerPage } = props.pagination;
  
  // Обновляем локальную пагинацию
  tablePagination.value.page = page;
  tablePagination.value.rowsPerPage = rowsPerPage;
  
  const pageChanged = page !== store.pagination.page;
  const sizeChanged = rowsPerPage !== store.pagination.size;
  
  if (sizeChanged) {
    await store.setPageSize(rowsPerPage);
  } else if (pageChanged) {
    await store.setPage(page);
  }
  
  // Обновляем rowsNumber после загрузки данных
  tablePagination.value.rowsNumber = store.pagination.totalElements;
}

const selectedRows = computed({
  get: () => (store.selectedChain ? [store.selectedChain] : []),
  set: (rows: InvestmentChain[]) => {
    const first = rows[0];
    if (first) {
      void store.selectChain(first.chainKey);
    }
  }
});

const planGroupFilterOptions = computed(() => {
  const uniqueGroups = new Map<number, string>();
  store.relations.forEach((rel) => {
    if (rel.planGroupKey !== null && rel.planGroupKey !== undefined) {
      const name = rel.planGroupName ?? planGroupsStore.getPlanGroupName(rel.planGroupKey) ?? `ID: ${rel.planGroupKey}`;
      uniqueGroups.set(rel.planGroupKey, name);
    }
  });
  return Array.from(uniqueGroups.entries())
    .map(([key, name]) => ({ label: name, value: key }))
    .sort((a, b) => a.label.localeCompare(b.label));
});

const filteredRelations = computed(() => {
  let filtered = store.relations;

  // Фильтр по группе планов
  if (relationPlanGroupFilter.value !== null) {
    filtered = filtered.filter((rel) => rel.planGroupKey === relationPlanGroupFilter.value);
  }

  // Фильтр по поисковому запросу
  if (relationSearchTerm.value.trim()) {
    const search = relationSearchTerm.value.toLowerCase().trim();
    filtered = filtered.filter((rel) => {
      const programName = rel.investmentProgramName?.toLowerCase() ?? '';
      const planGroupName = rel.planGroupName?.toLowerCase() ?? '';
      return programName.includes(search) || planGroupName.includes(search);
    });
  }

  return filtered;
});

function getStNetworkName(key: number | null | undefined, fallbackName: string | null | undefined): string {
  if (fallbackName) {
    return fallbackName;
  }
  const lookupName = stNetworksStore.getStNetworkName(key);
  return lookupName ?? '—';
}

function getInvestmentProgramName(key: number | null | undefined, fallbackName: string | null | undefined): string {
  if (fallbackName) {
    return fallbackName;
  }
  const lookupName = investmentProgramsStore.getInvestmentProgramName(key);
  if (lookupName) {
    return lookupName;
  }
  return key !== null && key !== undefined ? `ID: ${key}` : '—';
}

function getPlanGroupName(key: number | null | undefined, fallbackName: string | null | undefined): string {
  if (fallbackName) {
    return fallbackName;
  }
  const lookupName = planGroupsStore.getPlanGroupName(key);
  if (lookupName) {
    return lookupName;
  }
  return key !== null && key !== undefined ? `ID: ${key}` : '—';
}

function resetRelationFilters(): void {
  relationSearchTerm.value = '';
  relationPlanGroupFilter.value = null;
}

function handleRefresh(): void {
  void store.fetchChains({ keepSelection: true });
  void stNetworksStore.fetchStNetworks();
  void investmentProgramsStore.fetchInvestmentPrograms();
  void planGroupsStore.fetchPlanGroups();
}

function formatDate(value: string): string {
  if (!value) {
    return '';
  }
  try {
    return new Intl.DateTimeFormat('ru-RU', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(value));
  } catch (error) {
    return value;
  }
}

onMounted(async () => {
  // Загружаем lookup данные
  if (stNetworksStore.stNetworks.length === 0 && !stNetworksStore.loading) {
    await stNetworksStore.fetchStNetworks();
  }
  if (investmentProgramsStore.investmentPrograms.length === 0 && !investmentProgramsStore.loading) {
    await investmentProgramsStore.fetchInvestmentPrograms();
  }
  if (planGroupsStore.planGroups.length === 0 && !planGroupsStore.loading) {
    await planGroupsStore.fetchPlanGroups();
  }
  
  // Загружаем цепочки
  if (!store.hasChains) {
    await store.fetchChains();
  }
});
</script>
<style scoped>
.investment-chains-view {
  background: var(--q-background, #f5f6f8);
  min-height: 100%;
}

.chain-card {
  min-height: 420px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.24s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.filters {
  align-items: flex-end;
}
</style>
