<template>
  <v-card>
    <v-card-title class="d-flex align-center">
      <v-icon icon="mdi-file-multiple-outline" class="mr-2" />
      Файлы для проверки
      <v-chip class="ml-2" size="small" color="primary">
        {{ files.length }}
      </v-chip>
      <v-spacer />
      <v-btn
        color="primary"
        prepend-icon="mdi-plus"
        @click="handleAdd"
        :disabled="!dirId"
      >
        Добавить файл
      </v-btn>
    </v-card-title>
    
    <v-card-text>
      <!-- Фильтры -->
      <v-row class="mb-4">
        <v-col cols="12" md="6">
          <v-text-field
            v-model="search"
            prepend-inner-icon="mdi-magnify"
            label="Поиск по имени файла"
            variant="outlined"
            density="compact"
            clearable
            hide-details
          />
        </v-col>
        
        <v-col cols="12" md="6">
          <v-select
            v-model="filterType"
            :items="fileTypeFilterOptions"
            label="Фильтр по типу"
            variant="outlined"
            density="compact"
            clearable
            hide-details
          />
        </v-col>
      </v-row>
      
      <!-- Таблица файлов -->
      <v-data-table
        :headers="headers"
        :items="filteredFiles"
        :loading="loading"
        :sort-by="[{ key: 'afNum', order: 'asc' }]"
        class="elevation-1"
        density="comfortable"
        :items-per-page="25"
        :items-per-page-options="[10, 25, 50, 100]"
      >
        <template #item.afNum="{ item }">
          <span class="text-grey">{{ item.afNum ?? '—' }}</span>
        </template>
        
        <template #item.afName="{ item }">
          <div class="d-flex align-center">
            <v-icon icon="mdi-file-document-outline" size="small" class="mr-2" />
            <span class="font-weight-medium">{{ item.afName }}</span>
          </div>
        </template>
        
        <template #item.afType="{ item }">
          <v-chip size="small" color="primary" variant="tonal">
            {{ getFileTypeName(item.afType) }}
          </v-chip>
        </template>
        
        <template #item.raOrgSender="{ item }">
          <span class="text-body-2">
            {{ getOrganizationName(item.raOrgSender) }}
          </span>
        </template>
        
        <template #item.afExecute="{ item }">
          <v-icon
            :icon="item.afExecute ? 'mdi-check-circle' : 'mdi-circle-outline'"
            :color="item.afExecute ? 'success' : 'grey'"
            size="small"
          />
        </template>
        
        <template #item.afSource="{ item }">
          <v-icon
            v-if="item.afSource"
            icon="mdi-table-large"
            color="info"
            size="small"
          />
          <span v-else class="text-grey">—</span>
        </template>
        
        <template #item.actions="{ item }">
          <v-btn
            icon="mdi-pencil"
            variant="text"
            size="small"
            @click="handleEdit(item)"
          />
          <v-btn
            icon="mdi-delete"
            variant="text"
            size="small"
            color="error"
            @click="handleDelete(item)"
          />
        </template>
        
        <template #no-data>
          <v-alert type="info" variant="tonal" class="ma-4">
            {{ dirId ? 'Файлы не найдены' : 'Выберите директорию для отображения файлов' }}
          </v-alert>
        </template>
        
        <template #loading>
          <v-skeleton-loader type="table-row@10" />
        </template>
      </v-data-table>
    </v-card-text>
    
    <!-- Диалог редактирования -->
    <FileEditDialog
      v-model="dialogOpen"
      :file="selectedFile"
      :dir-id="dirId!"
      @save="handleSave"
      @cancel="handleCancelDialog"
    />
    
    <!-- Диалог подтверждения удаления -->
    <v-dialog v-model="deleteDialogOpen" max-width="400">
      <v-card>
        <v-card-title class="text-h6">Подтверждение удаления</v-card-title>
        <v-card-text>
          Вы уверены, что хотите удалить файл<br>
          <strong>{{ fileToDelete?.afName }}</strong>?
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="deleteDialogOpen = false">Отмена</v-btn>
          <v-btn color="error" variant="flat" @click="confirmDelete" :loading="deleting">
            Удалить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    
    <!-- Snackbar для уведомлений -->
    <v-snackbar v-model="snackbar" :color="snackbarColor" :timeout="3000">
      {{ snackbarText }}
      <template #actions>
        <v-btn icon="mdi-close" size="small" @click="snackbar = false" />
      </template>
    </v-snackbar>
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files'
import { useFilesStore } from '@/stores/files'
import { useLookupsStore } from '@/stores/lookups'
import FileEditDialog from './FileEditDialog.vue'

interface Props {
  dirId: number | null
}

const props = defineProps<Props>()

const filesStore = useFilesStore()
const lookupsStore = useLookupsStore()

// State
const search = ref('')
const filterType = ref<number | null>(null)
const dialogOpen = ref(false)
const selectedFile = ref<RaFDto | null>(null)
const deleteDialogOpen = ref(false)
const fileToDelete = ref<RaFDto | null>(null)
const deleting = ref(false)

// Snackbar
const snackbar = ref(false)
const snackbarText = ref('')
const snackbarColor = ref<'success' | 'error'>('success')

// Computed
const files = computed(() => filesStore.sortedFiles)
const loading = computed(() => filesStore.loading)

const fileTypeFilterOptions = computed(() => [
  { title: 'Все типы', value: null },
  ...lookupsStore.fileTypesOptions.map(opt => ({
    title: opt.label,
    value: opt.value
  }))
])

const filteredFiles = computed(() => {
  let result = files.value
  
  // Фильтр по поиску
  if (search.value) {
    const searchLower = search.value.toLowerCase()
    result = result.filter(file => 
      file.afName.toLowerCase().includes(searchLower)
    )
  }
  
  // Фильтр по типу
  if (filterType.value !== null) {
    result = result.filter(file => file.afType === filterType.value)
  }
  
  return result
})

// Table headers
const headers = [
  { title: '№', key: 'afNum', width: '80px', sortable: true },
  { title: 'Имя файла', key: 'afName', sortable: true },
  { title: 'Тип', key: 'afType', width: '200px', sortable: true },
  { title: 'Отправитель', key: 'raOrgSender', width: '200px', sortable: false },
  { title: 'Рассмотрение', key: 'afExecute', width: '120px', align: 'center', sortable: true },
  { title: 'Из Excel', key: 'afSource', width: '100px', align: 'center', sortable: true },
  { title: 'Действия', key: 'actions', width: '120px', align: 'center', sortable: false }
]

// Watchers
watch(() => props.dirId, async (newDirId) => {
  if (newDirId) {
    await loadFiles(newDirId)
    await lookupsStore.loadAllLookups()
  }
}, { immediate: true })

// Methods
async function loadFiles(dirId: number) {
  try {
    await filesStore.loadByDirId(dirId)
  } catch (error) {
    showSnackbar('Ошибка загрузки файлов', 'error')
  }
}

function getFileTypeName(typeId: number): string {
  return lookupsStore.fileTypeNameById(typeId)
}

function getOrganizationName(orgId: number | null): string {
  return lookupsStore.organizationNameById(orgId)
}

function handleAdd() {
  selectedFile.value = null
  dialogOpen.value = true
}

function handleEdit(file: RaFDto) {
  selectedFile.value = file
  dialogOpen.value = true
}

async function handleSave(data: RaFCreateRequest | RaFUpdateRequest) {
  try {
    if (selectedFile.value) {
      await filesStore.update(selectedFile.value.afKey, data as RaFUpdateRequest)
      showSnackbar('Файл успешно обновлен', 'success')
    } else {
      await filesStore.create(data as RaFCreateRequest)
      showSnackbar('Файл успешно создан', 'success')
    }
    dialogOpen.value = false
  } catch (error) {
    showSnackbar('Ошибка сохранения файла', 'error')
  }
}

function handleCancelDialog() {
  dialogOpen.value = false
  selectedFile.value = null
}

function handleDelete(file: RaFDto) {
  fileToDelete.value = file
  deleteDialogOpen.value = true
}

async function confirmDelete() {
  if (!fileToDelete.value) return
  
  deleting.value = true
  try {
    await filesStore.deleteFile(fileToDelete.value.afKey)
    showSnackbar('Файл успешно удален', 'success')
    deleteDialogOpen.value = false
    fileToDelete.value = null
  } catch (error) {
    showSnackbar('Ошибка удаления файла', 'error')
  } finally {
    deleting.value = false
  }
}

function showSnackbar(text: string, color: 'success' | 'error') {
  snackbarText.value = text
  snackbarColor.value = color
  snackbar.value = true
}
</script>

<style scoped>
.v-data-table :deep(.v-data-table__td) {
  white-space: nowrap;
}
</style>
