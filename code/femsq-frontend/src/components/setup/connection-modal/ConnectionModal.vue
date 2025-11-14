<template>
  <Teleport to="body">
    <transition name="modal-fade">
      <div v-if="open" class="modal" @keydown.esc.prevent="handleEsc">
        <div class="modal__backdrop" @click.self="requestClose"></div>
        <section class="modal__panel" role="dialog" aria-modal="true" aria-labelledby="connection-modal-title">
          <header class="modal__header">
            <div class="modal__title-group">
              <h2 id="connection-modal-title">Подключение к базе данных</h2>
              <small :class="['modal__status', `modal__status--${status}`]">{{ statusLabel }}</small>
            </div>
            <button class="modal__close" type="button" @click="requestClose" aria-label="Закрыть">×</button>
          </header>

          <form class="modal__body" @submit.prevent="handleSubmit">
            <fieldset :disabled="isBusy">
              <div class="modal__fields">
                <label class="modal__field">
                  <span>Host *</span>
                  <input v-model.trim="form.host" type="text" data-focus="connection-host" autocomplete="off" />
                  <span v-if="errors.host" class="modal__error">{{ errors.host }}</span>
                </label>
                <label class="modal__field">
                  <span>Port *</span>
                  <input v-model.trim="form.port" type="number" min="1" max="65535" autocomplete="off" />
                  <span v-if="errors.port" class="modal__error">{{ errors.port }}</span>
                </label>
                <label class="modal__field">
                  <span>Database *</span>
                  <input v-model.trim="form.database" type="text" autocomplete="off" />
                  <span v-if="errors.database" class="modal__error">{{ errors.database }}</span>
                </label>
                <label class="modal__field">
                  <span>Schema</span>
                  <input v-model.trim="form.schema" type="text" autocomplete="off" />
                </label>
              </div>

              <div class="modal__section">
                <span class="modal__section-title">Режим аутентификации *</span>
                <div class="modal__auth">
                  <label class="modal__radio">
                    <input v-model="form.authMode" type="radio" value="sql" /> SQL Auth
                  </label>
                  <label class="modal__radio">
                    <input v-model="form.authMode" type="radio" value="windows" /> Windows Auth
                  </label>
                  <label class="modal__radio">
                    <input v-model="form.authMode" type="radio" value="token" /> Token
                  </label>
                </div>

                <div v-if="form.authMode === 'sql'" class="modal__fields">
                  <label class="modal__field">
                    <span>Username *</span>
                    <input v-model.trim="form.username" type="text" autocomplete="username" />
                    <span v-if="errors.username" class="modal__error">{{ errors.username }}</span>
                  </label>
                  <label class="modal__field">
                    <span>Password *</span>
                    <input v-model="form.password" type="password" autocomplete="current-password" />
                    <span v-if="errors.password" class="modal__error">{{ errors.password }}</span>
                  </label>
                </div>

                <div v-else-if="form.authMode === 'token'" class="modal__fields">
                  <label class="modal__field modal__field--full">
                    <span>Token *</span>
                    <textarea v-model.trim="form.token" rows="3"></textarea>
                    <span v-if="errors.token" class="modal__error">{{ errors.token }}</span>
                  </label>
                </div>
              </div>

              <details class="modal__details" :open="advancedOpen">
                <summary @click.prevent="toggleAdvanced">Дополнительно</summary>
                <div class="modal__details-body">
                  <label class="modal__field">
                    <span>Timeout, сек</span>
                    <input v-model.trim="form.timeoutSeconds" type="number" min="5" max="600" />
                    <span v-if="errors.timeoutSeconds" class="modal__error">{{ errors.timeoutSeconds }}</span>
                  </label>
                  <label class="modal__field">
                    <span>Application name</span>
                    <input v-model.trim="form.applicationName" type="text" autocomplete="off" />
                  </label>
                  <label class="modal__checkbox">
                    <input v-model="form.useSsl" type="checkbox" /> Использовать SSL
                  </label>
                </div>
              </details>
            </fieldset>
          </form>

          <footer class="modal__footer">
            <div class="modal__messages">
              <span v-if="message">{{ message }}</span>
              <span v-if="error" class="modal__error">{{ error }}</span>
            </div>
            <div class="modal__actions">
              <button type="button" class="modal__button" @click="handleReset" :disabled="isBusy || !isDirty">
                Сбросить
              </button>
              <button type="button" class="modal__button" @click="requestClose" :disabled="isBusy">
                Отмена
              </button>
              <button type="submit" class="modal__button modal__button--primary" formnovalidate :disabled="isBusy">
                <span v-if="status === 'connecting'" class="modal__spinner" aria-hidden="true"></span>
                <span>Подключить</span>
              </button>
            </div>
          </footer>
        </section>
      </div>
    </transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue';

import type { ConnectionFormValues } from '@/stores/connection';

type ModalStatus = 'idle' | 'validating' | 'connecting' | 'success' | 'error' | 'closing';

interface Props {
  open: boolean;
  status: ModalStatus;
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

const form = reactive<ConnectionFormValues>({ ...props.initialValues });
const errors = reactive<Record<string, string>>({});
const advancedOpen = ref(false);

watch(
  () => props.initialValues,
  (next) => {
    Object.assign(form, next);
    clearErrors();
  },
  { deep: true }
);

watch(
  () => props.open,
  (value) => {
    if (value) {
      window.setTimeout(() => {
        document.querySelector<HTMLInputElement>('[data-focus="connection-host"]')?.focus();
      }, 0);
      escapeHandlerActive.value = true;
    } else {
      escapeHandlerActive.value = false;
    }
  }
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

const isBusy = computed(() => ['validating', 'connecting', 'closing', 'success'].includes(props.status));

const baseline = computed(() => JSON.stringify({ ...props.initialValues, password: '', token: '' }));
const snapshot = computed(() => JSON.stringify({ ...form, password: '', token: '' }));
const isDirty = computed(() => baseline.value !== snapshot.value);

const escapeHandlerActive = ref(false);
function handleEsc(): void {
  if (escapeHandlerActive.value) {
    requestClose();
  }
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
    nextErrors.token = 'Введите токен';
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

function clearErrors(): void {
  Object.keys(errors).forEach((key) => delete errors[key]);
}

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

function toggleAdvanced(): void {
  advancedOpen.value = !advancedOpen.value;
}

onBeforeUnmount(() => {
  escapeHandlerActive.value = false;
});
</script>

<style scoped>
.modal {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(17, 24, 39, 0.45);
}

.modal__panel {
  position: relative;
  width: min(640px, 92vw);
  max-height: 90vh;
  background: #ffffff;
  border-radius: 24px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 32px 64px rgba(17, 24, 39, 0.2);
  animation: pop 0.2s ease;
}

.modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px 28px 16px;
  border-bottom: 1px solid rgba(17, 24, 39, 0.08);
}

.modal__title-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal__status {
  font-size: 13px;
  color: rgba(17, 24, 39, 0.64);
}

.modal__status--connecting,
.modal__status--validating {
  color: #0ea5e9;
}

.modal__status--success {
  color: #22c55e;
}

.modal__status--error {
  color: #ef4444;
}

.modal__close {
  border: none;
  background: transparent;
  font-size: 26px;
  cursor: pointer;
  line-height: 1;
}

.modal__body {
  padding: 0 28px;
  overflow-y: auto;
}

.modal__fields {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 18px;
}

.modal__field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal__field span {
  font-weight: 600;
  font-size: 14px;
}

.modal__field input,
.modal__field textarea {
  border-radius: 12px;
  border: 1px solid rgba(17, 24, 39, 0.16);
  padding: 10px 12px;
  font-size: 14px;
}

.modal__field--full {
  grid-column: 1 / -1;
}

.modal__section {
  margin-bottom: 18px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.modal__section-title {
  font-weight: 600;
}

.modal__auth {
  display: flex;
  gap: 18px;
}

.modal__radio {
  display: inline-flex;
  gap: 8px;
  align-items: center;
  font-size: 14px;
}

.modal__details {
  border-top: 1px solid rgba(17, 24, 39, 0.08);
  padding-top: 12px;
}

.modal__details summary {
  font-weight: 600;
  cursor: pointer;
}

.modal__details-body {
  margin-top: 12px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.modal__checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
}

.modal__error {
  color: #ef4444;
  font-size: 13px;
}

.modal__footer {
  padding: 18px 28px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  border-top: 1px solid rgba(17, 24, 39, 0.08);
  flex-wrap: wrap;
}

.modal__messages {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 14px;
}

.modal__actions {
  display: flex;
  gap: 12px;
}

.modal__button {
  border-radius: 999px;
  border: 1px solid rgba(17, 24, 39, 0.12);
  background: white;
  padding: 10px 18px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.modal__button[disabled] {
  cursor: not-allowed;
  opacity: 0.6;
}

.modal__button--primary {
  border: none;
  background: linear-gradient(135deg, #2f7ace, #43b7b7);
  color: #ffffff;
  box-shadow: 0 8px 20px rgba(47, 122, 206, 0.25);
}

.modal__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.6);
  border-top-color: #ffffff;
  animation: spin 0.7s linear infinite;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.15s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@keyframes pop {
  from {
    transform: scale(0.96);
    opacity: 0;
  }
}

@media (max-width: 640px) {
  .modal__panel {
    width: 96vw;
    max-height: 96vh;
    border-radius: 20px;
  }
  .modal__header,
  .modal__body,
  .modal__footer {
    padding-left: 18px;
    padding-right: 18px;
  }
  .modal__auth {
    flex-direction: column;
    align-items: flex-start;
  }
  .modal__actions {
    width: 100%;
    justify-content: flex-end;
    flex-wrap: wrap;
  }
}
</style>
