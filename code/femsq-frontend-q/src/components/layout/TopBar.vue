<template>
  <QToolbar class="q-px-md femsq-top-bar" data-test="top-bar">
    <div class="femsq-brand" data-test="top-bar-brand">FEMSQ</div>

    <QSpace />

    <nav v-if="!isXs" class="femsq-nav" aria-label="Основная навигация">
      <button
        type="button"
        class="femsq-nav-item"
        :class="{ 'femsq-nav-item--active': activeView === 'organizations' }"
        :disabled="!organizationsEnabled"
        data-test="nav-organizations"
        @click="handleNavigate('organizations')"
      >
        Организации
      </button>
      <QBtn
        flat
        dense
        no-caps
        class="femsq-nav-item femsq-nav-item--btn"
        :class="{
          'femsq-nav-item--active':
            activeView === 'construction-sites' || activeView === 'construction-sites-by-code'
        }"
        :disable="!constructionSitesEnabled"
        label="Стройки"
        icon-right="expand_more"
        data-test="nav-construction-sites"
      >
        <QMenu anchor="bottom right" self="top right">
          <QList dense style="min-width: 160px" role="menu">
            <QItem
              clickable
              v-close-popup
              :active="activeView === 'construction-sites'"
              data-test="nav-construction-sites-list"
              @click="handleNavigate('construction-sites')"
            >
              <QItemSection>Стройки (cst)</QItemSection>
            </QItem>
            <QItem
              clickable
              v-close-popup
              :active="activeView === 'construction-sites-by-code'"
              data-test="nav-construction-sites-by-code"
              @click="handleNavigate('construction-sites-by-code')"
            >
              <QItemSection>САК (cstAgPn)</QItemSection>
            </QItem>
          </QList>
        </QMenu>
      </QBtn>
      <button
        type="button"
        class="femsq-nav-item"
        :class="{ 'femsq-nav-item--active': activeView === 'reports' }"
        :disabled="!reportsEnabled"
        data-test="nav-reports"
        @click="handleNavigate('reports')"
      >
        Отчёты
      </button>
      <button
        type="button"
        class="femsq-nav-item"
        :class="{ 'femsq-nav-item--active': activeView === 'investment-chains' }"
        :disabled="!investmentChainsEnabled"
        data-test="nav-investment-chains"
        @click="handleNavigate('investment-chains')"
      >
        Инвестиции
      </button>
      <button
        type="button"
        class="femsq-nav-item"
        :class="{ 'femsq-nav-item--active': activeView === 'audits' }"
        data-test="nav-audits"
        @click="handleNavigate('audits')"
      >
        Ревизии
      </button>

      <QBtn
        flat
        dense
        no-caps
        class="femsq-nav-item femsq-nav-item--btn"
        :class="{
          'femsq-nav-item--active':
            activeView === 'sudz-portfolio' || activeView === 'sudz-debts'
        }"
        :disable="!sudzEnabled"
        label="СУДЗ"
        icon-right="expand_more"
        data-test="nav-sudz"
      >
        <QMenu anchor="bottom right" self="top right">
          <QList dense style="min-width: 200px" role="menu">
            <QItem
              clickable
              v-close-popup
              :active="activeView === 'sudz-portfolio'"
              data-test="nav-sudz-portfolio"
              @click="handleNavigate('sudz-portfolio')"
            >
              <QItemSection>Портфель года</QItemSection>
            </QItem>
            <QItem
              clickable
              v-close-popup
              :active="activeView === 'sudz-debts'"
              data-test="nav-sudz-debts"
              @click="handleNavigate('sudz-debts')"
            >
              <QItemSection>Долги / мероприятия</QItemSection>
            </QItem>
            <QItem clickable disable>
              <QItemSection>Исходящие документы</QItemSection>
            </QItem>
            <QItem clickable disable>
              <QItemSection>Загрузка свода</QItemSection>
            </QItem>
          </QList>
        </QMenu>
      </QBtn>

      <QBtn
        flat
        dense
        no-caps
        class="femsq-nav-item femsq-nav-item--btn"
        :class="{ 'femsq-nav-item--active': activeView === 'test-grid' }"
        label="Сервис"
        icon-right="expand_more"
        data-test="nav-service"
      >
        <QMenu anchor="bottom right" self="top right">
          <QList dense style="min-width: 160px" role="menu">
            <QItem
              clickable
              v-close-popup
              :active="activeView === 'test-grid'"
              data-test="nav-test-grid"
              @click="handleNavigate('test-grid')"
            >
              <QItemSection>Test Grid</QItemSection>
            </QItem>
          </QList>
        </QMenu>
      </QBtn>
    </nav>

    <QBtn
      v-else
      flat
      dense
      icon="menu"
      class="femsq-chrome-icon-btn"
      aria-label="Меню"
      aria-haspopup="menu"
      :aria-expanded="menu"
      data-test="top-bar-menu"
    >
      <QMenu v-model="menu" anchor="bottom right" self="top right">
        <QList dense style="min-width: 200px" role="menu">
          <QItem
            clickable
            v-close-popup
            :disable="!organizationsEnabled"
            @click="handleNavigate('organizations')"
          >
            <QItemSection>Организации</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!constructionSitesEnabled"
            @click="handleNavigate('construction-sites')"
          >
            <QItemSection>Стройки (cst)</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!constructionSitesEnabled"
            @click="handleNavigate('construction-sites-by-code')"
          >
            <QItemSection>САК (cstAgPn)</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!reportsEnabled"
            @click="handleNavigate('reports')"
          >
            <QItemSection>Отчёты</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!investmentChainsEnabled"
            @click="handleNavigate('investment-chains')"
          >
            <QItemSection>Инвестиции</QItemSection>
          </QItem>
          <QItem clickable v-close-popup @click="handleNavigate('audits')">
            <QItemSection>Ревизии</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!sudzEnabled"
            @click="handleNavigate('sudz-portfolio')"
          >
            <QItemSection>СУДЗ · Портфель года</QItemSection>
          </QItem>
          <QItem
            clickable
            v-close-popup
            :disable="!sudzEnabled"
            @click="handleNavigate('sudz-debts')"
          >
            <QItemSection>СУДЗ · Долги / мероприятия</QItemSection>
          </QItem>
          <QItem clickable v-close-popup @click="handleNavigate('test-grid')">
            <QItemSection>Сервис · Test Grid</QItemSection>
          </QItem>
        </QList>
      </QMenu>
    </QBtn>
  </QToolbar>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useQuasar, QToolbar, QBtn, QSpace, QMenu, QList, QItem, QItemSection } from 'quasar';

import type { ActiveView } from '@/stores/connection';

interface Props {
  activeView: ActiveView;
  organizationsEnabled: boolean;
  constructionSitesEnabled: boolean;
  investmentChainsEnabled: boolean;
  reportsEnabled: boolean;
  sudzEnabled: boolean;
}

defineProps<Props>();
const emit = defineEmits<{
  (event: 'navigate', view: ActiveView): void;
}>();

const $q = useQuasar();
const menu = ref(false);

const isXs = computed(() => $q.screen.xs);

watch(isXs, (xs) => {
  if (!xs) {
    menu.value = false;
  }
});

/**
 * Переключает активный доменный экран.
 */
function handleNavigate(view: ActiveView): void {
  emit('navigate', view);
}
</script>

<style scoped>
.femsq-top-bar {
  min-height: 40px;
  padding-block: 4px;
}

.femsq-brand {
  font-size: var(--femsq-chrome-font-size);
  font-weight: 600;
  letter-spacing: 0.02em;
  color: var(--femsq-text);
  user-select: none;
}

.femsq-nav {
  display: flex;
  align-items: center;
  gap: 2px;
}

.femsq-nav-item {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  height: var(--femsq-nav-item-height);
  padding: 0 10px;
  border: none;
  border-radius: var(--femsq-control-radius);
  background: transparent;
  color: var(--femsq-text-muted);
  font: inherit;
  font-size: var(--femsq-chrome-font-size);
  line-height: 1;
  cursor: pointer;
  white-space: nowrap;
}

.femsq-nav-item:hover:not(:disabled) {
  background: var(--femsq-item-hover-bg);
  color: var(--femsq-text);
}

.femsq-nav-item--active {
  background: var(--femsq-item-active-bg);
  color: var(--femsq-primary);
  box-shadow: inset 0 -2px 0 var(--femsq-primary);
}

.femsq-nav-item:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.femsq-nav-item__chevron {
  opacity: 0.7;
}

.femsq-nav-item--btn {
  min-height: var(--femsq-nav-item-height);
  padding: 0 10px;
  font-size: var(--femsq-chrome-font-size);
  color: var(--femsq-text-muted);
  border-radius: var(--femsq-control-radius);
}

.femsq-nav-item--btn :deep(.q-icon) {
  font-size: 16px;
}

.femsq-chrome-icon-btn {
  color: var(--femsq-text-muted) !important;
  border-radius: var(--femsq-control-radius) !important;
}
</style>
