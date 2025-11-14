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
      <span v-if="user" class="text-caption text-grey-7">{{ user }}</span>
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
  color: rgba(28, 35, 51, 0.72);
}

.status-bar__segment--right {
  justify-content: flex-end;
}

.status-bar--info {
  background: linear-gradient(90deg, rgba(14, 165, 233, 0.08), rgba(14, 165, 233, 0));
}

.status-bar--positive {
  background: linear-gradient(90deg, rgba(34, 197, 94, 0.12), rgba(34, 197, 94, 0));
}

.status-bar--negative {
  background: linear-gradient(90deg, rgba(239, 68, 68, 0.12), rgba(239, 68, 68, 0));
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
