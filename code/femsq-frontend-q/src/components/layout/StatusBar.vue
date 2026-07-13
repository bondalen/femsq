<template>
  <div class="status-bar q-pa-md" :class="[`status-bar--${statusTone}`]">
    <div class="status-bar__segment">
      <QChip dense outline :color="chipColor">
        {{ statusLabel }}
      </QChip>
      <span v-if="error" class="text-negative text-weight-medium">{{ error }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--center">
      <span>{{ message || '—' }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--right">
      <span>{{ schemaLabel }}</span>
      <span v-if="user" class="text-caption femsq-text-muted">{{ user }}</span>
      <QBtn
        v-if="status === 'connected'"
        flat
        round
        dense
        icon="logout"
        color="primary"
        @click="emit('disconnect')"
        aria-label="Отключиться"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { QChip, QBtn } from 'quasar';

import type { ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  statusTone: 'neutral' | 'info' | 'success' | 'danger' | 'positive' | 'negative';
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

const chipColor = computed(() => {
  switch (props.status) {
    case 'connected':
      return 'positive';
    case 'connecting':
    case 'disconnecting':
      return 'info';
    case 'connectionError':
      return 'negative';
    default:
      return 'grey-6';
  }
});

const schemaLabel = computed(() => {
  if (!props.schema) {
    return 'Схема не выбрана';
  }
  return `Схема: ${props.schema}`;
});
</script>

<style scoped>
.status-bar {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
  align-items: center;
  font-size: 14px;
}

.status-bar__segment {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.status-bar__segment--center {
  justify-content: center;
  color: var(--femsq-status-center-text);
}

.status-bar__segment--right {
  justify-content: flex-end;
}

.status-bar--info {
  background: var(--femsq-status-info-bg);
}

.status-bar--positive {
  background: var(--femsq-status-positive-bg);
}

.status-bar--negative {
  background: var(--femsq-status-negative-bg);
}

@media (max-width: 768px) {
  .status-bar {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .status-bar__segment,
  .status-bar__segment--center,
  .status-bar__segment--right {
    justify-content: flex-start;
  }
}
</style>
