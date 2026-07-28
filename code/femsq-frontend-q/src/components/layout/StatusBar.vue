<template>
  <div class="status-bar" :class="[`status-bar--${statusTone}`]" data-test="status-bar">
    <div class="status-bar__segment">
      <button
        type="button"
        class="status-bar__connection"
        data-test="status-connection"
        :title="connectionTitle"
        @click="emit('open-connection')"
      >
        <span class="status-bar__dot" :class="`status-bar__dot--${dotTone}`" aria-hidden="true" />
        <span class="status-bar__connection-label">{{ statusLabel }}</span>
      </button>
      <span v-if="error" class="status-bar__error" :title="error">{{ error }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--center">
      <span class="status-bar__message" :title="message || undefined">{{ message || '—' }}</span>
    </div>

    <div class="status-bar__segment status-bar__segment--right">
      <span class="status-bar__schema">{{ schemaLabel }}</span>
      <span v-if="user" class="status-bar__user">{{ user }}</span>
      <button
        type="button"
        class="status-bar__icon-btn"
        data-test="status-theme-toggle"
        :aria-label="themeToggleLabel"
        :title="themeMenuLabel"
        @click="handleToggleTheme"
      >
        <QIcon :name="themeToggleIcon" :size="iconSize" />
      </button>
      <button
        v-if="status === 'connected'"
        type="button"
        class="status-bar__icon-btn"
        data-test="status-disconnect"
        aria-label="Отключиться"
        title="Отключиться"
        @click="emit('disconnect')"
      >
        <QIcon name="logout" :size="iconSize" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { QIcon } from 'quasar';

import type { ConnectionState } from '@/stores/connection';
import { useThemeStore } from '@/stores/theme';
import { themeToggleAriaLabel, themeToggleIcon as resolveThemeToggleIcon } from '@/theme/femsq-theme';

interface Props {
  status: ConnectionState;
  statusTone: 'neutral' | 'info' | 'success' | 'danger' | 'positive' | 'negative';
  message: string;
  schema: string;
  user: string;
  error: string;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'disconnect'): void;
}>();

const themeStore = useThemeStore();
const iconSize = '18px';

const themeToggleIcon = computed(() => resolveThemeToggleIcon(themeStore.themeId));
const themeToggleLabel = computed(() => themeToggleAriaLabel(themeStore.themeId));
const themeMenuLabel = computed(() =>
  themeStore.isDark ? 'Светлая тема (Visual Studio)' : 'Тёмная тема (Kimbie Dark)'
);

const statusLabel = computed(() => {
  switch (props.status) {
    case 'connecting':
      return 'Подключение…';
    case 'connected':
      return 'Подключено';
    case 'connectionError':
      return 'Ошибка';
    case 'disconnecting':
      return 'Отключение…';
    default:
      return 'Не подключено';
  }
});

const connectionTitle = computed(
  () => `${statusLabel.value}. Нажмите, чтобы открыть параметры подключения.`
);

const dotTone = computed(() => {
  switch (props.status) {
    case 'connected':
      return 'positive';
    case 'connecting':
    case 'disconnecting':
      return 'info';
    case 'connectionError':
      return 'negative';
    default:
      return 'neutral';
  }
});

const schemaLabel = computed(() => {
  if (!props.schema) {
    return 'Схема не выбрана';
  }
  return props.schema;
});

/**
 * Переключает глобальную тему (Kimbie Dark ↔ VS Light).
 */
function handleToggleTheme(): void {
  themeStore.toggleTheme();
}
</script>

<style scoped>
.status-bar {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(0, 1fr) minmax(0, 1.2fr);
  gap: 8px;
  align-items: center;
  min-height: 28px;
  padding: 2px 10px;
  font-size: var(--femsq-status-bar-font-size);
  line-height: 1.2;
  box-sizing: border-box;
  border-top: 1px solid var(--femsq-border);
  color: var(--femsq-text);
}

.status-bar__segment {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.status-bar__segment--center {
  justify-content: center;
  color: var(--femsq-status-center-text);
}

.status-bar__segment--right {
  justify-content: flex-end;
}

.status-bar__connection {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  max-width: 100%;
  padding: 2px 6px;
  margin: 0;
  border: none;
  border-radius: var(--femsq-control-radius);
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}

.status-bar__connection:hover {
  background: var(--femsq-item-hover-bg);
}

.status-bar__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
  background: var(--femsq-text-muted);
}

.status-bar__dot--positive {
  background: #98c379;
}

.status-bar__dot--info {
  background: var(--femsq-primary);
}

.status-bar__dot--negative {
  background: #f44747;
}

.status-bar__dot--neutral {
  background: var(--femsq-text-muted);
}

.status-bar__connection-label,
.status-bar__message,
.status-bar__schema,
.status-bar__user,
.status-bar__error {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.status-bar__error {
  color: var(--femsq-banner-error-text);
  max-width: 40%;
}

.status-bar__user {
  color: var(--femsq-text-muted);
}

.status-bar__icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  padding: 0;
  border: none;
  border-radius: var(--femsq-control-radius);
  background: transparent;
  color: var(--femsq-text-muted);
  cursor: pointer;
  flex-shrink: 0;
}

.status-bar__icon-btn:hover {
  background: var(--femsq-item-hover-bg);
  color: var(--femsq-text);
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
    gap: 2px;
    padding-block: 4px;
  }

  .status-bar__segment,
  .status-bar__segment--center,
  .status-bar__segment--right {
    justify-content: flex-start;
  }
}
</style>
