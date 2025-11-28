<template>
  <nav class="top-bar" :data-status="status">
    <div class="top-bar__brand">
      <div class="top-bar__logo" aria-hidden="true">FEMSQ</div>
      <div class="top-bar__caption">Контрагенты и объекты</div>
    </div>

    <button
      class="top-bar__burger"
      type="button"
      aria-label="Меню"
      @click="toggleMenu"
    >
      <span></span>
      <span></span>
      <span></span>
    </button>

    <div class="top-bar__actions" :class="{ 'top-bar__actions--mobile-open': menuOpen }">
      <button
        class="top-bar__button top-bar__button--primary"
        type="button"
        @click="handleOpenConnection"
      >
        <span class="top-bar__indicator" :data-status="status" aria-hidden="true"></span>
        Подключение к БД
      </button>
      <button
        class="top-bar__button"
        type="button"
        :disabled="!organizationsEnabled"
        :data-active="activeView === 'organizations'"
        @click="handleNavigate('organizations')"
      >
        Организации
      </button>
      <button
        class="top-bar__button"
        type="button"
        :disabled="!reportsEnabled"
        :data-active="activeView === 'reports'"
        @click="handleNavigate('reports')"
      >
        Отчёты
      </button>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import type { ActiveView, ConnectionState } from '@/stores/connection';

interface Props {
  status: ConnectionState;
  activeView: ActiveView;
  organizationsEnabled: boolean;
  reportsEnabled: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (event: 'open-connection'): void;
  (event: 'navigate', view: ActiveView): void;
}>();

const menuOpen = ref(false);

watch(
  () => props.activeView,
  () => {
    menuOpen.value = false;
  }
);

function toggleMenu(): void {
  menuOpen.value = !menuOpen.value;
}

function handleOpenConnection(): void {
  emit('open-connection');
  menuOpen.value = false;
}

function handleNavigate(view: ActiveView): void {
  emit('navigate', view);
}
</script>

<style scoped>
.top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 12px 24px;
}

.top-bar__brand {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.top-bar__logo {
  font-weight: 700;
  letter-spacing: 0.08em;
}

.top-bar__caption {
  font-size: 13px;
  color: rgba(28, 35, 51, 0.72);
}

.top-bar__actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

.top-bar__button {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  border-radius: 999px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  background: white;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.top-bar__button[disabled] {
  cursor: not-allowed;
  opacity: 0.5;
}

.top-bar__button[data-active='true'] {
  border-color: #2f7ace;
  color: #2f7ace;
}

.top-bar__button--primary {
  border: none;
  background: linear-gradient(135deg, #2f7ace, #43b7b7);
  color: #fff;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(47, 122, 206, 0.28);
}

.top-bar__button--primary:hover {
  transform: translateY(-1px);
}

.top-bar__indicator {
  display: inline-flex;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.8);
}

.top-bar__indicator[data-status='connected'] {
  background: #22c55e;
}

.top-bar__indicator[data-status='connecting'],
.top-bar__indicator[data-status='disconnecting'] {
  background: #0ea5e9;
}

.top-bar__indicator[data-status='connectionError'] {
  background: #ef4444;
}

.top-bar__burger {
  display: none;
  width: 44px;
  height: 44px;
  background: transparent;
  border: none;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 0;
}

.top-bar__burger span {
  display: block;
  width: 24px;
  height: 2px;
  background: rgba(28, 35, 51, 0.8);
  border-radius: 999px;
}

@media (max-width: 768px) {
  .top-bar {
    padding: 12px 16px;
  }

  .top-bar__actions {
    position: absolute;
    top: 64px;
    right: 16px;
    flex-direction: column;
    background: white;
    border-radius: 16px;
    padding: 16px;
    box-shadow: 0 20px 32px rgba(28, 35, 51, 0.12);
    transform: translateY(-12px);
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.2s ease;
  }

  .top-bar__actions--mobile-open {
    opacity: 1;
    pointer-events: auto;
    transform: translateY(0);
  }

  .top-bar__burger {
    display: inline-flex;
  }
}
</style>
