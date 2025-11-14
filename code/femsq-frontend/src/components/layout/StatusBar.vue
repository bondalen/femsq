<template>
  <section class="status-bar" :data-tone="tone">
    <div class="status-bar__segment">
      <span class="status-bar__label">{{ statusLabel }}</span>
      <span v-if="error" class="status-bar__error" role="alert">{{ error }}</span>
    </div>
    <div class="status-bar__segment status-bar__segment--center">
      <span>{{ message }}</span>
    </div>
    <div class="status-bar__segment status-bar__segment--right">
      <span v-if="schema">Схема: {{ schema }}</span>
      <span v-else>Схема не выбрана</span>
      <span v-if="user" class="status-bar__user">Пользователь: {{ user }}</span>
      <button
        v-if="status === 'connected'"
        type="button"
        class="status-bar__action"
        @click="emit('disconnect')"
      >
        Отключиться
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  tone: 'neutral' | 'info' | 'success' | 'danger';
  message: string;
  schema: string;
  user: string;
  error: string;
}

const props = defineProps<Props>();
const emit = defineEmits<{ (event: 'disconnect'): void }>();

const statusLabel = computed(() => {
  switch (props.status) {
    case 'connecting':
      return 'Идёт подключение…';
    case 'connected':
      return 'Подключено';
    case 'connectionError':
      return 'Ошибка подключения';
    case 'disconnecting':
      return 'Отключение…';
    default:
      return 'Не подключено';
  }
});
</script>

<style scoped>
.status-bar {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 24px;
  padding: 12px 24px;
  font-size: 14px;
  align-items: center;
}

.status-bar__segment {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
}

.status-bar__segment--center {
  justify-content: center;
  color: rgba(28, 35, 51, 0.72);
}

.status-bar__segment--right {
  justify-content: flex-end;
}

.status-bar__label {
  font-weight: 600;
}

.status-bar__error {
  color: #ef4444;
  font-weight: 500;
}

.status-bar__user {
  color: rgba(28, 35, 51, 0.72);
}

.status-bar__action {
  border: none;
  background: transparent;
  color: #2563eb;
  cursor: pointer;
  font-weight: 500;
}

.status-bar[data-tone='info'] {
  background: linear-gradient(90deg, rgba(14, 165, 233, 0.09), rgba(14, 165, 233, 0));
}

.status-bar[data-tone='success'] {
  background: linear-gradient(90deg, rgba(34, 197, 94, 0.12), rgba(34, 197, 94, 0));
}

.status-bar[data-tone='danger'] {
  background: linear-gradient(90deg, rgba(239, 68, 68, 0.1), rgba(239, 68, 68, 0));
}

@media (max-width: 768px) {
  .status-bar {
    grid-template-columns: 1fr;
    gap: 8px;
    padding: 16px;
  }

  .status-bar__segment,
  .status-bar__segment--right,
  .status-bar__segment--center {
    justify-content: flex-start;
    gap: 8px;
  }
}
</style>
