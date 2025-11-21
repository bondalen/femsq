<template>
  <QToolbar class="q-px-lg q-py-sm top-bar" data-test="top-bar">
    <div class="row items-center q-gutter-sm">
      <div class="text-subtitle1 text-weight-bold">FEMSQ</div>
      <div class="text-caption text-grey-7">Контрагенты и объекты</div>
    </div>

    <QSpace />

    <div class="row items-center q-gutter-sm" v-if="!isXs">
      <QChip :color="statusColor" text-color="white" dense>
        {{ statusLabel }}
      </QChip>
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
        :color="activeView === 'organizations' ? 'primary' : 'dark'"
        :disable="!organizationsEnabled"
        @click="handleNavigate('organizations')"
      />
      <QBtn
        flat
        rounded
        icon="account_tree"
        label="Инвестиционные цепочки"
        :color="activeView === 'investment-chains' ? 'primary' : 'dark'"
        :disable="!investmentChainsEnabled"
        @click="handleNavigate('investment-chains')"
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
        <QItem clickable :disable="!investmentChainsEnabled" @click="handleNavigate('investment-chains')">
          <QItemSection avatar>
            <QIcon name="account_tree" />
          </QItemSection>
          <QItemSection>Инвестиционные цепочки</QItemSection>
        </QItem>
      </QList>
    </QMenu>
  </QToolbar>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useQuasar, QToolbar, QBtn, QSpace, QChip, QMenu, QList, QItem, QItemSection, QIcon } from 'quasar';

import type { ActiveView, ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  activeView: ActiveView;
  organizationsEnabled: boolean;
  investmentChainsEnabled: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
}>();

const $q = useQuasar();
const menu = ref(false);

const isXs = computed(() => $q.screen.xs);

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
.top-bar {
  backdrop-filter: blur(8px);
}
</style>
