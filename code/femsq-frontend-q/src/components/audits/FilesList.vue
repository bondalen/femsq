<template>
  <QCard flat bordered class="files-list-card">
    <QCardSection :class="compact ? 'files-header-compact row items-center' : 'row items-center'">
      <div :class="compact ? 'text-subtitle2' : 'text-h6'">Файлы для проверки</div>
      <QChip class="q-ml-sm" color="primary" text-color="white">
        {{ files.length }}
      </QChip>
      <QSpace />
      <QBtn
        color="primary"
        icon="add"
        label="Добавить файл"
        unelevated
        @click="handleAdd"
        :disable="!dirId"
      />
    </QCardSection>

    <QCardSection :class="compact ? 'files-body-compact' : ''">
      <div :class="compact ? 'row q-col-gutter-sm q-mb-xs' : 'row q-col-gutter-md q-mb-md'">
        <div class="col-12 col-md-6">
          <QSelect
            v-model="filterType"
            :options="filterTypeOptions"
            outlined
            dense
            emit-value
            map-options
            clearable
            placeholder="Фильтр по типу"
          />
        </div>
      </div>

      <FemsqTable
        class="files-table"
        root-class="files-table"
        row-key="afKey"
        :rows="typedFiles"
        :columns="columns"
        :loading="loading"
        :dense="compact"
        filter-label="Поиск по имени файла"
        filter-test-id="audit-files-filter"
        v-model:filter="searchQuery"
        :pagination="{ rowsPerPage: compact ? 25 : 10, sortBy: 'afNum', descending: false }"
        :rows-per-page-options="[10, 25, 50]"
        data-test="audit-files-table"
      >
        <template #body-cell-afNum="props">
          <QTd :props="props">
            <QChip size="sm" class="femsq-chip-neutral">
              {{ props.row.afNum ?? '—' }}
            </QChip>
          </QTd>
        </template>

        <template #body-cell-afName="props">
          <QTd :props="props">
            <div class="row items-center no-wrap">
              <QIcon name="description" size="sm" class="q-mr-sm" color="grey-7" />
              <span>{{ props.row.afName }}</span>
            </div>
          </QTd>
        </template>

        <template #body-cell-afType="props">
          <QTd :props="props">
            <QChip size="sm" class="femsq-chip-type">
              {{ getFileTypeName(props.row.afType) }}
            </QChip>
          </QTd>
        </template>

        <template #body-cell-raOrgSender="props">
          <QTd :props="props">
            <span class="text-body2">
              {{ getOrganizationName(props.row.raOrgSender) }}
            </span>
          </QTd>
        </template>

        <template #body-cell-afExecute="props">
          <QTd :props="props" class="text-center">
            <QIcon
              :name="props.row.afExecute ? 'check_circle' : 'radio_button_unchecked'"
              :color="props.row.afExecute ? 'positive' : 'grey-5'"
              size="sm"
            />
          </QTd>
        </template>

        <template #body-cell-afSource="props">
          <QTd :props="props" class="text-center">
            <QIcon
              v-if="props.row.afSource"
              name="table_chart"
              color="green-7"
              size="sm"
            />
            <span v-else class="text-grey-5">—</span>
          </QTd>
        </template>

        <template #body-cell-actions="props">
          <QTd :props="props">
            <QBtn
              icon="edit"
              size="sm"
              flat
              round
              color="primary"
              @click="handleEdit(props.row)"
            >
              <QTooltip>Редактировать</QTooltip>
            </QBtn>
            <QBtn
              icon="delete"
              size="sm"
              flat
              round
              color="negative"
              @click="handleDelete(props.row)"
            >
              <QTooltip>Удалить</QTooltip>
            </QBtn>
          </QTd>
        </template>

        <template #no-data>
          <div class="full-width column flex-center q-pa-lg">
            <QIcon name="folder_open" size="3em" color="grey-5" />
            <div class="text-h6 q-mt-md text-grey-7">Файлы не найдены</div>
            <div class="text-body2 text-grey-6">
              {{ dirId ? 'Добавьте первый файл для этой директории' : 'Выберите директорию' }}
            </div>
          </div>
        </template>
      </FemsqTable>
    </QCardSection>

    <FileEditDialog
      v-model="dialogOpen"
      :file="selectedFile"
      :dir-id="dirId!"
      @save="handleSave"
      @cancel="handleCancelDialog"
    />

    <QDialog v-model="deleteDialogOpen" persistent>
      <QCard>
        <QCardSection class="row items-center">
          <QIcon name="warning" color="warning" size="md" class="q-mr-md" />
          <span class="text-h6">Подтверждение удаления</span>
        </QCardSection>

        <QCardSection>
          Вы действительно хотите удалить файл
          <strong>"{{ fileToDelete?.afName }}"</strong>?
          <br />
          Это действие нельзя отменить.
        </QCardSection>

        <QCardActions align="right">
          <QBtn label="Отмена" color="grey-7" flat @click="deleteDialogOpen = false" />
          <QBtn
            label="Удалить"
            color="negative"
            unelevated
            @click="confirmDelete"
            :loading="deleteLoading"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QCard>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import {
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QChip,
  QDialog,
  QIcon,
  QSelect,
  QSpace,
  QTd,
  QTooltip,
  useQuasar
} from 'quasar';
import { FemsqTable, actionsColumn, type FemsqTableColumn } from 'fequlib';
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files';
import { useFilesStore } from '@/stores/files';
import { useLookupsStore } from '@/stores/lookups';
import FileEditDialog from './FileEditDialog.vue';

interface Props {
  dirId: number | null;
  compact?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  compact: false
});

const $q = useQuasar();
const filesStore = useFilesStore();
const lookupsStore = useLookupsStore();

const dialogOpen = ref(false);
const selectedFile = ref<RaFDto | null>(null);
const deleteDialogOpen = ref(false);
const fileToDelete = ref<RaFDto | null>(null);
const deleteLoading = ref(false);
const searchQuery = ref('');
const filterType = ref<number | null>(null);

const files = computed(() => (props.dirId ? filesStore.filesByDirId(props.dirId) : []));

const loading = computed(() => filesStore.loading);

const columns: FemsqTableColumn<RaFDto>[] = [
  {
    name: 'afNum',
    label: '№',
    field: 'afNum',
    align: 'center',
    sortable: true,
    style: 'width: 80px',
    filterValue: (row) => String(row.afNum ?? '')
  },
  {
    name: 'afName',
    label: 'Имя файла',
    field: 'afName',
    align: 'left',
    sortable: true
  },
  {
    name: 'afType',
    label: 'Тип',
    field: 'afType',
    align: 'left',
    sortable: true,
    style: 'width: 180px',
    filterValue: (row) => getFileTypeName(row.afType)
  },
  {
    name: 'raOrgSender',
    label: 'Отправитель',
    field: 'raOrgSender',
    align: 'left',
    sortable: true,
    style: 'width: 200px',
    filterValue: (row) => getOrganizationName(row.raOrgSender)
  },
  {
    name: 'afExecute',
    label: 'Рассмотрение',
    field: 'afExecute',
    align: 'center',
    sortable: true,
    style: 'width: 120px',
    filterable: false
  },
  {
    name: 'afSource',
    label: 'Из Excel',
    field: 'afSource',
    align: 'center',
    sortable: true,
    style: 'width: 100px',
    filterable: false
  },
  actionsColumn({ align: 'center', style: 'width: 120px', label: 'Действия' })
];

const filterTypeOptions = computed(() => lookupsStore.fileTypesOptions);

/** Строки после фильтра по типу; имя — через FemsqTable filter. */
const typedFiles = computed(() => {
  if (filterType.value === null) {
    return files.value;
  }
  return files.value.filter((file) => file.afType === filterType.value);
});

watch(
  () => props.dirId,
  async (newDirId) => {
    if (newDirId) {
      await filesStore.loadByDirId(newDirId);
      await lookupsStore.loadAllLookups();
    }
  },
  { immediate: true }
);

function getFileTypeName(typeId: number): string {
  return lookupsStore.fileTypeNameById(typeId);
}

function getOrganizationName(orgId: number | null): string {
  if (!orgId) return '—';
  return lookupsStore.organizationNameById(orgId);
}

function handleAdd() {
  selectedFile.value = null;
  dialogOpen.value = true;
}

function handleEdit(file: RaFDto) {
  selectedFile.value = file;
  dialogOpen.value = true;
}

function handleDelete(file: RaFDto) {
  fileToDelete.value = file;
  deleteDialogOpen.value = true;
}

async function handleSave(data: RaFCreateRequest | RaFUpdateRequest) {
  try {
    if (selectedFile.value) {
      await filesStore.update(selectedFile.value.afKey, data as RaFUpdateRequest);
      $q.notify({
        type: 'positive',
        message: 'Файл успешно обновлен',
        position: 'top-right'
      });
    } else {
      await filesStore.create(data as RaFCreateRequest);
      $q.notify({
        type: 'positive',
        message: 'Файл успешно создан',
        position: 'top-right'
      });
    }
    dialogOpen.value = false;
    if (props.dirId) {
      await filesStore.loadByDirId(props.dirId);
    }
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: `Ошибка: ${error instanceof Error ? error.message : 'Неизвестная ошибка'}`,
      position: 'top-right'
    });
  }
}

function handleCancelDialog() {
  dialogOpen.value = false;
}

async function confirmDelete() {
  if (!fileToDelete.value) return;

  deleteLoading.value = true;
  try {
    await filesStore.deleteFile(fileToDelete.value.afKey);
    $q.notify({
      type: 'positive',
      message: 'Файл успешно удален',
      position: 'top-right'
    });
    deleteDialogOpen.value = false;
    if (props.dirId) {
      await filesStore.loadByDirId(props.dirId);
    }
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: `Ошибка удаления: ${error instanceof Error ? error.message : 'Неизвестная ошибка'}`,
      position: 'top-right'
    });
  } finally {
    deleteLoading.value = false;
  }
}
</script>

<style scoped>
.files-list-card {
  display: flex;
  flex-direction: column;
  min-height: 0;
  height: 100%;
}

.files-header-compact {
  padding: 4px 8px !important;
}

.files-body-compact {
  padding: 4px !important;
  display: flex;
  flex-direction: column;
  min-height: 0;
  flex: 1 1 auto;
}

.files-table {
  flex: 1 1 auto;
  min-height: 0;
}

:deep(.files-table .q-table__middle) {
  max-height: 100%;
}
</style>
