<template>
  <QPage class="organizations-view q-pa-sm">
    <div class="org-page">
      <div class="row items-center q-gutter-sm q-mb-xs">
        <div>
          <div class="text-h6">Организации</div>
          <div class="text-caption text-grey-7">Master–detail как Access: список сверху, вкладки снизу</div>
        </div>
        <QSpace />
        <QBtn color="primary" unelevated dense icon="add" label="Создать" @click="openCreateDialog" />
        <QBtn flat round dense icon="refresh" :loading="store.loading" @click="handleRefresh" aria-label="Обновить" />
      </div>

      <div class="row q-col-gutter-sm q-mb-xs filters">
        <div class="col-12 col-md-5">
          <QInput
            v-model="searchInput"
            debounce="400"
            dense
            clearable
            label="Поиск по краткому названию"
          />
        </div>
        <div class="col-6 col-md-3">
          <QSelect
            v-model="sortOption"
            :options="sortOptions"
            emit-value
            map-options
            dense
            label="Сортировка"
          />
        </div>
      </div>

      <QBanner v-if="store.error" dense rounded class="bg-negative text-white q-mb-xs">{{ store.error }}</QBanner>

      <!-- Master: список -->
      <QTable
        flat
        bordered
        dense
        class="org-master q-mb-sm"
        :rows="store.organizations"
        :columns="masterColumns"
        row-key="ogKey"
        :loading="store.loading"
        v-model:pagination="tablePagination"
        :rows-per-page-options="[5, 10, 25]"
        selection="single"
        v-model:selected="selectedRows"
        @request="onRequest"
      >
        <template #no-data>
          <div class="text-grey-7 q-pa-sm">Нет данных</div>
        </template>
      </QTable>

      <!-- Detail: вкладки -->
      <QCard v-if="store.selectedOrganization" flat bordered class="org-detail">
        <QCardSection class="q-py-xs q-px-sm row items-center">
          <div class="text-subtitle2">{{ store.selectedOrganization.ogName }}</div>
          <QSpace />
          <div class="text-caption text-grey-7">ogKey={{ store.selectedOrganization.ogKey }}</div>
          <ContractorReportsMenu :contractor="store.selectedOrganization" />
        </QCardSection>
        <QSeparator />
        <QTabs v-model="detailTab" dense align="left" class="text-primary">
          <QTab name="ids" label="идентификаторы" />
          <QTab name="general" label="общее" />
          <QTab name="names" label="разные имена для ловли" />
        </QTabs>
        <QSeparator />
        <QTabPanels v-model="detailTab" animated>
          <!-- идентификаторы -->
          <QTabPanel name="ids" class="q-pa-sm">
            <QBanner v-if="store.orgIdsError" dense rounded class="bg-warning text-dark q-mb-xs">
              {{ store.orgIdsError }}
            </QBanner>
            <QTable
              flat
              bordered
              dense
              :rows="idRows"
              :columns="idColumns"
              row-key="orgIdKey"
              :loading="store.orgIdsLoading"
              hide-pagination
              :rows-per-page-options="[0]"
            >
              <template #body-cell-orgIdValueTExt="props">
                <QTd :props="props">
                  <QInput
                    v-if="props.row.orgIdType === 2"
                    dense
                    borderless
                    :model-value="kppDraft[props.row.orgIdKey] ?? props.row.orgIdValueTExt ?? ''"
                    placeholder="КПП"
                    :disable="store.saving"
                    @update:model-value="(v) => setKppDraft(props.row.orgIdKey, String(v ?? ''))"
                    @blur="() => void saveKpp(props.row)"
                    @keyup.enter="() => void saveKpp(props.row)"
                  />
                  <span v-else>{{ props.row.orgIdValueTExt || '' }}</span>
                </QTd>
              </template>
              <template #no-data>
                <div class="text-caption text-grey-6 q-pa-sm">Нет идентификаторов</div>
              </template>
            </QTable>
            <div class="text-caption text-grey-7 q-mt-xs q-mb-xs">
              КПП у существующего ИНН — в ячейке «расширение текстового» (Enter / уход с поля). Либо тип ИНН + ИНН + КПП → Добавить.
            </div>
            <div class="row q-col-gutter-xs items-end q-mt-sm">
              <div class="col-2">
                <QSelect
                  v-model="idForm.type"
                  :options="idTypeOptions"
                  emit-value
                  map-options
                  dense
                  label="тип"
                />
              </div>
              <div class="col-2">
                <QInput
                  v-model.number="idForm.valueL"
                  type="number"
                  dense
                  label="цифровой ключ"
                  :disable="idForm.type !== 1"
                  clearable
                />
              </div>
              <div class="col-3">
                <QInput
                  v-model="idForm.valueT"
                  dense
                  label="текстовый ключ (ИНН)"
                  :disable="idForm.type !== 2"
                  clearable
                />
              </div>
              <div class="col-3">
                <QInput
                  v-model="idForm.valueTExt"
                  dense
                  label="расширение (КПП)"
                  :disable="idForm.type !== 2"
                  clearable
                  hint="для филиалов"
                />
              </div>
              <div class="col-2">
                <QBtn
                  color="primary"
                  unelevated
                  dense
                  class="full-width"
                  label="Добавить"
                  :loading="store.saving"
                  :disable="!canAddId"
                  @click="handleAddId"
                />
              </div>
            </div>
          </QTabPanel>

          <!-- общее -->
          <QTabPanel name="general" class="q-pa-sm">
            <div class="row q-col-gutter-sm">
              <div class="col-6 col-md-3">
                <div class="text-caption text-grey-7">Налоговый режим</div>
                <div>{{ store.selectedOrganization.registrationTaxType ?? '—' }}</div>
              </div>
              <div class="col-6 col-md-3">
                <div class="text-caption text-grey-7">ИНН (поле og)</div>
                <div>{{ store.selectedOrganization.inn ?? '—' }}</div>
              </div>
              <div class="col-6 col-md-3">
                <div class="text-caption text-grey-7">Официальное имя</div>
                <div>{{ store.selectedOrganization.ogOfficialName ?? '—' }}</div>
              </div>
              <div class="col-12">
                <div class="text-caption text-grey-7">Описание</div>
                <div>{{ store.selectedOrganization.ogDescription ?? '—' }}</div>
              </div>
            </div>
            <QSeparator class="q-my-sm" />
            <div class="text-subtitle2 q-mb-xs">Контактные лица</div>
            <div v-if="store.agentsLoading"><QSpinner size="16px" /></div>
            <div v-else-if="store.agents.length === 0" class="text-caption text-grey-6">Не указаны</div>
            <QList v-else dense bordered>
              <QItem v-for="a in store.agents" :key="a.ogAgKey" dense>
                <QItemSection>{{ a.code }} <span class="text-caption text-grey-7">({{ a.ogAgKey }})</span></QItemSection>
              </QItem>
            </QList>
          </QTabPanel>

          <!-- разные имена для ловли (ogNmF) -->
          <QTabPanel name="names" class="q-pa-sm">
            <QBanner v-if="store.nameVariantsError" dense rounded class="bg-warning text-dark q-mb-xs">
              {{ store.nameVariantsError }}
            </QBanner>
            <QTable
              flat
              bordered
              dense
              :rows="store.nameVariants"
              :columns="nameColumns"
              row-key="onfKey"
              :loading="store.nameVariantsLoading"
              hide-pagination
              :rows-per-page-options="[0]"
            >
              <template #body-cell-actions="props">
                <QTd :props="props">
                  <QBtn flat dense round size="sm" icon="delete" color="negative" @click="handleDeleteName(props.row.onfKey)" />
                </QTd>
              </template>
              <template #no-data>
                <div class="text-caption text-grey-6 q-pa-sm">Нет вариантов имён</div>
              </template>
            </QTable>
            <div class="row q-col-gutter-xs items-end q-mt-sm">
              <div class="col-4">
                <QInput v-model="nameForm.onfName" dense label="организация *" :disable="store.saving" />
              </div>
              <div class="col-3">
                <QInput v-model="nameForm.onfNameExt" dense label="филиал" clearable :disable="store.saving" />
              </div>
              <div class="col-2">
                <QInput v-model="nameForm.onfStart" dense type="date" label="начало" clearable :disable="store.saving" />
              </div>
              <div class="col-2">
                <QInput v-model="nameForm.onfEnd" dense type="date" label="завершение" clearable :disable="store.saving" />
              </div>
              <div class="col-1">
                <QBtn
                  color="primary"
                  unelevated
                  dense
                  class="full-width"
                  icon="add"
                  :loading="store.saving"
                  :disable="!nameForm.onfName.trim()"
                  @click="handleAddName"
                />
              </div>
            </div>
          </QTabPanel>
        </QTabPanels>
      </QCard>
      <QBanner v-else dense rounded class="bg-grey-2">Выберите организацию в списке выше</QBanner>
    </div>

    <QDialog v-model="createOpen" persistent>
      <QCard style="min-width: 360px; max-width: 480px">
        <QCardSection class="q-py-sm">
          <div class="text-subtitle1">Новая организация</div>
        </QCardSection>
        <QSeparator />
        <QCardSection class="q-gutter-sm q-py-sm">
          <QInput v-model="createForm.ogName" dense label="Краткое наименование *" />
          <QInput v-model="createForm.ogOfficialName" dense label="Официальное наименование *" />
          <QSelect
            v-model="createForm.registrationTaxType"
            :options="taxTypeOptions"
            emit-value
            map-options
            dense
            label="тип (og, sd, ie) *"
          />
          <QInput v-model.number="createForm.buirg" type="number" dense label="БУиРГ" clearable />
          <QInput v-model="createForm.itn" dense label="ИНН" clearable />
          <QInput v-model="createForm.itnExt" dense label="КПП (расширение текстового)" clearable />
        </QCardSection>
        <QCardActions align="right" class="q-pa-sm">
          <QBtn flat dense label="Отмена" v-close-popup />
          <QBtn color="primary" unelevated dense label="Создать" :loading="store.saving" :disable="!canCreate" @click="handleCreate" />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QPage,
  QTable,
  QTd,
  QCard,
  QCardSection,
  QCardActions,
  QBtn,
  QSpace,
  QBanner,
  QInput,
  QSelect,
  QSeparator,
  QTabs,
  QTab,
  QTabPanels,
  QTabPanel,
  QList,
  QItem,
  QItemSection,
  QDialog,
  QSpinner,
  useQuasar
} from 'quasar';
import type { QTableColumn } from 'quasar';

import { useOrganizationsStore } from '@/stores/organizations';
import type { Organization } from '@/stores/organizations';
import ContractorReportsMenu from '@/modules/reports/components/ContractorReportsMenu.vue';

const store = useOrganizationsStore();
const $q = useQuasar();
const detailTab = ref<'ids' | 'general' | 'names'>('ids');

/** Локальный ввод поиска — не блокируется store.loading (иначе теряется фокус). */
const searchInput = ref(store.filters.ogName);
watch(searchInput, (value) => {
  void store.updateNameFilter(value ?? '');
});

/** Черновики КПП по org_id_key до сохранения. */
const kppDraft = reactive<Record<number, string>>({});

function setKppDraft(orgIdKey: number, value: string): void {
  kppDraft[orgIdKey] = value;
}

async function saveKpp(row: {
  orgIdKey: number;
  org: number;
  orgIdType: number;
  orgIdValueL: number | string | null;
  orgIdValueT: string | null;
  orgIdValueTExt: string | null;
}): Promise<void> {
  if (row.orgIdType !== 2) {
    return;
  }
  const next = (kppDraft[row.orgIdKey] ?? row.orgIdValueTExt ?? '').trim();
  const prev = (row.orgIdValueTExt ?? '').trim();
  if (next === prev) {
    return;
  }
  const ok = await store.updateId({
    orgIdKey: row.orgIdKey,
    org: row.org,
    orgIdType: row.orgIdType,
    orgIdValueL: null,
    orgIdValueT: row.orgIdValueT,
    orgIdValueTExt: next || null
  });
  if (ok) {
    delete kppDraft[row.orgIdKey];
    $q.notify({ type: 'positive', message: 'КПП сохранён' });
  } else if (store.orgIdsError) {
    $q.notify({ type: 'negative', message: store.orgIdsError });
  }
}

const masterColumns: QTableColumn<Organization>[] = [
  { name: 'ogName', field: 'ogName', label: 'название', align: 'left', sortable: true },
  {
    name: 'registrationTaxType',
    label: 'тип (og, sd, ie)',
    field: (row) => row.registrationTaxType ?? '—',
    align: 'left'
  }
];

const idColumns: QTableColumn[] = [
  { name: 'orgIdKey', field: 'orgIdKey', label: 'org_id_key', align: 'left' },
  { name: 'typeLabel', field: 'typeLabel', label: 'org_id_type', align: 'left' },
  { name: 'org', field: 'org', label: 'org', align: 'left' },
  { name: 'orgIdValueL', field: 'orgIdValueL', label: 'цифровой ключ', align: 'left' },
  { name: 'orgIdValueT', field: 'orgIdValueT', label: 'текстовый ключ', align: 'left' },
  { name: 'orgIdValueTExt', field: 'orgIdValueTExt', label: 'расширение текстового', align: 'left' }
];

const nameColumns: QTableColumn[] = [
  { name: 'onfName', field: 'onfName', label: 'организация', align: 'left' },
  { name: 'onfNameExt', field: 'onfNameExt', label: 'филиал', align: 'left' },
  { name: 'onfStart', field: 'onfStart', label: 'начало актуальности', align: 'left' },
  { name: 'onfEnd', field: 'onfEnd', label: 'завершение актуальности', align: 'left' },
  { name: 'actions', label: '', field: 'onfKey', align: 'right' }
];

const idRows = computed(() =>
  store.orgIds.map((r) => ({
    ...r,
    typeLabel: r.orgIdType === 1 ? 'БУИРГ' : r.orgIdType === 2 ? 'ИНН' : String(r.orgIdType),
    orgIdValueL: r.orgIdValueL ?? '',
    orgIdValueT: r.orgIdValueT ?? '',
    orgIdValueTExt: r.orgIdValueTExt ?? ''
  }))
);

const sortOptions = [
  { label: 'Наименование ↑', value: 'ogName,asc' },
  { label: 'Наименование ↓', value: 'ogName,desc' }
];
const taxTypeOptions = [
  { label: 'og', value: 'og' },
  { label: 'sd', value: 'sd' },
  { label: 'ie', value: 'ie' }
];
const idTypeOptions = [
  { label: 'БУИРГ', value: 1 },
  { label: 'ИНН', value: 2 }
];

const sortOption = computed({
  get: () => store.pagination.sort,
  set: (v: string) => {
    void store.setSort(v);
  }
});

const tablePagination = ref({
  page: store.pagination.page,
  rowsPerPage: store.pagination.size,
  rowsNumber: store.pagination.totalElements
});
watch(
  () => ({ page: store.pagination.page, size: store.pagination.size, total: store.pagination.totalElements }),
  (v) => {
    tablePagination.value.page = v.page;
    tablePagination.value.rowsPerPage = v.size;
    tablePagination.value.rowsNumber = v.total;
  }
);

async function onRequest(props: { pagination: { page: number; rowsPerPage: number } }): Promise<void> {
  const { page, rowsPerPage } = props.pagination;
  tablePagination.value.page = page;
  tablePagination.value.rowsPerPage = rowsPerPage;
  if (rowsPerPage !== store.pagination.size) {
    await store.setPageSize(rowsPerPage);
  } else if (page !== store.pagination.page) {
    await store.setPage(page);
  }
  tablePagination.value.rowsNumber = store.pagination.totalElements;
}

const selectedRows = computed({
  get: () => (store.selectedOrganization ? [store.selectedOrganization] : []),
  set: (rows: Organization[]) => {
    if (rows[0]) {
      void store.selectOrganization(rows[0].ogKey);
    }
  }
});

const idForm = reactive({
  type: 2 as 1 | 2,
  valueL: null as number | null,
  valueT: '',
  valueTExt: ''
});

const nameForm = reactive({
  onfName: '',
  onfNameExt: '',
  onfStart: '',
  onfEnd: ''
});

const createOpen = ref(false);
const createForm = reactive({
  ogName: '',
  ogOfficialName: '',
  registrationTaxType: 'og',
  buirg: null as number | null,
  itn: '',
  itnExt: ''
});

const canCreate = computed(
  () => createForm.ogName.trim().length > 0 && createForm.ogOfficialName.trim().length > 0
);

const canAddId = computed(() => {
  if (idForm.type === 1) {
    return idForm.valueL != null && Number(idForm.valueL) > 0;
  }
  return idForm.valueT.trim().length > 0;
});

watch(
  () => createForm.ogName,
  (name) => {
    if (!createForm.ogOfficialName.trim()) {
      createForm.ogOfficialName = name;
    }
  }
);

function openCreateDialog(): void {
  createForm.ogName = '';
  createForm.ogOfficialName = '';
  createForm.registrationTaxType = 'og';
  createForm.buirg = null;
  createForm.itn = '';
  createForm.itnExt = '';
  createOpen.value = true;
}

async function handleCreate(): Promise<void> {
  const created = await store.createWithIds({
    ogName: createForm.ogName.trim(),
    ogOfficialName: createForm.ogOfficialName.trim(),
    registrationTaxType: createForm.registrationTaxType,
    buirg: createForm.buirg != null && Number(createForm.buirg) > 0 ? Number(createForm.buirg) : null,
    itn: createForm.itn.trim() || null,
    itnExt: createForm.itnExt.trim() || null
  });
  if (created) {
    createOpen.value = false;
    detailTab.value = 'ids';
    $q.notify({ type: 'positive', message: `Создана «${created.ogName}»` });
  } else if (store.error) {
    $q.notify({ type: 'negative', message: store.error });
  }
}

async function handleAddId(): Promise<void> {
  const ok = await store.attachIds({
    buirg: idForm.type === 1 && idForm.valueL != null ? Number(idForm.valueL) : null,
    itn: idForm.type === 2 ? idForm.valueT.trim() : null,
    itnExt: idForm.type === 2 ? idForm.valueTExt.trim() || null : null
  });
  if (ok) {
    idForm.valueL = null;
    idForm.valueT = '';
    idForm.valueTExt = '';
    $q.notify({ type: 'positive', message: 'Идентификатор добавлен' });
  } else if (store.orgIdsError) {
    $q.notify({ type: 'negative', message: store.orgIdsError });
  }
}

async function handleAddName(): Promise<void> {
  const ok = await store.addNameVariant({
    onfName: nameForm.onfName.trim(),
    onfNameExt: nameForm.onfNameExt.trim() || null,
    onfStart: nameForm.onfStart || null,
    onfEnd: nameForm.onfEnd || null
  });
  if (ok) {
    nameForm.onfName = '';
    nameForm.onfNameExt = '';
    nameForm.onfStart = '';
    nameForm.onfEnd = '';
    $q.notify({ type: 'positive', message: 'Вариант имени добавлен' });
  } else if (store.nameVariantsError) {
    $q.notify({ type: 'negative', message: store.nameVariantsError });
  }
}

async function handleDeleteName(onfKey: number): Promise<void> {
  const ok = await store.removeNameVariant(onfKey);
  if (ok) {
    $q.notify({ type: 'positive', message: 'Вариант имени удалён' });
  } else if (store.nameVariantsError) {
    $q.notify({ type: 'negative', message: store.nameVariantsError });
  }
}

function handleRefresh(): void {
  void store.fetchOrganizations({ keepSelection: true });
}

onMounted(() => {
  if (!store.hasOrganizations) {
    void store.fetchOrganizations();
  }
});
</script>

<style scoped>
.organizations-view {
  background: var(--femsq-bg-page);
  min-height: 100%;
}

.org-master :deep(.q-table th),
.org-master :deep(.q-table td),
.org-detail :deep(.q-table th),
.org-detail :deep(.q-table td) {
  padding: 2px 6px;
}

.org-master :deep(.q-table__top),
.org-master :deep(.q-table__bottom) {
  padding: 4px 6px;
  min-height: 32px;
}

.org-detail :deep(.q-tab-panel) {
  padding-top: 8px;
}

.filters {
  align-items: flex-end;
}
</style>
