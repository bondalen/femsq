<template>
  <div v-if="open" class="report-parameters-dialog" @click.self="handleClose">
    <div class="report-parameters-dialog__content">
      <header class="report-parameters-dialog__header">
        <h2>{{ reportName }}</h2>
        <button
          type="button"
          class="report-parameters-dialog__close"
          @click="handleClose"
        >
          ×
        </button>
      </header>

      <div v-if="loading" class="report-parameters-dialog__loading">
        Загрузка параметров…
      </div>

      <div v-else-if="error" class="report-parameters-dialog__error">
        {{ error }}
      </div>

      <div v-else class="report-parameters-dialog__body">
        <p v-if="reportDescription" class="report-parameters-dialog__description">
          {{ reportDescription }}
        </p>

        <form v-if="parameters.length > 0" @submit.prevent="handleGenerate('pdf')">
          <div
            v-for="param in parameters"
            :key="param.name"
            class="report-parameters-dialog__field"
          >
            <label :for="`param-${param.name}`">
              {{ param.label }}
              <span v-if="param.required" class="report-parameters-dialog__required">*</span>
            </label>

            <input
              v-if="param.type === 'string' && !param.options"
              :id="`param-${param.name}`"
              type="text"
              v-model="formValues[param.name]"
              :required="param.required"
              :placeholder="param.description"
            />

            <input
              v-else-if="param.type === 'integer' || param.type === 'long'"
              :id="`param-${param.name}`"
              type="number"
              v-model.number="formValues[param.name]"
              :required="param.required"
              :min="param.validation?.min"
              :max="param.validation?.max"
              :placeholder="param.description"
            />

            <input
              v-else-if="param.type === 'double'"
              :id="`param-${param.name}`"
              type="number"
              step="0.01"
              v-model.number="formValues[param.name]"
              :required="param.required"
              :min="param.validation?.min"
              :max="param.validation?.max"
              :placeholder="param.description"
            />

            <input
              v-else-if="param.type === 'date'"
              :id="`param-${param.name}`"
              type="date"
              v-model="formValues[param.name]"
              :required="param.required"
              :min="param.validation?.minDate"
              :max="param.validation?.maxDate"
            />

            <input
              v-else-if="param.type === 'boolean'"
              :id="`param-${param.name}`"
              type="checkbox"
              v-model="formValues[param.name]"
            />

            <select
              v-else-if="param.type === 'enum' || param.options"
              :id="`param-${param.name}`"
              v-model="formValues[param.name]"
              :required="param.required"
            >
              <option value="">{{ param.required ? 'Выберите...' : 'Не выбрано' }}</option>
              <option
                v-for="option in getOptions(param)"
                :key="String(option.value)"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>

            <p v-if="param.description" class="report-parameters-dialog__field-hint">
              {{ param.description }}
            </p>
          </div>
        </form>

        <div v-else class="report-parameters-dialog__no-params">
          <p>Этот отчёт не требует параметров.</p>
        </div>
      </div>

      <footer class="report-parameters-dialog__footer">
        <button
          type="button"
          class="report-parameters-dialog__button report-parameters-dialog__button--secondary"
          @click="handleClose"
        >
          Отмена
        </button>
        <button
          v-if="parameters.length > 0"
          type="button"
          class="report-parameters-dialog__button report-parameters-dialog__button--secondary"
          @click="handlePreview"
          :disabled="!isFormValid"
        >
          Предпросмотр
        </button>
        <div class="report-parameters-dialog__format-group">
          <label>Формат:</label>
          <select v-model="selectedFormat">
            <option value="pdf">PDF</option>
            <option value="excel">Excel</option>
            <option value="html">HTML</option>
          </select>
        </div>
        <button
          type="button"
          class="report-parameters-dialog__button report-parameters-dialog__button--primary"
          @click="handleGenerateClick"
          :disabled="!isFormValid || generating"
        >
          {{ generating ? 'Генерация…' : 'Сгенерировать' }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useReportsStore } from '@/stores/reports';
import { getParameterSource } from '@/api/reports-api';
import type { ReportParameter, ParameterOption } from '@/types/reports';

interface Props {
  reportId: string;
  open: boolean;
  context?: Record<string, string>;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  (event: 'close'): void;
  (event: 'generate', format: 'pdf' | 'excel' | 'html', parameters: Record<string, unknown>): void;
  (event: 'preview', parameters: Record<string, unknown>): void;
}>();

const reportsStore = useReportsStore();

const loading = ref(false);
const error = ref('');
const parameters = ref<ReportParameter[]>([]);
const reportName = ref('');
const reportDescription = ref('');
const formValues = reactive<Record<string, unknown>>({});
const selectedFormat = ref<'pdf' | 'excel' | 'html'>('pdf');
const generating = ref(false);
const parameterOptions = reactive<Record<string, ParameterOption[]>>({});

const isFormValid = computed(() => {
  return parameters.value.every(param => {
    if (!param.required) {
      return true;
    }
    const value = formValues[param.name];
    if (value === undefined || value === null || value === '') {
      return false;
    }
    return true;
  });
});

watch(() => props.open, async (newValue) => {
  if (newValue) {
    await loadParameters();
  } else {
    // Сброс формы при закрытии
    Object.keys(formValues).forEach(key => {
      delete formValues[key];
    });
  }
});

async function loadParameters(): Promise<void> {
  loading.value = true;
  error.value = '';

  try {
    // Загружаем метаданные для получения имени и описания
    const metadata = await reportsStore.loadMetadata(props.reportId);
    if (metadata) {
      reportName.value = metadata.name;
      reportDescription.value = metadata.description || '';
    }

    // Загружаем параметры с разрешением defaults
    const params = await reportsStore.loadParameters(props.reportId, props.context);
    parameters.value = params;

    // Инициализируем значения формы с defaults
    params.forEach(param => {
      if (param.defaultValue) {
        const resolved = resolveDefaultValue(param.defaultValue);
        formValues[param.name] = convertValue(resolved, param.type);
      } else if (!param.required) {
        // Для необязательных параметров устанавливаем пустое значение
        formValues[param.name] = getDefaultValueForType(param.type);
      }

      // Загружаем опции для параметров с source.type="api"
      if (param.source?.type === 'api') {
        loadParameterOptions(param);
      }
    });
  } catch (err) {
    error.value = 'Не удалось загрузить параметры отчёта';
    console.error('Failed to load parameters:', err);
  } finally {
    loading.value = false;
  }
}

async function loadParameterOptions(param: ReportParameter): Promise<void> {
  try {
    const options = await getParameterSource(props.reportId, param.name);
    parameterOptions[param.name] = options;
  } catch (err) {
    console.error(`Failed to load options for parameter ${param.name}:`, err);
    // Используем статические опции, если они есть
    if (param.options) {
      parameterOptions[param.name] = param.options;
    }
  }
}

function getOptions(param: ReportParameter): ParameterOption[] {
  // Приоритет: загруженные из API > статические опции
  if (parameterOptions[param.name] && parameterOptions[param.name].length > 0) {
    return parameterOptions[param.name];
  }
  if (param.options) {
    return param.options;
  }
  return [];
}

function resolveDefaultValue(defaultValue: string): string {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  const todayStr = `${year}-${month}-${day}`;

  // Вычисляем первый день квартала
  const quarter = Math.floor(today.getMonth() / 3);
  const firstDayOfQuarter = new Date(year, quarter * 3, 1);
  const firstDayOfQuarterStr = firstDayOfQuarter.toISOString().slice(0, 10);

  // Вычисляем последний день квартала
  const lastDayOfQuarter = new Date(year, (quarter + 1) * 3, 0);
  const lastDayOfQuarterStr = lastDayOfQuarter.toISOString().slice(0, 10);

  // Вычисляем первый день месяца
  const firstDayOfMonth = `${year}-${month}-01`;

  // Вычисляем последний день месяца
  const lastDayOfMonth = new Date(year, today.getMonth() + 1, 0).toISOString().slice(0, 10);

  // Вычисляем первый день года
  const firstDayOfYear = `${year}-01-01`;

  // Вычисляем последний день года
  const lastDayOfYear = `${year}-12-31`;

  // Вычисляем вчера
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);

  return defaultValue
    .replace(/\$\{today\}/g, todayStr)
    .replace(/\$\{yesterday\}/g, yesterdayStr)
    .replace(/\$\{firstDayOfMonth\}/g, firstDayOfMonth)
    .replace(/\$\{lastDayOfMonth\}/g, lastDayOfMonth)
    .replace(/\$\{firstDayOfQuarter\}/g, firstDayOfQuarterStr)
    .replace(/\$\{lastDayOfQuarter\}/g, lastDayOfQuarterStr)
    .replace(/\$\{firstDayOfYear\}/g, firstDayOfYear)
    .replace(/\$\{lastDayOfYear\}/g, lastDayOfYear)
    .replace(/\$\{([^}]+)\}/g, (match, key) => {
      // Пытаемся разрешить из контекста
      if (props.context && props.context[key]) {
        return props.context[key];
      }
      return match; // Оставляем как есть, если не найдено
    });
}

function convertValue(value: string, type: string): unknown {
  if (!value) {
    return getDefaultValueForType(type);
  }

  switch (type) {
    case 'integer':
    case 'long':
      return parseInt(value, 10);
    case 'double':
      return parseFloat(value);
    case 'boolean':
      return value === 'true' || value === '1';
    case 'date':
      return value;
    default:
      return value;
  }
}

function getDefaultValueForType(type: string): unknown {
  switch (type) {
    case 'integer':
    case 'long':
    case 'double':
      return 0;
    case 'boolean':
      return false;
    case 'date':
      return '';
    default:
      return '';
  }
}

function handleClose(): void {
  emit('close');
}

function handleGenerateClick(): void {
  handleGenerate(selectedFormat.value);
}

function handleGenerate(format: 'pdf' | 'excel' | 'html'): void {
  if (!isFormValid.value) {
    return;
  }

  generating.value = true;
  const params: Record<string, unknown> = {};

  // Копируем только заполненные значения
  parameters.value.forEach(param => {
    const value = formValues[param.name];
    if (value !== undefined && value !== null && value !== '') {
      params[param.name] = value;
    }
  });

  emit('generate', format, params);
  generating.value = false;
}

function handlePreview(): void {
  if (!isFormValid.value) {
    return;
  }

  const params: Record<string, unknown> = {};

  parameters.value.forEach(param => {
    const value = formValues[param.name];
    if (value !== undefined && value !== null && value !== '') {
      params[param.name] = value;
    }
  });

  emit('preview', params);
}

onMounted(() => {
  if (props.open) {
    loadParameters();
  }
});
</script>

<style scoped>
.report-parameters-dialog {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(28, 35, 51, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.report-parameters-dialog__content {
  background: white;
  border-radius: 20px;
  box-shadow: 0 24px 48px rgba(28, 35, 51, 0.2);
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.report-parameters-dialog__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  border-bottom: 1px solid rgba(28, 35, 51, 0.08);
}

.report-parameters-dialog__header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
}

.report-parameters-dialog__close {
  background: none;
  border: none;
  font-size: 32px;
  line-height: 1;
  color: rgba(28, 35, 51, 0.6);
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  transition: all 0.15s ease;
}

.report-parameters-dialog__close:hover {
  background: rgba(28, 35, 51, 0.08);
  color: rgba(28, 35, 51, 0.8);
}

.report-parameters-dialog__body {
  padding: 24px;
  overflow-y: auto;
  flex: 1;
}

.report-parameters-dialog__description {
  margin: 0 0 20px;
  color: rgba(28, 35, 51, 0.72);
  font-size: 14px;
  line-height: 1.5;
}

.report-parameters-dialog__field {
  margin-bottom: 20px;
}

.report-parameters-dialog__field label {
  display: block;
  margin-bottom: 6px;
  font-size: 14px;
  font-weight: 600;
  color: rgba(28, 35, 51, 0.8);
}

.report-parameters-dialog__required {
  color: #ef4444;
}

.report-parameters-dialog__field input[type='text'],
.report-parameters-dialog__field input[type='number'],
.report-parameters-dialog__field input[type='date'],
.report-parameters-dialog__field select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  border-radius: 8px;
  font-size: 14px;
  background: white;
  transition: border-color 0.15s ease;
}

.report-parameters-dialog__field input:focus,
.report-parameters-dialog__field select:focus {
  outline: none;
  border-color: rgba(47, 122, 206, 0.5);
}

.report-parameters-dialog__field input[type='checkbox'] {
  width: auto;
  margin-right: 8px;
}

.report-parameters-dialog__field-hint {
  margin: 4px 0 0;
  font-size: 12px;
  color: rgba(28, 35, 51, 0.56);
}

.report-parameters-dialog__loading,
.report-parameters-dialog__error,
.report-parameters-dialog__no-params {
  padding: 24px;
  text-align: center;
  color: rgba(28, 35, 51, 0.6);
}

.report-parameters-dialog__error {
  color: #ef4444;
}

.report-parameters-dialog__footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 24px;
  border-top: 1px solid rgba(28, 35, 51, 0.08);
}

.report-parameters-dialog__button {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  border: 1px solid transparent;
}

.report-parameters-dialog__button--secondary {
  background: white;
  border-color: rgba(28, 35, 51, 0.12);
  color: rgba(28, 35, 51, 0.8);
}

.report-parameters-dialog__button--secondary:hover:not(:disabled) {
  background: rgba(28, 35, 51, 0.04);
}

.report-parameters-dialog__button--primary {
  background: #2f7ace;
  color: white;
  border-color: #2f7ace;
}

.report-parameters-dialog__button--primary:hover:not(:disabled) {
  background: #2563eb;
  border-color: #2563eb;
}

.report-parameters-dialog__button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.report-parameters-dialog__format-group {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;
}

.report-parameters-dialog__format-group label {
  font-size: 14px;
  font-weight: 500;
  color: rgba(28, 35, 51, 0.72);
}

.report-parameters-dialog__format-group select {
  padding: 8px 12px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  border-radius: 8px;
  font-size: 14px;
  background: white;
}

@media (max-width: 640px) {
  .report-parameters-dialog {
    padding: 0;
  }

  .report-parameters-dialog__content {
    border-radius: 0;
    max-height: 100vh;
  }

  .report-parameters-dialog__footer {
    flex-wrap: wrap;
  }

  .report-parameters-dialog__format-group {
    width: 100%;
    margin-left: 0;
  }
}
</style>
