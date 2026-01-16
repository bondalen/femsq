<template>
  <q-card flat bordered>
    <q-card-section class="row items-center">
      <div class="text-h6">Файлы для проверки</div>
      <q-chip class="q-ml-sm" color="primary" text-color="white">
        {{ files.length }}
      </q-chip>
      <q-space />
      <q-btn
        color="primary"
        icon="add"
        label="Добавить файл"
        unelevated
        @click="handleAdd"
        :disable="!dirId"
      />
    </q-card-section>

    <q-card-section>
      <!-- Фильтры -->
      <div class="row q-col-gutter-md q-mb-md">
        <div class="col-12 col-md-6">
          <q-input
            v-model="searchQuery"
            outlined
            dense
            placeholder="Поиск по имени файла..."
            clearable
          >
            <template v-slot:prepend>
              <q-icon name="search" />
            </template>
          </q-input>
        </div>
        <div class="col-12 col-md-6">
          <q-select
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

      <!-- Таблица -->
      <q-table
        :rows="filteredFiles"
        :columns="columns"
        row-key="afKey"
        :loading="loading"
        flat
        bordered
        :rows-per-page-options="[10, 25, 50]"
        :pagination="{ rowsPerPage: 10, sortBy: 'afNum', descending: false }"
      >
        <!-- Колонка: Номер -->
        <template v-slot:body-cell-afNum="props">
          <q-td :props="props">
            <q-chip size="sm" color="grey-3">
              {{ props.row.afNum ?? '—' }}
            </q-chip>
          </q-td>
        </template>

        <!-- Колонка: Имя файла -->
        <template v-slot:body-cell-afName="props">
          <q-td :props="props">
            <div class="row items-center no-wrap">
              <q-icon name="description" size="sm" class="q-mr-sm" color="grey-7" />
              <span>{{ props.row.afName }}</span>
            </div>
          </q-td>
        </template>

        <!-- Колонка: Тип -->
        <template v-slot:body-cell-afType="props">
          <q-td :props="props">
            <q-chip size="sm" color="blue-2" text-color="blue-9">
              {{ getFileTypeName(props.row.afType) }}
            </q-chip>
          </q-td>
        </template>

        <!-- Колонка: Отправитель -->
        <template v-slot:body-cell-raOrgSender="props">
          <q-td :props="props">
            <span class="text-body2">
              {{ getOrganizationName(props.row.raOrgSender) }}
            </span>
          </q-td>
        </template>

        <!-- Колонка: Рассмотрение -->
        <template v-slot:body-cell-afExecute="props">
          <q-td :props="props" class="text-center">
            <q-icon
              :name="props.row.afExecute ? 'check_circle' : 'radio_button_unchecked'"
              :color="props.row.afExecute ? 'positive' : 'grey-5'"
              size="sm"
            />
          </q-td>
        </template>

        <!-- Колонка: Из Excel -->
        <template v-slot:body-cell-afSource="props">
          <q-td :props="props" class="text-center">
            <q-icon
              v-if="props.row.afSource"
              name="table_chart"
              color="green-7"
              size="sm"
            />
            <span v-else class="text-grey-5">—</span>
          </q-td>
        </template>

        <!-- Колонка: Действия -->
        <template v-slot:body-cell-actions="props">
          <q-td :props="props">
            <q-btn
              icon="edit"
              size="sm"
              flat
              round
              color="primary"
              @click="handleEdit(props.row)"
            >
              <q-tooltip>Редактировать</q-tooltip>
            </q-btn>
            <q-btn
              icon="delete"
              size="sm"
              flat
              round
              color="negative"
              @click="handleDelete(props.row)"
            >
              <q-tooltip>Удалить</q-tooltip>
            </q-btn>
          </q-td>
        </template>

        <!-- Нет данных -->
        <template v-slot:no-data>
          <div class="full-width column flex-center q-pa-lg">
            <q-icon name="folder_open" size="3em" color="grey-5" />
            <div class="text-h6 q-mt-md text-grey-7">Файлы не найдены</div>
            <div class="text-body2 text-grey-6">
              {{ dirId ? 'Добавьте первый файл для этой директории' : 'Выберите директорию' }}
            </div>
          </div>
        </template>

        <!-- Загрузка -->
        <template v-slot:loading>
          <q-inner-loading showing>
            <q-spinner-dots size="50px" color="primary" />
          </q-inner-loading>
        </template>
      </q-table>
    </q-card-section>

    <!-- Диалог редактирования -->
    <FileEditDialog
      v-model="dialogOpen"
      :file="selectedFile"
      :dir-id="dirId!"
      @save="handleSave"
      @cancel="handleCancelDialog"
    />

    <!-- Диалог подтверждения удаления -->
    <q-dialog v-model="deleteDialogOpen" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-icon name="warning" color="warning" size="md" class="q-mr-md" />
          <span class="text-h6">Подтверждение удаления</span>
        </q-card-section>

        <q-card-section>
          Вы действительно хотите удалить файл
          <strong>"{{ fileToDelete?.afName }}"</strong>?
          <br />
          Это действие нельзя отменить.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn label="Отмена" color="grey-7" flat @click="deleteDialogOpen = false" />
          <q-btn
            label="Удалить"
            color="negative"
            unelevated
            @click="confirmDelete"
            :loading="deleteLoading"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-card>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useQuasar } from 'quasar';
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files';
import { useFilesStore } from '@/stores/files';
import { useLookupsStore } from '@/stores/lookups';
import FileEditDialog from './FileEditDialog.vue';

interface Props {
  dirId: number | null;
}

const props = defineProps<Props>();

const $q = useQuasar();
const filesStore = useFilesStore();
const lookupsStore = useLookupsStore();

// State
const dialogOpen = ref(false);
const selectedFile = ref<RaFDto | null>(null);
const deleteDialogOpen = ref(false);
const fileToDelete = ref<RaFDto | null>(null);
const deleteLoading = ref(false);
const searchQuery = ref('');
const filterType = ref<number | null>(null);

// Computed
const files = computed(() => 
  props.dirId ? filesStore.filesByDirId(props.dirId) : []
);

const loading = computed(() => filesStore.loading);

const columns = [
  {
    name: 'afNum',
    label: '№',
    field: 'afNum',
    align: 'center' as const,
    sortable: true,
    style: 'width: 80px'
  },
  {
    name: 'afName',
    label: 'Имя файла',
    field: 'afName',
    align: 'left' as const,
    sortable: true
  },
  {
    name: 'afType',
    label: 'Тип',
    field: 'afType',
    align: 'left' as const,
    sortable: true,
    style: 'width: 180px'
  },
  {
    name: 'raOrgSender',
    label: 'Отправитель',
    field: 'raOrgSender',
    align: 'left' as const,
    sortable: true,
    style: 'width: 200px'
  },
  {
    name: 'afExecute',
    label: 'Рассмотрение',
    field: 'afExecute',
    align: 'center' as const,
    sortable: true,
    style: 'width: 120px'
  },
  {
    name: 'afSource',
    label: 'Из Excel',
    field: 'afSource',
    align: 'center' as const,
    sortable: true,
    style: 'width: 100px'
  },
  {
    name: 'actions',
    label: 'Действия',
    field: 'actions',
    align: 'center' as const,
    style: 'width: 120px'
  }
];

const filterTypeOptions = computed(() => lookupsStore.fileTypesOptions);

const filteredFiles = computed(() => {
  let result = files.value;

  // Фильтр по поиску
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter((file) =>
      file.afName.toLowerCase().includes(query)
    );
  }

  // Фильтр по типу
  if (filterType.value !== null) {
    result = result.filter((file) => file.afType === filterType.value);
  }

  return result;
});

// Watchers
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

// Methods
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
      // Редактирование
      await filesStore.update(selectedFile.value.afKey, data as RaFUpdateRequest);
      $q.notify({
        type: 'positive',
        message: 'Файл успешно обновлен',
        position: 'top-right'
      });
    } else {
      // Создание
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
