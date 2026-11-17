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

      <div class="row q-col-gutter-md q-mb-md items-end">
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
          <FemsqTable
            mode="server"
            title="Список цепочек"
            row-key="chainKey"
            :rows="store.chains"
            :columns="columns"
            :loading="store.loading || stNetworksStore.loading"
            filter-label="Поиск по названию"
            filter-test-id="investment-chains-filter"
            v-model:filter="nameFilter"
            v-model:pagination="tablePagination"
            :rows-per-page-options="rowsPerPageOptionValues"
            selection="single"
            v-model:selected="selectedRows"
            data-test="investment-chains-table"
            @request="onMasterRequest"
            @row-click="onMasterRowClick"
          >
            <template #body-cell-stNetName="props">
              <QTd :props="props">
                <template v-if="stNetworksStore.loading">
                  <QSpinner size="16px" color="primary" />
                </template>
                <template v-else-if="props.row.stNetKey">
                  <QChip
                    :label="getStNetworkName(props.row.stNetKey, props.row.stNetName)"
                    color="info"
                    text-color="white"
                    dense
                    size="sm"
                  />
                </template>
                <span v-else class="text-grey-6">—</span>
              </QTd>
            </template>
            <template #body-cell-year="props">
              <QTd :props="props">
                <QChip
                  v-if="props.row.year"
                  :label="String(props.row.year)"
                  color="accent"
                  text-color="white"
                  dense
                  size="sm"
                />
                <span v-else class="text-grey-6">—</span>
              </QTd>
            </template>
            <template #body-cell-relationsCount="props">
              <QTd :props="props">
                <QChip color="primary" text-color="white" dense>
                  {{ props.row.relationsCount }}
                </QChip>
              </QTd>
            </template>
            <template #no-data>
              <div class="text-grey-7 q-pa-lg">
                <span v-if="nameFilter || yearFilter">По указанному фильтру цепочки не найдены.</span>
                <span v-else>Данные отсутствуют.</span>
              </div>
            </template>
          </FemsqTable>
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
                <div class="row items-center q-mb-sm q-col-gutter-sm">
                  <div class="text-subtitle2">Инвестиционные программы</div>
                  <QSpace />
                  <ObjectsReportsMenu
                    :items="
                      selectedRelations.map((rel) => ({
                        objectId: rel.investmentProgramKey ?? rel.relationKey,
                        label: rel.investmentProgramName ?? rel.planGroupName
                      }))
                    "
                  />
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
                <FemsqTable
                  v-if="!store.relationsLoading && store.relations.length > 0"
                  row-key="relationKey"
                  :rows="store.relations"
                  :columns="relationColumns"
                  :loading="investmentProgramsStore.loading || planGroupsStore.loading"
                  filter-label="Поиск по программе"
                  filter-test-id="investment-relations-filter"
                  v-model:filter="relationSearchTerm"
                  v-model:column-filters="relationColumnFilters"
                  :show-column-filters="true"
                  selection="multiple"
                  v-model:selected="selectedRelations"
                  :pagination="{ rowsPerPage: 0 }"
                  hide-pagination
                  data-test="investment-relations-table"
                >
                  <template #body-cell-investmentProgramName="props">
                    <QTd :props="props">
                      <template v-if="investmentProgramsStore.loading">
                        <QSpinner size="16px" color="primary" />
                      </template>
                      <QChip
                        v-else
                        :label="
                          getInvestmentProgramName(
                            props.row.investmentProgramKey,
                            props.row.investmentProgramName
                          )
                        "
                        color="primary"
                        text-color="white"
                        dense
                        size="sm"
                      />
                    </QTd>
                  </template>
                  <template #body-cell-planGroupName="props">
                    <QTd :props="props">
                      <template v-if="planGroupsStore.loading">
                        <QSpinner size="16px" color="primary" />
                      </template>
                      <template v-else-if="props.row.planGroupKey">
                        <QChip
                          :label="getPlanGroupName(props.row.planGroupKey, props.row.planGroupName)"
                          color="secondary"
                          text-color="white"
                          dense
                          size="sm"
                        />
                      </template>
                      <span v-else class="text-grey-6">—</span>
                    </QTd>
                  </template>
                  <template #no-data>
                    <div class="text-grey-7 q-pa-lg text-center">
                      <div>По фильтру программы не найдены.</div>
                    </div>
                  </template>
                </FemsqTable>
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
  QTd,
  QBanner,
  QBadge,
  QCard,
  QCardSection,
  QBtn,
  QSpace,
  QChip,
  QSpinner,
  QSeparator,
  QInput
} from 'quasar';
import {
  FemsqTable,
  type FemsqTableColumn,
  type FemsqTableRequest
} from 'fequlib';

import { useInvestmentChainsStore } from '@/stores/investment-chains';
import type { InvestmentChain, InvestmentChainRelation } from '@/stores/investment-chains';
import { useStNetworksStore } from '@/stores/lookups/st-networks';
import { useInvestmentProgramsStore } from '@/stores/lookups/investment-programs';
import { usePlanGroupsStore } from '@/stores/lookups/plan-groups';
import ObjectsReportsMenu from '@/modules/reports/components/ObjectsReportsMenu.vue';

const store = useInvestmentChainsStore();
const stNetworksStore = useStNetworksStore();
const investmentProgramsStore = useInvestmentProgramsStore();
const planGroupsStore = usePlanGroupsStore();

const nameFilter = ref(store.filters.name);
const relationSearchTerm = ref('');
const relationColumnFilters = ref<Record<string, string>>({});
const selectedRelations = ref<InvestmentChainRelation[]>([]);

const columns: FemsqTableColumn<InvestmentChain>[] = [
  { name: 'name', field: 'name', label: 'Название', align: 'left', sortable: true },
  {
    name: 'stNetName',
    label: 'Структура сети',
    field: 'stNetName',
    align: 'left',
    filterValue: (row) => getStNetworkName(row.stNetKey, row.stNetName)
  },
  {
    name: 'year',
    label: 'Год',
    field: 'year',
    align: 'center',
    sortable: true,
    format: (val: unknown) => (val === null || val === undefined || val === '' ? '—' : String(val))
  },
  {
    name: 'relationsCount',
    field: 'relationsCount',
    label: 'Программ',
    align: 'center',
    sortable: true,
    filterValue: (row) => String(row.relationsCount ?? '')
  }
];

const relationColumns: FemsqTableColumn<InvestmentChainRelation>[] = [
  {
    name: 'investmentProgramName',
    label: 'Инвестиционная программа',
    field: 'investmentProgramName',
    align: 'left',
    filterValue: (row) =>
      getInvestmentProgramName(row.investmentProgramKey, row.investmentProgramName)
  },
  {
    name: 'planGroupName',
    label: 'Группа планов',
    field: 'planGroupName',
    align: 'left',
    filterValue: (row) => getPlanGroupName(row.planGroupKey, row.planGroupName)
  }
];

const rowsPerPageOptionValues = [5, 10, 25];

const yearFilter = computed({
  get: () => store.filters.year,
  set: (value: number | null) => {
    if (value !== null && (value < 1900 || value > 2100)) {
      console.warn('[investment-chains-view] Invalid year filter:', value);
      return;
    }
    void store.updateYearFilter(value);
  }
});

const tablePagination = ref({
  page: store.pagination.page,
  rowsPerPage: store.pagination.size,
  rowsNumber: store.pagination.totalElements,
  sortBy: 'ipgcKey' as string | null,
  descending: false
});

watch(
  () => ({ page: store.pagination.page, size: store.pagination.size, total: store.pagination.totalElements }),
  (newVal) => {
    tablePagination.value.page = newVal.page;
    tablePagination.value.rowsPerPage = newVal.size;
    tablePagination.value.rowsNumber = newVal.total;
  }
);

watch(
  () => store.selectedChainKey,
  () => {
    selectedRelations.value = [];
    relationSearchTerm.value = '';
    relationColumnFilters.value = {};
  }
);

watch(
  () => store.relations,
  () => {
    selectedRelations.value = [];
  }
);

/**
 * Server-запрос master-списка цепочек.
 */
async function onMasterRequest(request: FemsqTableRequest): Promise<void> {
  const rowsPerPage = request.rowsPerPage >= 1 ? request.rowsPerPage : 10;
  const sortBy = request.sortBy || 'ipgcKey';
  const sortField = sortBy === 'name' ? 'name' : sortBy === 'year' ? 'year' : 'ipgcKey';
  const sort = `${sortField},${request.descending ? 'desc' : 'asc'}`;

  tablePagination.value = {
    page: request.page,
    rowsPerPage,
    rowsNumber: tablePagination.value.rowsNumber,
    sortBy,
    descending: request.descending
  };

  nameFilter.value = request.filter ?? '';

  const filterChanged = (request.filter ?? '') !== store.filters.name;
  const sortChanged = sort !== store.pagination.sort;
  const sizeChanged = rowsPerPage !== store.pagination.size;
  const pageChanged = request.page !== store.pagination.page;

  if (filterChanged) {
    await store.updateNameFilter(request.filter ?? '');
  } else if (sortChanged) {
    await store.setSort(sort);
  } else if (sizeChanged) {
    await store.setPageSize(rowsPerPage);
  } else if (pageChanged) {
    await store.setPage(request.page);
  }

  tablePagination.value.rowsNumber = store.pagination.totalElements;
}

function onMasterRowClick(_evt: Event, row: InvestmentChain): void {
  void store.selectChain(row.chainKey);
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

function getStNetworkName(key: number | null | undefined, fallbackName: string | null | undefined): string {
  if (fallbackName) {
    return fallbackName;
  }
  const lookupName = stNetworksStore.getStNetworkName(key);
  return lookupName ?? '—';
}

function getInvestmentProgramName(
  key: number | null | undefined,
  fallbackName: string | null | undefined
): string {
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
  } catch {
    return value;
  }
}

onMounted(async () => {
  if (stNetworksStore.stNetworks.length === 0 && !stNetworksStore.loading) {
    await stNetworksStore.fetchStNetworks();
  }
  if (investmentProgramsStore.investmentPrograms.length === 0 && !investmentProgramsStore.loading) {
    await investmentProgramsStore.fetchInvestmentPrograms();
  }
  if (planGroupsStore.planGroups.length === 0 && !planGroupsStore.loading) {
    await planGroupsStore.fetchPlanGroups();
  }

  if (!store.hasChains) {
    await store.fetchChains();
  }
});
</script>

<style scoped>
.investment-chains-view {
  background: var(--femsq-bg-page);
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
</style>
