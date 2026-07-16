<template>
  <div class="status-bar" :class="[`status-bar--${statusTone}`]">
    <div class="status-bar__segment">
      <QChip dense outline :color="chipColor" class="status-bar__chip">
        {{ statusLabel }}
      </QChip>
      <span v-if="error" class="text-negative text-weight-medium status-bar__error">{{ error }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--center">
      <span class="status-bar__message">{{ message || '—' }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--right">
      <span class="status-bar__schema">{{ schemaLabel }}</span>
      <span v-if="user" class="text-caption femsq-text-muted">{{ user }}</span>
      <QBtn
        v-if="status === 'connected'"
        flat
        round
        dense
        icon="logout"
        color="primary"
        class="status-bar__logout"
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
/*
 * Высота = высота самого высокого компонента (chip dense / btn dense ≈ 24px)
 * плюс ~10% запаса по вертикали (padding-block).
 */
.status-bar {
  --status-bar-tallest: 24px;
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 8px;
  align-items: center;
  min-height: calc(var(--status-bar-tallest) * 1.1);
  padding-block: calc(var(--status-bar-tallest) * 0.05);
  padding-inline: 12px;
  font-size: 13px;
  line-height: 1.2;
  box-sizing: border-box;
}

.status-bar__segment {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: nowrap;
  min-height: var(--status-bar-tallest);
}

.status-bar__segment--center {
  justify-content: center;
  color: var(--femsq-status-center-text);
}

.status-bar__segment--right {
  justify-content: flex-end;
}

.status-bar__message,
.status-bar__schema,
.status-bar__error {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
    gap: 4px;
    padding-block: 6px;
  }

  .status-bar__segment,
  .status-bar__segment--center,
  .status-bar__segment--right {
    justify-content: flex-start;
    flex-wrap: wrap;
  }
}
</style>
