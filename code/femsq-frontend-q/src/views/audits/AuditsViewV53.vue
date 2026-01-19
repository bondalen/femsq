<template>
  <QPage class="audits-view q-pa-md">
    <div class="row q-col-gutter-md" style="height: calc(100vh - 150px);">
      <!-- Левая панель: список ревизий -->
      <div class="col-12 audits-list-panel">
        <QCard flat bordered class="audits-list-card full-height">
          <QCardSection class="row items-center justify-between">
            <div class="text-h6">Ревизии</div>
            <QBtn
              flat
              round
              icon="refresh"
              :loading="auditsStore.loading"
              :disable="auditsStore.loading"
              @click="handleRefresh"
              aria-label="Обновить"
            />
          </QCardSection>
          <QSeparator />
          <QCardSection class="q-pa-none">
            <QList bordered separator>
              <QItem
                v-for="audit in sortedAudits"
                :key="audit.adtKey"
                clickable
                :active="selectedAuditId === audit.adtKey"
                @click="handleSelectAudit(audit.adtKey)"
                class="audit-list-item"
              >
                <QItemSection>
                  <QItemLabel>{{ audit.adtName }}</QItemLabel>
                  <QItemLabel caption v-if="audit.adtDate">
                    {{ formatDate(audit.adtDate) }}
                  </QItemLabel>
                </QItemSection>
              </QItem>
              <QItem v-if="sortedAudits.length === 0 && !auditsStore.loading" class="text-grey-7">
                <QItemSection>
                  <QItemLabel>Ревизии не найдены</QItemLabel>
                </QItemSection>
              </QItem>
            </QList>
          </QCardSection>
          <QSeparator />
          <QCardActions>
            <QBtn
              unelevated
              color="primary"
              icon="add"
              label="Создать новую"
              class="full-width"
              @click="handleCreateNew"
            />
          </QCardActions>
        </QCard>
      </div>

      <!-- Основная область: форма ревизии -->
      <div class="col-12 audit-form-panel">
        <QCard flat bordered class="audit-form-card full-height">
          <QCardSection v-if="selectedAudit || isNewAudit" class="compact-form-section">
            <div class="text-h6 compact-title">{{ isNewAudit ? 'Новая ревизия' : 'Редактирование ревизии' }}</div>
            
            <QBanner v-if="errorMessage" class="bg-negative text-white compact-banner" rounded>
              {{ errorMessage }}
            </QBanner>

            <QForm @submit.prevent="handleSave" class="compact-form">
              <!-- Имя ревизии -->
              <QInput
                v-model="form.adtName"
                label="Имя ревизии *"
                :error="!!errors.adtName"
                :error-message="errors.adtName"
                :disable="saving"
                outlined
                dense
              />

              <!-- Тип ревизии -->
              <QSelect
                v-model="form.adtType"
                :options="auditTypesOptions"
                option-value="atKey"
                option-label="atName"
                emit-value
                map-options
                label="Ревизия, тип *"
                :loading="auditTypesStore.loading"
                :error="!!errors.adtType"
                :error-message="errors.adtType"
                :disable="saving"
                outlined
                dense
                clearable
              />

              <!-- Директория -->
              <QSelect
                v-model="form.adtDir"
                :options="directoriesOptions"
                option-value="key"
                option-label="dirName"
                emit-value
                map-options
                label="Директория *"
                :loading="directoriesStore.loading"
                :error="!!errors.adtDir"
                :error-message="errors.adtDir"
                :disable="saving"
                outlined
                dense
                clearable
              />

              <!-- Дата и время -->
              <div class="row q-col-gutter-sm">
                <div class="col-12 col-md-6">
                  <QInput
                    v-model="form.adtDateDate"
                    label="Дата *"
                    type="date"
                    :error="!!errors.adtDate"
                    :error-message="errors.adtDate"
                    :disable="saving"
                    outlined
                    dense
                  />
                </div>
                <div class="col-12 col-md-6">
                  <QInput
                    v-model="form.adtDateTime"
                    label="Время *"
                    type="time"
                    :error="!!errors.adtDate"
                    :disable="saving"
                    outlined
                    dense
                  />
                </div>
              </div>

              <!-- Чекбокс "обновляем базу данных?" -->
              <QCheckbox
                v-model="form.adtAddRA"
                label="Обновляем базу данных?"
                :disable="saving"
              />

              <!-- Кнопки действий -->
              <div class="row q-gutter-sm compact-buttons">
                <QBtn
                  type="submit"
                  unelevated
                  color="primary"
                  icon="save"
                  label="Сохранить"
                  :loading="saving"
                  :disable="!isFormValid"
                />
                <QBtn
                  flat
                  color="primary"
                  icon="play_arrow"
                  label="Выполнить ревизию"
                  :disable="isNewAudit || saving"
                  @click="handleExecuteAudit"
                />
              </div>
            </QForm>
          </QCardSection>

          <!-- Вкладки -->
          <QSeparator v-if="selectedAudit || isNewAudit" />
          <QCardSection v-if="selectedAudit || isNewAudit" class="q-pa-none">
            <QTabs v-model="activeTab" dense class="text-grey" active-color="primary" indicator-color="primary">
              <QTab name="progress" label="Ход ревизии" />
              <QTab name="files" label="Файлы для проверки" />
            </QTabs>
            <QSeparator />
            <QTabPanels v-model="activeTab" animated>
              <QTabPanel name="progress">
                <div class="q-pa-md">
                  <div class="text-body2 text-grey-7">
                    Лог выполнения ревизии будет отображаться здесь после реализации функции "Выполнить ревизию".
                  </div>
                </div>
              </QTabPanel>
              <QTabPanel name="files">
                <div class="q-pa-md">
                  <!-- Информация о директории (включая файлы внутри) -->
                  <DirectoryInfo 
                    v-if="selectedAudit"
                    :directory="currentDirectory" 
                    :loading="loadingDirectory" 
                  />
                  
                  <div v-else class="text-body2 text-grey-7 text-center q-pa-md">
                    Выберите ревизию для просмотра директории
                  </div>
                </div>
              </QTabPanel>
            </QTabPanels>
          </QCardSection>

          <!-- Сообщение, когда ревизия не выбрана -->
          <QCardSection v-if="!selectedAudit && !isNewAudit" class="text-center text-grey-7 q-pa-xl">
            <QIcon name="info" size="48px" class="q-mb-md" />
            <div class="text-body1">Выберите ревизию из списка или создайте новую</div>
          </QCardSection>
        </QCard>
      </div>
    </div>

    <!-- Диалог подтверждения выполнения ревизии -->
    <QDialog v-model="executeDialogOpen">
      <QCard>
        <QCardSection>
          <div class="text-h6">Выполнить ревизию</div>
        </QCardSection>
        <QCardSection>
          <div class="text-body1">
            Функция выполнения ревизии будет реализована позже. 
            Она будет включать загрузку данных из Excel и выполнение проверок.
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat label="Закрыть" color="primary" @click="executeDialogOpen = false" />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QCheckbox,
  QDialog,
  QForm,
  QIcon,
  QInput,
  QItem,
  QItemLabel,
  QItemSection,
  QList,
  QPage,
  QSelect,
  QSeparator,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs
} from 'quasar';
import { useQuasar, Notify } from 'quasar';

import { useAuditsStore } from '@/stores/audits';
import { useAuditTypesStore } from '@/stores/lookups/audit-types';
import { useDirectoriesStore } from '@/stores/lookups/directories';
import type { RaADto, RaACreateRequest, RaAUpdateRequest, RaDirDto } from '@/types/audits';
import * as directoriesApi from '@/api/directories-api';
import DirectoryInfo from '@/components/audits/DirectoryInfo.vue';

const $q = useQuasar();
const auditsStore = useAuditsStore();
const auditTypesStore = useAuditTypesStore();
const directoriesStore = useDirectoriesStore();

const selectedAuditId = ref<number | null>(null);
const isNewAudit = ref(false);
const saving = ref(false);
const errorMessage = ref<string | null>(null);
const activeTab = ref<'progress' | 'files'>('progress');
const executeDialogOpen = ref(false);

// Состояние для директории
const currentDirectory = ref<RaDirDto | null>(null);
const loadingDirectory = ref(false);

// Форма ревизии
const form = ref<{
  adtName: string;
  adtType: number | null;
  adtDir: number | null;
  adtDateDate: string;
  adtDateTime: string;
  adtAddRA: boolean;
}>({
  adtName: '',
  adtType: null,
  adtDir: null,
  adtDateDate: '',
  adtDateTime: '',
  adtAddRA: false
});

const errors = ref<{
  adtName?: string;
  adtType?: string;
  adtDir?: string;
  adtDate?: string;
}>({});

// Отсортированные ревизии (по дате, новые сверху)
const sortedAudits = computed(() => {
  return [...auditsStore.audits].sort((a, b) => {
    if (!a.adtDate) return 1;
    if (!b.adtDate) return -1;
    return new Date(b.adtDate).getTime() - new Date(a.adtDate).getTime();
  });
});

// Computed selectedAudit для реактивности
const selectedAudit = computed(() => {
  if (!selectedAuditId.value) return null;
  return auditsStore.audits.find((a) => a.adtKey === selectedAuditId.value) || null;
});

// Опции для выпадающих списков
const auditTypesOptions = computed(() => auditTypesStore.auditTypes);
const directoriesOptions = computed(() => directoriesStore.directories);

// Валидация формы (время опционально)
const isFormValid = computed(() => {
  return !!(
    form.value.adtName.trim() &&
    form.value.adtType !== null &&
    form.value.adtDir !== null &&
    form.value.adtDateDate
  );
});

// Загрузка данных при монтировании
onMounted(async () => {
  await Promise.all([
    auditsStore.fetchAudits(),
    auditTypesStore.fetchAuditTypes(),
    directoriesStore.fetchDirectories()
  ]);

  // Auto-select first audit if available
  if (auditsStore.audits.length > 0 && !selectedAuditId.value) {
    selectedAuditId.value = sortedAudits.value[0]?.adtKey || null;
  }
});

// Watch для автоматической загрузки формы при изменении выбранной ревизии
watch(selectedAuditId, async (newId) => {
  if (!newId || isNewAudit.value) {
    currentDirectory.value = null;
    return;
  }

  errorMessage.value = null;

  try {
    // Загружаем полные данные ревизии через API
    const audit = await auditsStore.fetchAuditById(newId);
    if (audit) {
      loadAuditToForm(audit);
      // Загружаем директорию для ревизии
      await loadDirectory(newId);
    } else {
      errorMessage.value = 'Ревизия не найдена';
      currentDirectory.value = null;
    }
  } catch (err) {
    errorMessage.value = err instanceof Error ? err.message : 'Не удалось загрузить ревизию';
    currentDirectory.value = null;
  }
});

// ============================================================================
// Обработка выбора и навигации
// ============================================================================

// Обработка выбора ревизии
function handleSelectAudit(id: number): void {
  if (selectedAuditId.value === id) {
    return;
  }

  isNewAudit.value = false;
  selectedAuditId.value = id;
  errorMessage.value = null;
  activeTab.value = 'progress';
}

// ============================================================================
// Работа с формой
// ============================================================================

// Очистка формы
function resetForm(): void {
  form.value = {
    adtName: '',
    adtType: null,
    adtDir: null,
    adtDateDate: '',
    adtDateTime: '',
    adtAddRA: false
  };
  errors.value = {};
  errorMessage.value = null;
}

// Загрузка данных ревизии в форму
function loadAuditToForm(audit: RaADto): void {
  form.value.adtName = audit.adtName || '';
  form.value.adtType = audit.adtType || null;
  form.value.adtDir = audit.adtDir || null;
  form.value.adtAddRA = audit.adtAddRA || false;

  if (audit.adtDate) {
    const date = new Date(audit.adtDate);
    form.value.adtDateDate = date.toISOString().slice(0, 10);
    // Формат времени для input type="time": HH:mm (без секунд)
    form.value.adtDateTime = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  } else {
    form.value.adtDateDate = '';
    form.value.adtDateTime = '';
  }
}

// Создание новой ревизии
function handleCreateNew(): void {
  isNewAudit.value = true;
  selectedAuditId.value = null;
  activeTab.value = 'progress';

  // Очистка формы
  resetForm();

  // Установка текущей даты и времени по умолчанию
  const now = new Date();
  form.value.adtDateDate = now.toISOString().slice(0, 10);
  form.value.adtDateTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
}

// Обновление списка ревизий
async function handleRefresh(): Promise<void> {
  await auditsStore.fetchAudits();
  // Watch автоматически загрузит форму при изменении selectedAuditId
}

// Загрузка директории для ревизии
async function loadDirectory(auditId: number): Promise<void> {
  loadingDirectory.value = true;
  try {
    const directory = await directoriesApi.getDirectoryByAuditId(auditId);
    currentDirectory.value = directory;
  } catch (err) {
    // Если директория не найдена, это не критическая ошибка
    currentDirectory.value = null;
    console.warn('Директория для ревизии не найдена:', err);
  } finally {
    loadingDirectory.value = false;
  }
}

// ============================================================================
// Валидация и сохранение
// ============================================================================

// Валидация формы перед сохранением
function validateForm(): boolean {
  errors.value = {};

  if (!form.value.adtName.trim()) {
    errors.value.adtName = 'Введите название ревизии';
  }

  if (form.value.adtType === null) {
    errors.value.adtType = 'Выберите тип ревизии из списка';
  }

  if (form.value.adtDir === null) {
    errors.value.adtDir = 'Выберите директорию из списка';
  }

  if (!form.value.adtDateDate) {
    errors.value.adtDate = 'Укажите дату выполнения ревизии';
  }

  return Object.keys(errors.value).length === 0;
}

// Сохранение ревизии
async function handleSave(): Promise<void> {
  if (!validateForm()) {
    return;
  }

  saving.value = true;
  errorMessage.value = null;

  try {
    // Формирование даты и времени в локальном формате (без конвертации в UTC)
    // Формат: "YYYY-MM-DDTHH:mm:ss" (без 'Z') для работы с LocalDateTime на backend
    // Время опционально: если не указано, используется 00:00:00
    const timeStr = form.value.adtDateTime || '00:00:00';
    const dateTimeStr = `${form.value.adtDateDate}T${timeStr}`;
    // Добавляем секунды, если их нет
    const adtDate = dateTimeStr.includes(':') && dateTimeStr.split(':').length === 2 
      ? `${dateTimeStr}:00` 
      : dateTimeStr;

    if (isNewAudit.value) {
      // Создание новой ревизии
      const createRequest: RaACreateRequest = {
        adtName: form.value.adtName.trim(),
        adtType: form.value.adtType!,
        adtDir: form.value.adtDir!,
        adtDate: adtDate,
        adtAddRA: form.value.adtAddRA
      };

      const created = await auditsStore.createAudit(createRequest);
      if (created) {
        // Обновляем список ревизий и устанавливаем выбранную
        await auditsStore.fetchAudits();
        selectedAuditId.value = created.adtKey;
        isNewAudit.value = false;
        Notify.create({
          type: 'positive',
          message: 'Ревизия успешно создана',
          position: 'top'
        });
      }
    } else if (selectedAudit.value) {
      // Обновление существующей ревизии
      const updateRequest: RaAUpdateRequest = {
        adtName: form.value.adtName.trim(),
        adtType: form.value.adtType!,
        adtDir: form.value.adtDir!,
        adtDate: adtDate,
        adtAddRA: form.value.adtAddRA
      };

      const updated = await auditsStore.updateAudit(selectedAudit.value.adtKey, updateRequest);
      if (updated) {
        // Обновляем список ревизий, watch автоматически загрузит форму
        await auditsStore.fetchAudits();
        Notify.create({
          type: 'positive',
          message: 'Ревизия успешно обновлена',
          position: 'top'
        });
      }
    }
  } catch (err) {
    errorMessage.value = err instanceof Error ? err.message : 'Не удалось сохранить ревизию';
    Notify.create({
      type: 'negative',
      message: errorMessage.value,
      position: 'top'
    });
  } finally {
    saving.value = false;
  }
}

// ============================================================================
// Дополнительные действия
// ============================================================================

// Выполнение ревизии (заглушка)
function handleExecuteAudit(): void {
  executeDialogOpen.value = true;
}

// ============================================================================
// Утилиты
// ============================================================================

// Форматирование даты
function formatDate(dateString: string | null | undefined): string {
  if (!dateString) {
    return '';
  }
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch {
    return '';
  }
}
</script>

<style scoped>
.audits-view {
  height: 100%;
}

.audits-list-card,
.audit-form-card {
  display: flex;
  flex-direction: column;
}

.full-height {
  height: 100%;
}

.audit-list-item {
  cursor: pointer;
  transition: background-color 0.2s;
}

.audit-list-item:hover {
  background-color: rgba(0, 0, 0, 0.03);
}

.audit-list-item.q-item--active {
  background-color: rgba(25, 118, 210, 0.1);
}

/* Левая панель: ширина в 2.5 раза меньше чем было (col-md-4 = 33.33% -> 13.33%) */
.audits-list-panel {
  flex: 0 0 100%;
  max-width: 100%;
}

@media (min-width: 768px) {
  .audits-list-panel {
    flex: 0 0 13.33%;
    max-width: 13.33%;
  }
  
  .audit-form-panel {
    flex: 0 0 86.67%;
    max-width: 86.67%;
  }
}

/* Компактная форма: уменьшаем вертикальные отступы в 4 раза */
.compact-form-section {
  padding-top: 8px !important;
  padding-bottom: 8px !important;
}

.compact-title {
  margin-bottom: 4px !important; /* было q-mb-md (16px) -> 4px */
}

.compact-banner {
  margin-bottom: 4px !important; /* было q-mb-md (16px) -> 4px */
}

/* q-gutter-md использует gap или margin, переопределяем на 4px (было 16px) */
.compact-form {
  gap: 4px !important; /* было 16px в q-gutter-md */
}

.compact-form > * {
  margin-bottom: 4px !important;
}

.compact-form > *:last-child {
  margin-bottom: 0 !important;
}

/* Уменьшаем отступы внутри row для даты/времени */
.compact-form .row {
  margin-bottom: 4px !important;
}

.compact-buttons {
  margin-top: 4px !important; /* было q-mt-md (16px) -> 4px */
}
</style>
