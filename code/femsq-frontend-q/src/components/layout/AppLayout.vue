<template>
  <QLayout view="hHh lpR fFf">
    <QHeader class="femsq-app-header" bordered>
      <TopBar
        :active-view="activeView"
        :organizations-enabled="organizationsEnabled"
        :construction-sites-enabled="constructionSitesEnabled"
        :investment-chains-enabled="investmentChainsEnabled"
        :reports-enabled="reportsEnabled"
        :sudz-enabled="sudzEnabled"
        @navigate="emit('navigate', $event)"
      />
    </QHeader>

    <QPageContainer>
      <slot />
    </QPageContainer>

    <QFooter class="femsq-app-footer" bordered>
      <StatusBar
        :status="status"
        :status-tone="statusTone"
        :message="message"
        :schema="schema"
        :user="user"
        :error="error"
        @open-connection="emit('open-connection')"
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
  constructionSitesEnabled: boolean;
  investmentChainsEnabled: boolean;
  reportsEnabled: boolean;
  sudzEnabled: boolean;
}

defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
  (event: 'disconnect'): void;
}>();
</script>
