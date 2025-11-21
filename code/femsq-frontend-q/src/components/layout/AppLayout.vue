<template>
  <QLayout view="hHh lpR fFf">
    <QHeader elevated class="bg-white text-dark">
      <TopBar
        :status="status"
        :active-view="activeView"
        :organizations-enabled="organizationsEnabled"
        :investment-chains-enabled="investmentChainsEnabled"
        @open-connection="emit('open-connection')"
        @navigate="emit('navigate', $event)"
      />
    </QHeader>

    <QPageContainer>
      <slot />
    </QPageContainer>

    <QFooter elevated class="bg-white text-dark">
      <StatusBar
        :status="status"
        :status-tone="statusTone"
        :message="message"
        :schema="schema"
        :user="user"
        :error="error"
        @disconnect="emit('disconnect')"
      />
    </QFooter>
  </QLayout>
</template>

<script setup lang="ts">
import { QLayout, QHeader, QPageContainer, QFooter } from 'quasar';

import TopBar from './TopBar.vue';
import StatusBar from './StatusBar.vue';
import type { ActiveView, ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  statusTone: 'neutral' | 'info' | 'success' | 'danger' | 'positive' | 'negative';
  message: string;
  schema: string;
  user: string;
  error: string;
  activeView: ActiveView;
  organizationsEnabled: boolean;
  investmentChainsEnabled: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
  (event: 'disconnect'): void;
}>();
</script>
