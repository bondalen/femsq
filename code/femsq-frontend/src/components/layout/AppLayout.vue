<template>
  <div class="app-layout" :data-status="status">
    <header class="app-layout__header">
      <TopBar
        :status="status"
        :active-view="activeView"
        :organizations-enabled="organizationsEnabled"
        :reports-enabled="reportsEnabled"
        @open-connection="emit('open-connection')"
        @navigate="emit('navigate', $event)"
      />
    </header>

    <main class="app-layout__content">
      <slot />
    </main>

    <footer class="app-layout__footer">
      <StatusBar
        :status="status"
        :tone="statusTone"
        :message="message"
        :schema="schema"
        :user="user"
        :error="error"
        @disconnect="emit('disconnect')"
      />
    </footer>
  </div>
</template>

<script setup lang="ts">
import TopBar from './TopBar.vue';
import StatusBar from './StatusBar.vue';
import type { ActiveView, ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  statusTone: 'neutral' | 'info' | 'success' | 'danger';
  message: string;
  schema: string;
  user: string;
  error: string;
  activeView: ActiveView;
  organizationsEnabled: boolean;
  reportsEnabled: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
  (event: 'disconnect'): void;
}>();
</script>

<style scoped>
.app-layout {
  min-height: 100vh;
  display: grid;
  grid-template-rows: auto 1fr auto;
  background: #f5f6f9;
  color: #1c2333;
}

.app-layout__header {
  position: sticky;
  top: 0;
  z-index: 5;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(28, 35, 51, 0.08);
}

.app-layout__content {
  padding: 32px;
  width: min(1200px, 100%);
  margin: 0 auto;
}

.app-layout__footer {
  border-top: 1px solid rgba(28, 35, 51, 0.08);
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(12px);
}

@media (max-width: 768px) {
  .app-layout__content {
    padding: 20px;
  }
}
</style>
