<template>
  <ConnectionModal
    :open="open"
    :status="status"
    :message="message"
    :error="error"
    :initial-values="form"
    @close="handleClose"
    @submit="handleSubmit"
    @reset-defaults="handleReset"
  />
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue';

import ConnectionModal from './ConnectionModal.vue';
import type { ConnectionFormValues } from '@/stores/connection';

const emit = defineEmits<{
  (event: 'close'): void;
  (event: 'submit', values: ConnectionFormValues): void;
}>();

const open = defineModel<boolean>({ required: true });
const status = defineModel<'idle' | 'validating' | 'connecting' | 'success' | 'error'>('status', { default: 'idle' });
const message = defineModel<string>('message', { default: 'Введите параметры подключения' });
const error = defineModel<string>('error', { default: '' });
const form = defineModel<ConnectionFormValues>('form', {
  default: {
    host: 'localhost',
    port: '1433',
    database: 'FishEye',
    schema: 'ags_test',
    authMode: 'sql',
    username: 'sa',
    password: '',
    token: '',
    timeoutSeconds: '30',
    useSsl: false,
    applicationName: 'FEMSQ UI'
  }
});

function handleClose(): void {
  emit('close');
}

function handleSubmit(values: ConnectionFormValues): void {
  emit('submit', values);
}

function handleReset(): void {
  form.value = {
    ...form.value,
    password: '',
    token: ''
  };
  message.value = 'Данные восстановлены';
  error.value = '';
}
</script>
