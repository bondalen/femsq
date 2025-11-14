<template>
  <QPage class="organizations-view q-pa-none">
    <div class="q-pa-lg">
      <div class="row items-center q-gutter-md q-mb-md">
        <div>
          <div class="text-h5">Организации</div>
          <div class="text-caption text-grey-7">Список организаций и связанные контактные лица</div>
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
            label="Поиск по краткому названию"
            clearable
            dense
            :disable="store.loading"
            placeholder="Введите часть наименования"
            data-testid="organizations-filter"
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
      <QBanner v-else-if="store.agentsError" class="bg-warning text-dark q-mb-md" rounded>
        {{ store.agentsError }}
      </QBanner>
      <div v-if="store.lastUpdatedAt" class="text-caption text-grey-6 q-mb-md">
        Данные актуальны на {{ formatDate(store.lastUpdatedAt) }}
      </div>

      <div class="row q-col-gutter-lg">
        <div class="col-12 col-lg-7">
          <QTable
            flat
            bordered
            title="Список организаций"
            :rows="store.organizations"
            :columns="columns"
            row-key="ogKey"
            :loading="store.loading"
            v-model:pagination="tablePagination"
            :rows-per-page-options="rowsPerPageOptionValues"
            selection="single"
            v-model:selected="selectedRows"
            @request="onRequest"
          >
            <template #body-cell-ogAgCount="props">
              <QTd :props="props">
                <QChip color="primary" text-color="white" dense>
                  {{ props.row.ogAgCount }}
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
                <span v-if="searchTerm">По указанному фильтру организации не найдены.</span>
                <span v-else>Данные отсутствуют.</span>
              </div>
            </template>
          </QTable>
        </div>

        <div class="col-12 col-lg-5">
          <transition name="fade">
            <QCard v-if="store.selectedOrganization" class="organization-card" flat bordered>
              <QCardSection>
                <div class="text-h6 q-mb-xs">{{ store.selectedOrganization.ogName }}</div>
                <div class="text-caption text-grey-7">Ключ: {{ store.selectedOrganization.ogKey }}</div>
              </QCardSection>
              <QSeparator />
              <QCardSection>
                <div class="row q-col-gutter-md">
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">ИНН</div>
                    <div class="text-body2">{{ store.selectedOrganization.inn ?? '—' }}</div>
                  </div>
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">КПП</div>
                    <div class="text-body2">{{ store.selectedOrganization.kpp ?? '—' }}</div>
                  </div>
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">ОГРН</div>
                    <div class="text-body2">{{ store.selectedOrganization.ogrn ?? '—' }}</div>
                  </div>
                  <div class="col-12 col-sm-6">
                    <div class="text-caption text-grey-7">ОКПО</div>
                    <div class="text-body2">{{ store.selectedOrganization.okpo ?? '—' }}</div>
                  </div>
                  <div class="col-12">
                    <div class="text-caption text-grey-7">Налоговый режим</div>
                    <div class="text-body2">{{ store.selectedOrganization.registrationTaxType ?? '—' }}</div>
                  </div>
                  <div class="col-12">
                    <div class="text-caption text-grey-7">Описание</div>
                    <div class="text-body2">{{ store.selectedOrganization.ogDescription ?? '—' }}</div>
                  </div>
                </div>
              </QCardSection>

              <QSeparator />
              <QCardSection>
                <div class="row items-center q-mb-sm">
                  <div class="text-subtitle2">Контактные лица</div>
                  <QSpace />
                  <template v-if="store.agentsLoading">
                    <QSpinner size="18px" color="primary" />
                  </template>
                  <template v-else>
                    <QBadge color="primary" align="middle">{{ store.agents.length }}</QBadge>
                  </template>
                </div>
                <div v-if="!store.agentsLoading && store.agents.length === 0" class="text-caption text-grey-6">
                  Контактные лица не указаны.
                </div>
                <QList v-if="!store.agentsLoading && store.agents.length > 0" bordered class="rounded-borders">
                  <QItem v-for="agent in store.agents" :key="agent.ogAgKey">
                    <QItemSection avatar>
                      <QAvatar icon="person" color="primary" text-color="white" />
                    </QItemSection>
                    <QItemSection>
                      <div class="text-body2 text-weight-medium">{{ agent.code }}</div>
                      <div class="text-caption text-grey-7">Ключ: {{ agent.ogAgKey }}</div>
                      <div class="text-caption" v-if="agent.legacyOid">Legacy OID: {{ agent.legacyOid }}</div>
                    </QItemSection>
                  </QItem>
                </QList>
              </QCardSection>
            </QCard>
          </transition>

          <QBanner v-if="!store.selectedOrganization" class="bg-grey-2" rounded>
            Выберите организацию из списка, чтобы увидеть детали и контакты.
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
  QList,
  QItem,
  QItemSection,
  QBanner,
  QBadge,
  QCard,
  QCardSection,
  QBtn,
  QSpace,
  QChip,
  QInnerLoading,
  QSpinner,
  QAvatar,
  QSeparator,
  QInput,
  QSelect,
  QPagination
} from 'quasar';
import type { QTableColumn } from 'quasar';

import { useOrganizationsStore } from '@/stores/organizations';
import type { Organization } from '@/stores/organizations';

const store = useOrganizationsStore();

const columns: QTableColumn<Organization>[] = [
  { name: 'ogName', field: 'ogName', label: 'Организация', align: 'left', sortable: true },
  {
    name: 'registrationTaxType',
    label: 'Налоговый режим',
    field: (row: Organization) => row.registrationTaxType ?? '—',
    align: 'left'
  },
  { name: 'inn', label: 'ИНН', field: (row: Organization) => row.inn ?? '—', align: 'left' },
  { name: 'ogAgCount', field: 'ogAgCount', label: 'Контактов', align: 'center', sortable: true }
];

const rowsPerPageOptions = [
  { label: '5', value: 5 },
  { label: '10', value: 10 },
  { label: '25', value: 25 }
];
const rowsPerPageOptionValues = rowsPerPageOptions.map((item) => item.value);

const sortOptions = [
  { label: 'Наименование ↑', value: 'ogName,asc' },
  { label: 'Наименование ↓', value: 'ogName,desc' }
];

const searchTerm = computed({
  get: () => store.filters.ogName,
  set: (value: string) => {
    void store.updateNameFilter(value);
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
  get: () => (store.selectedOrganization ? [store.selectedOrganization] : []),
  set: (rows: Organization[]) => {
    const first = rows[0];
    if (first) {
      void store.selectOrganization(first.ogKey);
    }
  }
});

function handleRefresh(): void {
  void store.fetchOrganizations({ keepSelection: true });
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

onMounted(() => {
  if (!store.hasOrganizations) {
    void store.fetchOrganizations();
  }
});
</script>

<style scoped>
.organizations-view {
  background: var(--q-background, #f5f6f8);
  min-height: 100%;
}

.organization-card {
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
