<template>
  <QPage class="audits-view q-pa-md">
    <div class="row q-col-gutter-md" style="height: calc(100vh - 150px);">
      <!-- Левая панель: список ревизий -->
      <div class="col-12 col-md-3 audits-list-panel">
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
      <div class="col-12 col-md-9 audit-form-panel">
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
                <!-- ✅ ИНТЕГРАЦИЯ: Новый компонент файлов для проверки -->
                <AuditFilesTab v-if="selectedAudit" :audit-id="selectedAudit.adtKey" />
                <div v-else class="q-pa-md text-center text-grey-7">
                  Выберите ревизию для просмотра файлов
                </div>
              </QTabPanel>
            </QTabPanels>
          </QCardSection>

          <!-- Сообщение, когда ревизия не выбрана -->
          <QCardSection v-if="!selectedAudit && !isNewAudit" class="text-center text-grey-7 q-pa-xl">
            <div class="text-h6 q-mb-md">Выберите ревизию или создайте новую</div>
            <div class="text-body2">
              Используйте список слева для выбора существующей ревизии или нажмите "Создать новую".
            </div>
          </QCardSection>
        </QCard>
      </div>
    </div>
  </QPage>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useAuditsStore } from '@/stores/audits';
import { useAuditTypesStore } from '@/stores/lookups/audit-types';
import { useDirectoriesStore } from '@/stores/directories';
import type { RaAudit, RaAuditCreateRequest, RaAuditUpdateRequest } from '@/types/audits';
import AuditFilesTab from '@/components/audits/AuditFilesTab.vue';

// Stores
const auditsStore = useAuditsStore();
const auditTypesStore = useAuditTypesStore();
const directoriesStore = useDirectoriesStore();

// State
const selectedAuditId = ref<number | null>(null);
const isNewAudit = ref(false);
const activeTab = ref('progress');
const saving = ref(false);
const errorMessage = ref('');

// Form data
const form = ref({
  adtName: '',
  adtType: null as number | null,
  adtDir: null as number | null,
  adtDateDate: '',
  adtDateTime: '',
  adtAddRA: false,
});

// Form errors
const errors = ref({
  adtName: '',
  adtType: '',
  adtDir: '',
  adtDate: '',
});

// Computed
const sortedAudits = computed(() => {
  return [...auditsStore.audits].sort((a, b) => {
    if (!a.adtDate) return 1;
    if (!b.adtDate) return -1;
    return new Date(b.adtDate).getTime() - new Date(a.adtDate).getTime();
  });
});

const selectedAudit = computed(() => {
  if (!selectedAuditId.value) return null;
  return auditsStore.audits.find((a) => a.adtKey === selectedAuditId.value) || null;
});

const auditTypesOptions = computed(() => auditTypesStore.auditTypes);
const directoriesOptions = computed(() => directoriesStore.directories);

const isFormValid = computed(() => {
  return (
    form.value.adtName.trim() !== '' &&
    form.value.adtType !== null &&
    form.value.adtDir !== null &&
    form.value.adtDateDate !== ''
  );
});

// Methods
function formatDate(dateString: string | null): string {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  } catch {
    return '';
  }
}

function resetForm() {
  form.value = {
    adtName: '',
    adtType: null,
    adtDir: null,
    adtDateDate: '',
    adtDateTime: '',
    adtAddRA: false,
  };
  errors.value = {
    adtName: '',
    adtType: '',
    adtDir: '',
    adtDate: '',
  };
  errorMessage.value = '';
}

function loadFormFromAudit(audit: RaAudit) {
  form.value.adtName = audit.adtName || '';
  form.value.adtType = audit.adtType;
  form.value.adtDir = audit.adtDir;
  form.value.adtAddRA = audit.adtAddRA || false;

  if (audit.adtDate) {
    const date = new Date(audit.adtDate);
    form.value.adtDateDate = date.toISOString().split('T')[0];
    form.value.adtDateTime = date.toTimeString().split(' ')[0].substring(0, 5);
  } else {
    form.value.adtDateDate = '';
    form.value.adtDateTime = '';
  }
}

function validateForm(): boolean {
  errors.value = {
    adtName: '',
    adtType: '',
    adtDir: '',
    adtDate: '',
  };

  let valid = true;

  if (!form.value.adtName.trim()) {
    errors.value.adtName = 'Введите имя ревизии';
    valid = false;
  }

  if (form.value.adtType === null) {
    errors.value.adtType = 'Выберите тип ревизии';
    valid = false;
  }

  if (form.value.adtDir === null) {
    errors.value.adtDir = 'Выберите директорию';
    valid = false;
  }

  if (!form.value.adtDateDate) {
    errors.value.adtDate = 'Введите дату';
    valid = false;
  }

  return valid;
}

async function handleSave() {
  if (!validateForm()) {
    return;
  }

  saving.value = true;
  errorMessage.value = '';

  try {
    // Combine date and time
    let adtDate = form.value.adtDateDate;
    if (form.value.adtDateTime) {
      adtDate += 'T' + form.value.adtDateTime;
    } else {
      adtDate += 'T00:00:00';
    }

    if (isNewAudit.value) {
      // Create new audit
      const createRequest: RaAuditCreateRequest = {
        adtName: form.value.adtName,
        adtType: form.value.adtType!,
        adtDir: form.value.adtDir!,
        adtDate,
        adtAddRA: form.value.adtAddRA,
      };

      const newAudit = await auditsStore.createAudit(createRequest);
      selectedAuditId.value = newAudit.adtKey;
      isNewAudit.value = false;
    } else if (selectedAudit.value) {
      // Update existing audit
      const updateRequest: RaAuditUpdateRequest = {
        adtName: form.value.adtName,
        adtType: form.value.adtType!,
        adtDir: form.value.adtDir!,
        adtDate,
        adtAddRA: form.value.adtAddRA,
      };

      await auditsStore.updateAudit(selectedAudit.value.adtKey, updateRequest);
    }
  } catch (error: any) {
    errorMessage.value = error.message || 'Ошибка при сохранении ревизии';
  } finally {
    saving.value = false;
  }
}

function handleSelectAudit(auditId: number) {
  selectedAuditId.value = auditId;
  isNewAudit.value = false;
  activeTab.value = 'progress';
}

function handleCreateNew() {
  isNewAudit.value = true;
  selectedAuditId.value = null;
  resetForm();
  activeTab.value = 'progress';
}

async function handleRefresh() {
  await auditsStore.fetchAudits();
}

function handleExecuteAudit() {
  // TODO: Implement audit execution
  alert('Функция "Выполнить ревизию" будет реализована в следующих этапах');
}

// Watchers
watch(selectedAudit, (newAudit) => {
  if (newAudit && !isNewAudit.value) {
    loadFormFromAudit(newAudit);
  }
});

// Lifecycle
onMounted(async () => {
  await Promise.all([
    auditsStore.fetchAudits(),
    auditTypesStore.fetchAuditTypes(),
    directoriesStore.loadAll(),
  ]);

  // Auto-select first audit if available
  if (auditsStore.audits.length > 0 && !selectedAuditId.value) {
    selectedAuditId.value = sortedAudits.value[0]?.adtKey || null;
  }
});
</script>

<style scoped>
.audits-view {
  max-width: 1800px;
  margin: 0 auto;
}

/* Quasar Grid классы управляют шириной:
   - Мобильные (col-12): обе панели на всю ширину (100%)
   - Десктопы (col-md-2 / col-md-10): панели 16.67% и 83.33%
*/

.audits-list-card,
.audit-form-card {
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.audits-list-card .q-card__section:nth-child(3) {
  flex: 1;
  overflow-y: auto;
}

.audit-list-item {
  transition: background-color 0.2s;
}

.audit-list-item:hover {
  background-color: rgba(0, 0, 0, 0.04);
}

.audit-form-card {
  overflow-y: auto;
}

.compact-form-section {
  padding: 12px !important;
}

.compact-title {
  margin-bottom: 8px;
  font-size: 1.1rem;
}

.compact-banner {
  margin-bottom: 8px;
  padding: 8px 12px;
}

.compact-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.compact-buttons {
  margin-top: 4px;
}

.text-h6 {
  font-size: 1.25rem;
  font-weight: 500;
  line-height: 1.6;
}

.text-body2 {
  font-size: 0.875rem;
  font-weight: 400;
  line-height: 1.43;
  letter-spacing: 0.01071em;
}
</style>
