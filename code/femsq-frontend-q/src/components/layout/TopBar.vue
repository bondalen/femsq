<template>
  <QToolbar class="q-px-lg q-py-sm femsq-top-bar" data-test="top-bar">
    <div class="row items-center q-gutter-sm">
      <div class="text-subtitle1 text-weight-bold">FEMSQ</div>
      <div class="text-caption femsq-text-muted">Контрагенты и объекты</div>
    </div>

    <QSpace />

    <div class="row items-center q-gutter-sm" v-if="!isXs">
      <QChip :color="statusColor" text-color="white" dense>
        {{ statusLabel }}
      </QChip>
      <QBtn
        flat
        round
        :icon="themeToggleIcon"
        color="primary"
        :aria-label="themeToggleLabel"
        @click="handleToggleTheme"
      />
      <QBtn
        color="primary"
        unelevated
        rounded
        icon="link"
        label="Подключение к БД"
        @click="handleOpenConnection"
      />
      <QBtn
        flat
        rounded
        icon="business"
        label="Организации"
        :color="activeView === 'organizations' ? 'primary' : undefined"
        :class="{ 'femsq-nav-btn--inactive': activeView !== 'organizations' }"
        :disable="!organizationsEnabled"
        @click="handleNavigate('organizations')"
      />
      <QBtn
        flat
        rounded
        icon="analytics"
        label="Отчёты"
        :color="activeView === 'reports' ? 'primary' : undefined"
        :class="{ 'femsq-nav-btn--inactive': activeView !== 'reports' }"
        :disable="!reportsEnabled"
        @click="handleNavigate('reports')"
      />
      <QBtn
        flat
        rounded
        icon="account_tree"
        label="Инвестиционные цепочки"
        :color="activeView === 'investment-chains' ? 'primary' : undefined"
        :class="{ 'femsq-nav-btn--inactive': activeView !== 'investment-chains' }"
        :disable="!investmentChainsEnabled"
        @click="handleNavigate('investment-chains')"
      />
      <QBtn
        flat
        rounded
        icon="verified_user"
        label="Ревизии"
        :color="activeView === 'audits' ? 'primary' : undefined"
        :class="{ 'femsq-nav-btn--inactive': activeView !== 'audits' }"
        @click="handleNavigate('audits')"
      />
      <QBtn
        flat
        rounded
        icon="grid_on"
        label="Test Grid"
        :color="activeView === 'test-grid' ? 'primary' : undefined"
        :class="{ 'femsq-nav-btn--inactive': activeView !== 'test-grid' }"
        @click="handleNavigate('test-grid')"
      />
    </div>

    <QBtn
      v-else
      round
      flat
      icon="menu"
      @click="menu = !menu"
      aria-label="Меню"
    />

    <QMenu v-model="menu" anchor="bottom right" self="top right">
      <QList style="min-width: 220px">
        <QItem clickable @click="handleToggleTheme">
          <QItemSection avatar>
            <QIcon :name="themeToggleIcon" />
          </QItemSection>
          <QItemSection>{{ themeMenuLabel }}</QItemSection>
        </QItem>
        <QItem clickable @click="handleOpenConnection">
          <QItemSection avatar>
            <QIcon name="link" />
          </QItemSection>
          <QItemSection>Подключение к БД</QItemSection>
        </QItem>
        <QItem clickable :disable="!organizationsEnabled" @click="handleNavigate('organizations')">
          <QItemSection avatar>
            <QIcon name="business" />
          </QItemSection>
          <QItemSection>Организации</QItemSection>
        </QItem>
        <QItem clickable :disable="!reportsEnabled" @click="handleNavigate('reports')">
          <QItemSection avatar>
            <QIcon name="analytics" />
          </QItemSection>
          <QItemSection>Отчёты</QItemSection>
        </QItem>
        <QItem clickable :disable="!investmentChainsEnabled" @click="handleNavigate('investment-chains')">
          <QItemSection avatar>
            <QIcon name="account_tree" />
          </QItemSection>
          <QItemSection>Инвестиционные цепочки</QItemSection>
        </QItem>
        <QItem clickable @click="handleNavigate('audits')">
          <QItemSection avatar>
            <QIcon name="verified_user" />
          </QItemSection>
          <QItemSection>Ревизии</QItemSection>
        </QItem>
        <QItem clickable @click="handleNavigate('test-grid')">
          <QItemSection avatar>
            <QIcon name="grid_on" />
          </QItemSection>
          <QItemSection>Test Grid</QItemSection>
        </QItem>
      </QList>
    </QMenu>
  </QToolbar>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useQuasar, QToolbar, QBtn, QSpace, QChip, QMenu, QList, QItem, QItemSection, QIcon } from 'quasar';

import type { ActiveView, ConnectionState } from '@/stores/connection';
import { useThemeStore } from '@/stores/theme';
import { themeToggleAriaLabel, themeToggleIcon as resolveThemeToggleIcon } from '@/theme/femsq-theme';

interface Props {
  status: ConnectionState;
  activeView: ActiveView;
  organizationsEnabled: boolean;
  investmentChainsEnabled: boolean;
  reportsEnabled: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
}>();

const $q = useQuasar();
const themeStore = useThemeStore();
const menu = ref(false);

const isXs = computed(() => $q.screen.xs);

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

const statusColor = computed(() => {
  switch (props.status) {
    case 'connecting':
    case 'disconnecting':
      return 'info';
    case 'connected':
      return 'positive';
    case 'connectionError':
      return 'negative';
    default:
      return 'grey-6';
  }
});

function handleToggleTheme(): void {
  themeStore.toggleTheme();
  menu.value = false;
}

function handleOpenConnection(): void {
  emit('open-connection');
  menu.value = false;
}

function handleNavigate(view: ActiveView): void {
  emit('navigate', view);
  menu.value = false;
}
</script>

<style scoped>
.femsq-nav-btn--inactive {
  color: var(--femsq-text-muted) !important;
}
</style>
