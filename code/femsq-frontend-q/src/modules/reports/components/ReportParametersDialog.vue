<template>
  <QDialog :model-value="open" persistent @update:model-value="handleDialogToggle">
    <QCard class="dialog-card">
      <QCardSection class="row items-start justify-between q-gutter-sm">
        <div>
          <div class="text-h6">{{ reportName }}</div>
          <div v-if="reportDescription" class="text-body2 text-grey-7">
            {{ reportDescription }}
          </div>
        </div>
        <QBtn icon="close" flat round dense @click="handleClose" />
      </QCardSection>

      <QSeparator />

      <QCardSection class="q-pa-none">
        <div v-if="loading" class="column items-center q-pa-lg text-grey-6">
          <QSpinner color="primary" size="32px" />
          <div class="q-mt-sm">Загрузка параметров…</div>
        </div>

        <QBanner
          v-else-if="error"
          class="bg-red-1 text-negative q-ma-md"
          dense
          rounded
        >
          {{ error }}
        </QBanner>

        <div v-else class="q-pa-md" style="max-height: 55vh; overflow-y: auto;">
          <div v-if="parameters.length === 0" class="text-body1 text-grey-7">
            Этот отчёт не требует параметров.
          </div>

          <QForm v-else class="q-gutter-md">
            <div v-for="param in parameters" :key="param.name" class="column q-gutter-xs">
              <div class="text-caption text-weight-medium text-grey-7">
                {{ param.label }}
                <span v-if="param.required" class="text-negative">*</span>
              </div>

              <QInput
                v-if="param.type === 'string' && !param.options"
                v-model="formValues[param.name]"
                :label="param.description || 'Текст'"
                dense
                outlined
              />

              <QInput
                v-else-if="param.type === 'integer' || param.type === 'long'"
                v-model.number="formValues[param.name]"
                type="number"
                dense
                outlined
                :label="param.description || 'Число'"
                :min="param.validation?.min"
                :max="param.validation?.max"
              />

              <QInput
                v-else-if="param.type === 'double'"
                v-model.number="formValues[param.name]"
                type="number"
                step="0.01"
                dense
                outlined
                :label="param.description || 'Дробное число'"
                :min="param.validation?.min"
                :max="param.validation?.max"
              />

              <QInput
                v-else-if="param.type === 'date'"
                v-model="formValues[param.name]"
                type="date"
                dense
                outlined
                :label="param.description || 'Дата'"
                :min="param.validation?.minDate"
                :max="param.validation?.maxDate"
              />

              <div v-else-if="param.type === 'boolean'" class="q-ml-xs">
                <QCheckbox v-model="formValues[param.name]" :label="param.description || 'Да/Нет'" />
              </div>

              <QSelect
                v-else
                v-model="formValues[param.name]"
                dense
                outlined
                :options="getOptions(param)"
                :label="param.description || 'Выбор'"
                emit-value
                map-options
                use-input
                fill-input
                clearable
              />
            </div>
          </QForm>
        </div>
      </QCardSection>

      <QSeparator />

      <QCardActions align="right" class="q-gutter-sm">
        <QBtn flat color="primary" label="Отмена" @click="handleClose" />
        <QBtn
          v-if="parameters.length > 0"
          flat
          color="primary"
          label="Предпросмотр"
          :disable="!isFormValid"
          @click="handlePreviewClick"
        />
        <QSelect
          v-model="selectedFormat"
          :options="formatOptions"
          emit-value
          map-options
          dense
          outlined
          style="width: 140px;"
        />
        <QBtn
          unelevated
          color="primary"
          :label="generating ? 'Генерация…' : 'Сгенерировать'"
          :loading="generating"
          :disable="!isFormValid"
          @click="handleGenerateClick"
        />
      </QCardActions>
    </QCard>
  </QDialog>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QCheckbox,
  QDialog,
  QForm,
  QInput,
  QSelect,
  QSeparator,
  QSpinner
} from 'quasar';

import { useReportsStore } from '@/stores/reports';
import type { ParameterOption, ReportParameter } from '@/types/reports';

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
const reportName = ref('Параметры отчёта');
const reportDescription = ref('');
const formValues = reactive<Record<string, unknown>>({});
const selectedFormat = ref<'pdf' | 'excel' | 'html'>('pdf');
const generating = ref(false);
const parameterOptions = reactive<Record<string, ParameterOption[]>>({});

const formatOptions = [
  { label: 'PDF', value: 'pdf' },
  { label: 'Excel', value: 'excel' },
  { label: 'HTML', value: 'html' }
];

const isFormValid = computed(() =>
  parameters.value.every((param) => {
    if (!param.required) {
      return true;
    }
    const value = formValues[param.name];
    return value !== undefined && value !== null && value !== '';
  })
);

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) {
      void loadParameters();
    } else {
      resetForm();
    }
  }
);

async function loadParameters(): Promise<void> {
  loading.value = true;
  error.value = '';

  try {
    const metadata = await reportsStore.loadMetadata(props.reportId);
    if (metadata) {
      reportName.value = metadata.name;
      reportDescription.value = metadata.description || '';
    }

    const params = await reportsStore.loadParameters(props.reportId, props.context);
    parameters.value = params;

    params.forEach((param) => {
      if (param.defaultValue) {
        const resolved = resolveDefaultValue(param.defaultValue);
        formValues[param.name] = convertValue(resolved, param.type);
      } else if (!param.required) {
        formValues[param.name] = getDefaultValueForType(param.type);
      } else {
        formValues[param.name] = param.type === 'boolean' ? false : '';
      }

      if (param.source?.type === 'api') {
        void loadParameterOptions(param);
      } else if (param.options) {
        parameterOptions[param.name] = param.options;
      }
    });
  } catch (err) {
    console.error('[ReportParametersDialog] Failed to load parameters:', err);
    error.value = 'Не удалось загрузить параметры отчёта';
  } finally {
    loading.value = false;
  }
}

async function loadParameterOptions(param: ReportParameter): Promise<void> {
  const options = await reportsStore.loadParameterSourceOptions(props.reportId, param.name);
  parameterOptions[param.name] = options;
}

function getOptions(param: ReportParameter): ParameterOption[] {
  if (parameterOptions[param.name]?.length) {
    return parameterOptions[param.name];
  }
  if (param.options?.length) {
    return param.options;
  }
  return [];
}

function resolveDefaultValue(defaultValue: string): string {
  const today = new Date();
  const iso = (date: Date) => date.toISOString().slice(0, 10);
  const year = today.getFullYear();
  const month = today.getMonth();

  const replacements: Record<string, string> = {
    today: iso(today),
    yesterday: iso(new Date(today.getTime() - 86_400_000)),
    firstDayOfMonth: `${year}-${String(month + 1).padStart(2, '0')}-01`,
    lastDayOfMonth: iso(new Date(year, month + 1, 0)),
    firstDayOfYear: `${year}-01-01`,
    lastDayOfYear: `${year}-12-31`
  };

  const quarter = Math.floor(month / 3);
  replacements.firstDayOfQuarter = iso(new Date(year, quarter * 3, 1));
  replacements.lastDayOfQuarter = iso(new Date(year, quarter * 3 + 3, 0));

  return defaultValue.replace(/\$\{([^}]+)\}/g, (match, key) => {
    if (replacements[key]) {
      return replacements[key];
    }
    if (props.context?.[key]) {
      return props.context[key];
    }
    return match;
  });
}

function convertValue(value: string, type: string): unknown {
  if (!value && value !== '0') {
    return getDefaultValueForType(type);
  }
  switch (type) {
    case 'integer':
    case 'long':
      return Number.parseInt(value, 10);
    case 'double':
      return Number.parseFloat(value);
    case 'boolean':
      return value === 'true' || value === '1';
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
    default:
      return '';
  }
}

function handleClose(): void {
  emit('close');
}

function handleDialogToggle(value: boolean): void {
  if (!value) {
    handleClose();
  }
}

function handleGenerateClick(): void {
  handleGenerate(selectedFormat.value);
}

function handleGenerate(format: 'pdf' | 'excel' | 'html'): void {
  if (!isFormValid.value) {
    return;
  }
  generating.value = true;
  const params = collectParameters();
  emit('generate', format, params);
  generating.value = false;
}

function handlePreviewClick(): void {
  if (!isFormValid.value) {
    return;
  }
  emit('preview', collectParameters());
}

function collectParameters(): Record<string, unknown> {
  const params: Record<string, unknown> = {};
  parameters.value.forEach((param) => {
    const value = formValues[param.name];
    // Включаем значение, если оно не undefined и не null
    // Для строк проверяем, что не пустая строка
    // Для чисел и boolean включаем всегда (даже 0 и false)
    if (value !== undefined && value !== null) {
      if (typeof value === 'string' && value === '') {
        // Пустые строки пропускаем (если параметр не обязателен)
        if (param.required) {
          params[param.name] = '';
        }
      } else {
        // Преобразуем значение к правильному типу перед отправкой
        params[param.name] = convertValueForApi(value, param.type);
      }
    }
  });
  return params;
}

function convertValueForApi(value: unknown, type: string): unknown {
  if (value === null || value === undefined || value === '') {
    return value;
  }
  
  switch (type) {
    case 'integer':
    case 'long':
      return typeof value === 'number' ? value : Number.parseInt(String(value), 10);
    case 'double':
      return typeof value === 'number' ? value : Number.parseFloat(String(value));
    case 'boolean':
      return typeof value === 'boolean' ? value : (value === 'true' || value === '1' || value === true);
    case 'date':
      return String(value);
    default:
      return String(value);
  }
}

function resetForm(): void {
  Object.keys(formValues).forEach((key) => {
    delete formValues[key];
  });
  Object.keys(parameterOptions).forEach((key) => {
    delete parameterOptions[key];
  });
  parameters.value = [];
  error.value = '';
  loading.value = false;
  selectedFormat.value = 'pdf';
}

onMounted(() => {
  if (props.open) {
    void loadParameters();
  }
});
</script>

<style scoped>
.dialog-card {
  width: min(640px, 90vw);
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}
</style>






