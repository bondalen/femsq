<template>
  <QDialog v-model="opened" persistent transition-show="jump-down" transition-hide="jump-up">
    <QCard class="connection-modal">
      <QCardSection class="row items-center justify-between">
        <div>
          <div class="text-h6">Подключение к базе данных</div>
          <div class="text-caption text-grey-7">{{ statusLabel }}</div>
        </div>
        <QBtn flat round icon="close" @click="requestClose" aria-label="Закрыть" />
      </QCardSection>

      <QSeparator />

      <QCardSection>
        <QForm @submit.prevent="handleSubmit">
          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-6">
              <QInput v-model.trim="form.host" label="Host *" :error-message="errors.host" :error="!!errors.host" />
            </div>
            <div class="col-12 col-md-6">
              <QInput v-model.trim="form.port" label="Port *" type="number" :error-message="errors.port" :error="!!errors.port" />
            </div>
            <div class="col-12 col-md-6">
              <QInput v-model.trim="form.database" label="Database *" :error-message="errors.database" :error="!!errors.database" />
            </div>
            <div class="col-12 col-md-6">
              <QInput v-model.trim="form.schema" label="Schema" />
            </div>
          </div>

          <div class="q-mt-md">
            <div class="text-subtitle2 q-mb-sm">Режим аутентификации</div>
            <QOptionGroup v-model="form.authMode" :options="authOptions" inline />
          </div>

          <div v-if="form.authMode === 'sql'" class="row q-col-gutter-md q-mt-md">
            <div class="col-12 col-md-6">
              <QInput v-model.trim="form.username" label="Username *" :error-message="errors.username" :error="!!errors.username" />
            </div>
            <div class="col-12 col-md-6">
              <QInput v-model="form.password" type="password" label="Password *" :error-message="errors.password" :error="!!errors.password" />
            </div>
          </div>

          <div v-else-if="form.authMode === 'token'" class="q-mt-md">
            <QInput v-model.trim="form.token" type="textarea" autogrow label="Token *" :error-message="errors.token" :error="!!errors.token" />
          </div>

          <QExpansionItem class="q-mt-md" icon="settings" label="Дополнительно">
            <div class="row q-col-gutter-md q-mt-sm">
              <div class="col-12 col-md-4">
                <QInput
                  v-model.trim="form.timeoutSeconds"
                  type="number"
                  label="Timeout, сек"
                  :error-message="errors.timeoutSeconds"
                  :error="!!errors.timeoutSeconds"
                />
              </div>
              <div class="col-12 col-md-8">
                <QInput v-model.trim="form.applicationName" label="Application name" />
              </div>
              <div class="col-12">
                <QToggle v-model="form.useSsl" label="Использовать SSL" />
              </div>
            </div>
          </QExpansionItem>
        </QForm>
      </QCardSection>

      <QSeparator />

      <QCardActions align="between">
        <div>
          <div class="text-body2">{{ message || "Готово к подключению" }}</div>
          <div v-if="error" class="text-negative">{{ error }}</div>
        </div>
        <div class="row q-gutter-sm">
          <QBtn flat label="Сбросить" :disable="isBusy || !isDirty" @click="handleReset" />
          <QBtn flat label="Отмена" :disable="isBusy" @click="requestClose" />
          <QBtn color="primary" label="Подключить" :loading="isBusy" @click="handleSubmit" />
        </div>
      </QCardActions>
    </QCard>
  </QDialog>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from 'vue';
import {
  QDialog,
  QCard,
  QCardSection,
  QSeparator,
  QForm,
  QInput,
  QOptionGroup,
  QExpansionItem,
  QToggle,
  QCardActions,
  QBtn
} from 'quasar';

import type { ConnectionFormValues } from '@/stores/connection';

type ModalState = 'idle' | 'validating' | 'connecting' | 'success' | 'error';

interface Props {
  open: boolean;
  status: ModalState;
  message: string;
  error: string;
  initialValues: ConnectionFormValues;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'close'): void;
  (event: 'submit', values: ConnectionFormValues): void;
  (event: 'reset-defaults'): void;
}>();

const opened = computed({
  get: () => props.open,
  set: (value: boolean) => {
    if (!value) {
      requestClose();
    }
  }
});

const form = reactive<ConnectionFormValues>({ ...props.initialValues });
const errors = reactive<Record<string, string>>({});
const authOptions = [
  { label: 'SQL Auth', value: 'sql' },
  { label: 'Windows Auth', value: 'windows' },
  { label: 'Token', value: 'token' }
];

watch(
  () => props.initialValues,
  (next) => {
    Object.assign(form, next);
    clearErrors();
  },
  { deep: true }
);

const statusLabel = computed(() => {
  switch (props.status) {
    case 'validating':
      return 'Проверяем данные…';
    case 'connecting':
      return 'Подключение…';
    case 'success':
      return 'Подключено';
    case 'error':
      return 'Ошибка подключения';
    default:
      return 'Готово к подключению';
  }
});

const isBusy = computed(() => ['validating', 'connecting'].includes(props.status));
const baseline = computed(() => JSON.stringify({ ...props.initialValues, password: '', token: '' }));
const currentSnapshot = computed(() => JSON.stringify({ ...form, password: '', token: '' }));
const isDirty = computed(() => baseline.value !== currentSnapshot.value);

function handleSubmit(): void {
  if (isBusy.value) {
    return;
  }
  if (!validate()) {
    return;
  }
  emit('submit', { ...form });
}

function handleReset(): void {
  if (isBusy.value) {
    return;
  }
  emit('reset-defaults');
}

function requestClose(): void {
  if (isBusy.value) {
    return;
  }
  if (isDirty.value && !window.confirm('Есть несохранённые изменения. Закрыть окно?')) {
    return;
  }
  emit('close');
}

function clearErrors(): void {
  Object.keys(errors).forEach((key) => delete errors[key]);
}

function validate(): boolean {
  const nextErrors: Record<string, string> = {};
  if (!form.host) {
    nextErrors.host = 'Укажите host';
  }
  if (!form.port) {
    nextErrors.port = 'Укажите порт';
  } else if (Number.isNaN(Number.parseInt(form.port, 10))) {
    nextErrors.port = 'Некорректный порт';
  }
  if (!form.database) {
    nextErrors.database = 'Укажите базу данных';
  }
  if (form.authMode === 'sql') {
    if (!form.username) {
      nextErrors.username = 'Укажите пользователя';
    }
    if (!form.password) {
      nextErrors.password = 'Введите пароль';
    }
  }
  if (form.authMode === 'token' && !form.token) {
    nextErrors.token = 'Введите токен доступа';
  }
  if (form.timeoutSeconds && Number.parseInt(form.timeoutSeconds, 10) <= 0) {
    nextErrors.timeoutSeconds = 'Таймаут должен быть больше нуля';
  }

  clearErrors();
  Object.entries(nextErrors).forEach(([key, value]) => {
    errors[key] = value;
  });
  return Object.keys(nextErrors).length === 0;
}
</script>

<style scoped>
.connection-modal {
  width: min(720px, 92vw);
  max-height: 90vh;
}
</style>
