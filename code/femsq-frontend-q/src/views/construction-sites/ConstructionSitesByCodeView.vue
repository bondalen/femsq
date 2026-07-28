<template>
  <QPage class="cst-by-code-view q-pa-md" data-test="construction-sites-by-code-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">САК</div>
        <div class="femsq-page-subtitle">
          Форма Access <code>cstAgPn</code> · поиск стройки по коду
        </div>
      </div>
      <QBtn
        flat
        dense
        icon="refresh"
        :loading="store.loadingCodes"
        aria-label="Обновить"
        @click="reloadCodes()"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-md" rounded>
      {{ store.error }}
    </QBanner>

    <div class="row q-col-gutter-md">
      <!-- Left: codes (Access sidebar «код») -->
      <div class="col-12 col-md-3">
        <section class="codes-panel" data-test="cstap-codes-panel">
          <QInput
            v-model="codeFilter"
            dense
            clearable
            debounce="300"
            label="Фильтр по коду"
            hint="как Access: Like '*…*'"
            data-test="cstap-code-filter"
            @update:model-value="onFilterChange"
          />
          <div class="text-caption femsq-text-muted q-mt-xs q-mb-sm">
            {{ store.codeEntries.length }} код(ов)
          </div>
          <QList bordered dense class="codes-list" separator>
            <QInnerLoading :showing="store.loadingCodes">
              <QSpinner color="primary" size="2em" />
            </QInnerLoading>
            <QItem
              v-for="entry in store.codeEntries"
              :key="entry.cstapKey"
              clickable
              :active="store.selectedCodeKey === entry.cstapKey"
              active-class="codes-list__active"
              data-test="cstap-code-item"
              @click="onSelectCode(entry)"
            >
              <QItemSection>
                <QItemLabel>{{ entry.cstapIpgPnN }}</QItemLabel>
                <QItemLabel caption>
                  cst={{ entry.cstaCst }} · csta={{ entry.cstapCsta }}
                </QItemLabel>
              </QItemSection>
            </QItem>
            <QItem v-if="!store.loadingCodes && store.codeEntries.length === 0">
              <QItemSection class="femsq-text-muted">Нет кодов по фильтру</QItemSection>
            </QItem>
          </QList>
        </section>
      </div>

      <!-- Right: wrapped cst form (detail) -->
      <div class="col-12 col-md-9">
        <template v-if="store.selectedCode && store.selectedSite">
          <div class="code-context q-mb-sm" data-test="cstap-code-context">
            <span class="code-context__label">код</span>
            <span class="code-context__value">{{ store.selectedCode.cstapIpgPnN }}</span>
            <span class="text-caption femsq-text-muted q-ml-sm">
              cstapKey={{ store.selectedCode.cstapKey }}
            </span>
          </div>

          <div class="name-context q-mb-sm" data-test="cst-name-context">
            {{ store.selectedSite.cstName }}
            <span class="text-caption femsq-text-muted q-ml-sm">
              cstKey={{ store.selectedSite.cstKey }}
            </span>
          </div>

          <QTabs v-model="activeTab" dense align="left" class="q-mb-sm">
            <QTab name="agents" label="агенты" />
            <QTab name="reports" label="отчёты" />
            <QTab name="rent" label="отчёты, аренда" />
            <QTab name="ipg" label="инвестпрограммы" disable />
            <QTab name="common" label="общее" disable />
            <QTab name="osv" label="освоение" disable />
            <QTab name="chart-total" label="график, всего" disable />
            <QTab name="chart-types" label="график, виды" disable />
          </QTabs>

          <QTabPanels v-model="activeTab" animated>
            <QTabPanel name="agents" class="q-pa-none">
              <div class="row items-center q-mb-xs">
                <div class="femsq-section-title col">Агенты · САК · филиалы</div>
                <QBtn
                  flat
                  dense
                  no-caps
                  color="primary"
                  icon="add"
                  label="Агент"
                  :disable="!store.selectedCstKey"
                  @click="openAgentDialog()"
                />
              </div>

              <div class="agents-tree" data-test="cst-agents-tree">
                <QInnerLoading :showing="store.loadingAgents">
                  <QSpinner color="primary" size="2em" />
                </QInnerLoading>

                <table class="tree-table">
                  <thead>
                    <tr>
                      <th class="col-expand" />
                      <th class="col-label">Значение</th>
                      <th class="col-meta">Ключ</th>
                      <th class="col-meta">Доп.</th>
                      <th class="col-actions" />
                    </tr>
                  </thead>
                  <tbody>
                    <template v-if="store.agents.length === 0 && !store.loadingAgents">
                      <tr>
                        <td colspan="5" class="empty-cell">Нет агентов</td>
                      </tr>
                    </template>

                    <template v-for="agent in store.agents" :key="'a-' + agent.cstaKey">
                      <tr
                        class="tree-row tree-row--l1"
                        :class="{
                          'tree-row--focus': store.selectedCode?.cstapCsta === agent.cstaKey
                        }"
                      >
                        <td class="col-expand">
                          <QBtn
                            flat
                            dense
                            size="sm"
                            :icon="store.isAgentExpanded(agent.cstaKey) ? 'expand_more' : 'chevron_right'"
                            :loading="store.isLoadingPoints(agent.cstaKey)"
                            @click="store.toggleAgent(agent.cstaKey)"
                          />
                        </td>
                        <td class="col-label">
                          <span class="level-tag">агент</span>
                          {{ agent.agentLabel || agent.cstaAg }}
                        </td>
                        <td class="col-meta">{{ agent.cstaKey }}</td>
                        <td class="col-meta">cstaAg={{ agent.cstaAg }}</td>
                        <td class="col-actions">
                          <QBtn flat dense icon="add" size="sm" @click="openPointDialog(undefined, agent.cstaKey)" />
                          <QBtn flat dense icon="edit" size="sm" @click="openAgentDialog(agent)" />
                          <QBtn
                            flat
                            dense
                            icon="delete"
                            size="sm"
                            color="negative"
                            @click="confirmDeleteAgent(agent)"
                          />
                        </td>
                      </tr>

                      <template v-if="store.isAgentExpanded(agent.cstaKey)">
                        <template v-if="(store.pointsByCsta[agent.cstaKey] || []).length === 0">
                          <tr class="tree-row tree-row--l2">
                            <td />
                            <td colspan="4" class="empty-cell">Нет САК</td>
                          </tr>
                        </template>
                        <template
                          v-for="point in store.pointsByCsta[agent.cstaKey] || []"
                          :key="'p-' + point.cstapKey"
                        >
                          <tr
                            class="tree-row tree-row--l2"
                            :class="{
                              'tree-row--focus': store.selectedCodeKey === point.cstapKey
                            }"
                          >
                            <td class="col-expand">
                              <QBtn
                                flat
                                dense
                                size="sm"
                                :icon="store.isPointExpanded(point.cstapKey) ? 'expand_more' : 'chevron_right'"
                                :loading="store.isLoadingBranches(point.cstapKey)"
                                @click="store.togglePoint(point.cstapKey)"
                              />
                            </td>
                            <td class="col-label">
                              <span class="level-tag">САК</span>
                              {{ point.cstapIpgPnN }}
                            </td>
                            <td class="col-meta">{{ point.cstapKey }}</td>
                            <td class="col-meta" />
                            <td class="col-actions">
                              <QBtn
                                flat
                                dense
                                icon="add"
                                size="sm"
                                @click="openBranchDialog(undefined, point.cstapKey)"
                              />
                              <QBtn
                                flat
                                dense
                                icon="edit"
                                size="sm"
                                @click="openPointDialog(point, agent.cstaKey)"
                              />
                              <QBtn
                                flat
                                dense
                                icon="delete"
                                size="sm"
                                color="negative"
                                @click="confirmDeletePoint(point, agent.cstaKey)"
                              />
                            </td>
                          </tr>

                          <template v-if="store.isPointExpanded(point.cstapKey)">
                            <template v-if="(store.branchesByCstap[point.cstapKey] || []).length === 0">
                              <tr class="tree-row tree-row--l3">
                                <td />
                                <td colspan="4" class="empty-cell">Нет филиалов</td>
                              </tr>
                            </template>
                            <tr
                              v-for="branch in store.branchesByCstap[point.cstapKey] || []"
                              :key="'b-' + branch.cstapbKey"
                              class="tree-row tree-row--l3"
                            >
                              <td class="col-expand" />
                              <td class="col-label">
                                <span class="level-tag">филиал</span>
                                {{ branch.branchName || branch.cstapbBranch }}
                              </td>
                              <td class="col-meta">{{ branch.cstapbKey }}</td>
                              <td class="col-meta">
                                {{ formatPeriod(branch.cstapbStart, branch.cstapbEnd) }}
                              </td>
                              <td class="col-actions">
                                <QBtn
                                  flat
                                  dense
                                  icon="edit"
                                  size="sm"
                                  @click="openBranchDialog(branch, point.cstapKey)"
                                />
                                <QBtn
                                  flat
                                  dense
                                  icon="delete"
                                  size="sm"
                                  color="negative"
                                  @click="confirmDeleteBranch(branch, point.cstapKey)"
                                />
                              </td>
                            </tr>
                          </template>
                        </template>
                      </template>
                    </template>
                  </tbody>
                </table>
              </div>
            </QTabPanel>
            <QTabPanel name="reports" class="q-pa-none">
              <CstReportsTab />
            </QTabPanel>
            <QTabPanel name="rent" class="q-pa-none">
              <CstRentReportsTab />
            </QTabPanel>
          </QTabPanels>
        </template>
        <div v-else class="text-grey-7 q-pa-md">Выберите код САК слева.</div>
      </div>
    </div>

    <!-- Dialogs (same as cst form) -->
    <QDialog v-model="agentDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">{{ agentDialog.id == null ? 'Новый агент' : 'Агент' }}</QCardSection>
        <QCardSection>
          <QSelect
            v-model="agentDialog.cstaAg"
            :options="agentOptions"
            emit-value
            map-options
            use-input
            input-debounce="200"
            @filter="filterAgents"
            label="Агент (ogAgCs) *"
            dense
            options-dense
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn flat dense no-caps color="primary" label="Сохранить" :loading="store.saving" @click="saveAgent" />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="pointDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">{{ pointDialog.id == null ? 'Новый САК' : 'САК' }}</QCardSection>
        <QCardSection>
          <QInput v-model="pointDialog.cstapIpgPnN" label="cstapIpgPnN *" dense autofocus />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn flat dense no-caps color="primary" label="Сохранить" :loading="store.saving" @click="savePoint" />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="branchDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">{{ branchDialog.id == null ? 'Новый филиал' : 'Филиал' }}</QCardSection>
        <QCardSection class="q-gutter-sm">
          <QSelect
            v-model="branchDialog.cstapbBranch"
            :options="orgOptions"
            emit-value
            map-options
            use-input
            input-debounce="200"
            @filter="filterOrgs"
            label="Филиал (og) *"
            dense
            options-dense
          />
          <QInput v-model="branchDialog.cstapbStart" label="cstapbStart (YYYY-MM-DD)" dense />
          <QInput v-model="branchDialog.cstapbEnd" label="cstapbEnd (YYYY-MM-DD)" dense />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn flat dense no-caps color="primary" label="Сохранить" :loading="store.saving" @click="saveBranch" />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInnerLoading,
  QInput,
  QItem,
  QItemLabel,
  QItemSection,
  QList,
  QPage,
  QSelect,
  QSpinner,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  useQuasar
} from 'quasar';

import { useConstructionSitesStore } from '@/stores/construction-sites';
import type {
  CstAgPnBranchDto,
  CstAgPnCodeDto,
  CstAgPointDto,
  CstAgentDto
} from '@/types/construction-sites';
import CstReportsTab from '@/views/construction-sites/CstReportsTab.vue';
import CstRentReportsTab from '@/views/construction-sites/CstRentReportsTab.vue';

/**
 * Форма Access {@code cstAgPn}: список кодов слева, справа — каркас стройки (cst) по {@code cstaCst}.
 */
const store = useConstructionSitesStore();
const $q = useQuasar();

const codeFilter = ref('');
const activeTab = ref('agents');

const agentDialog = reactive<{ open: boolean; id: number | null; cstaAg: number | null }>({
  open: false,
  id: null,
  cstaAg: null
});
const pointDialog = reactive<{
  open: boolean;
  id: number | null;
  parentCstaKey: number | null;
  cstapIpgPnN: string;
}>({
  open: false,
  id: null,
  parentCstaKey: null,
  cstapIpgPnN: ''
});
const branchDialog = reactive<{
  open: boolean;
  id: number | null;
  parentCstapKey: number | null;
  cstapbBranch: number | null;
  cstapbStart: string;
  cstapbEnd: string;
}>({
  open: false,
  id: null,
  parentCstapKey: null,
  cstapbBranch: null,
  cstapbStart: '',
  cstapbEnd: ''
});

const agentOptions = ref<{ label: string; value: number }[]>([]);
const orgOptions = ref<{ label: string; value: number }[]>([]);

onMounted(() => {
  void store.loadCodes();
});

function reloadCodes(): void {
  void store.loadCodes(codeFilter.value);
}

function onFilterChange(value: string | number | null): void {
  void store.loadCodes(value == null ? '' : String(value));
}

function onSelectCode(entry: CstAgPnCodeDto): void {
  void store.selectCode(entry);
}

function formatPeriod(start?: string | null, end?: string | null): string {
  if (!start && !end) {
    return '';
  }
  return `${start ?? '…'} — ${end ?? '…'}`;
}

function openAgentDialog(row?: CstAgentDto): void {
  agentDialog.id = row?.cstaKey ?? null;
  agentDialog.cstaAg = row?.cstaAg ?? null;
  agentOptions.value = store.agentLookups.map((item) => ({ label: item.ogaNm, value: item.ogaKey }));
  agentDialog.open = true;
}

function filterAgents(val: string, update: (fn: () => void) => void): void {
  update(() => {
    const needle = val.toLowerCase();
    agentOptions.value = store.agentLookups
      .filter((item) => item.ogaNm.toLowerCase().includes(needle))
      .map((item) => ({ label: item.ogaNm, value: item.ogaKey }));
  });
}

async function saveAgent(): Promise<void> {
  if (store.selectedCstKey == null || agentDialog.cstaAg == null) {
    $q.notify({ type: 'warning', message: 'Выберите агента' });
    return;
  }
  await store.saveAgent(
    { cstaAg: agentDialog.cstaAg, cstaCst: store.selectedCstKey },
    agentDialog.id ?? undefined
  );
  agentDialog.open = false;
}

function confirmDeleteAgent(row: CstAgentDto): void {
  $q.dialog({
    title: 'Удалить агента?',
    message: `${row.agentLabel ?? row.cstaAg}`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    if (store.selectedCstKey != null) {
      void store.removeAgent(row.cstaKey, store.selectedCstKey);
    }
  });
}

function openPointDialog(row?: CstAgPointDto, parentCstaKey?: number): void {
  pointDialog.id = row?.cstapKey ?? null;
  pointDialog.parentCstaKey = row?.cstapCsta ?? parentCstaKey ?? null;
  pointDialog.cstapIpgPnN = row?.cstapIpgPnN ?? '';
  pointDialog.open = true;
}

async function savePoint(): Promise<void> {
  if (pointDialog.parentCstaKey == null || !pointDialog.cstapIpgPnN.trim()) {
    $q.notify({ type: 'warning', message: 'Укажите код САК' });
    return;
  }
  await store.savePoint(
    { cstapCsta: pointDialog.parentCstaKey, cstapIpgPnN: pointDialog.cstapIpgPnN.trim() },
    pointDialog.id ?? undefined
  );
  pointDialog.open = false;
  void store.loadCodes(codeFilter.value);
}

function confirmDeletePoint(row: CstAgPointDto, cstaKey: number): void {
  $q.dialog({
    title: 'Удалить САК?',
    message: row.cstapIpgPnN,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removePoint(row.cstapKey, cstaKey).then(() => store.loadCodes(codeFilter.value));
  });
}

function openBranchDialog(row?: CstAgPnBranchDto, parentCstapKey?: number): void {
  branchDialog.id = row?.cstapbKey ?? null;
  branchDialog.parentCstapKey = row?.cstapbCstAgPn ?? parentCstapKey ?? null;
  branchDialog.cstapbBranch = row?.cstapbBranch ?? null;
  branchDialog.cstapbStart = row?.cstapbStart ?? '';
  branchDialog.cstapbEnd = row?.cstapbEnd ?? '';
  orgOptions.value = store.organizationLookups.map((item) => ({ label: item.ogNm, value: item.ogKey }));
  branchDialog.open = true;
}

function filterOrgs(val: string, update: (fn: () => void) => void): void {
  update(() => {
    const needle = val.toLowerCase();
    orgOptions.value = store.organizationLookups
      .filter((item) => item.ogNm.toLowerCase().includes(needle))
      .map((item) => ({ label: item.ogNm, value: item.ogKey }));
  });
}

async function saveBranch(): Promise<void> {
  if (branchDialog.parentCstapKey == null || branchDialog.cstapbBranch == null) {
    $q.notify({ type: 'warning', message: 'Выберите филиал' });
    return;
  }
  await store.saveBranch(
    {
      cstapbCstAgPn: branchDialog.parentCstapKey,
      cstapbBranch: branchDialog.cstapbBranch,
      cstapbStart: branchDialog.cstapbStart.trim() || null,
      cstapbEnd: branchDialog.cstapbEnd.trim() || null
    },
    branchDialog.id ?? undefined
  );
  branchDialog.open = false;
}

function confirmDeleteBranch(row: CstAgPnBranchDto, cstapKey: number): void {
  $q.dialog({
    title: 'Удалить филиал?',
    message: `${row.branchName ?? row.cstapbBranch}`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeBranch(row.cstapbKey, cstapKey);
  });
}
</script>

<style scoped>
.cst-by-code-view {
  max-width: 1400px;
}

.codes-panel {
  border: 1px solid var(--femsq-border, rgba(127, 127, 127, 0.35));
  border-radius: var(--femsq-control-radius, 4px);
  padding: 10px;
}

.codes-list {
  position: relative;
  max-height: min(70vh, 640px);
  overflow: auto;
  border-radius: var(--femsq-control-radius, 4px);
}

.codes-list__active {
  background: var(--femsq-item-active-bg);
  color: var(--femsq-primary);
}

.code-context {
  font-size: var(--femsq-content-body-size);
}

.code-context__label {
  color: var(--femsq-text-muted);
  margin-right: 8px;
}

.code-context__value {
  color: var(--q-primary);
  font-weight: 600;
}

.name-context {
  padding: 8px 10px;
  border-radius: var(--femsq-control-radius, 4px);
  background: color-mix(in srgb, var(--q-primary) 18%, transparent);
  border: 1px solid color-mix(in srgb, var(--q-primary) 35%, transparent);
  word-break: break-word;
  line-height: 1.35;
  font-size: var(--femsq-content-body-size);
}

.agents-tree {
  position: relative;
  min-height: 120px;
  border: 1px solid var(--femsq-border, rgba(127, 127, 127, 0.35));
  border-radius: var(--femsq-control-radius, 4px);
  overflow: auto;
}

.tree-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--femsq-content-body-size);
}

.tree-table th,
.tree-table td {
  padding: 4px 8px;
  border-bottom: 1px solid var(--femsq-border, rgba(127, 127, 127, 0.25));
  text-align: left;
  vertical-align: middle;
  font-size: var(--femsq-content-body-size);
}

.tree-table th {
  font-weight: 600;
  color: var(--femsq-text-muted, inherit);
  position: sticky;
  top: 0;
  z-index: 1;
}

.col-expand {
  width: 40px;
}

.col-meta {
  width: 120px;
  white-space: nowrap;
  color: var(--femsq-text-muted, inherit);
  font-variant-numeric: tabular-nums;
}

.col-actions {
  width: 120px;
  white-space: nowrap;
  text-align: right;
}

.tree-row--l2 .col-label {
  padding-left: 28px;
}

.tree-row--l3 .col-label {
  padding-left: 56px;
}

.tree-row--l2 .col-expand {
  padding-left: 20px;
}

.tree-row--l3 .col-expand {
  padding-left: 40px;
}

.tree-row--focus {
  background: var(--femsq-item-active-bg);
}

.level-tag {
  display: inline-block;
  min-width: 3.5rem;
  margin-right: 6px;
  font-size: var(--femsq-content-caption-size);
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--q-primary);
  opacity: 0.85;
}

.empty-cell {
  color: var(--femsq-text-muted, inherit);
  font-style: italic;
}

.dialog-card {
  min-width: min(480px, 92vw);
  border-radius: var(--femsq-control-radius, 4px);
}

.dialog-title {
  font-size: var(--femsq-content-title-size);
  font-weight: 600;
  line-height: 1.3;
}
</style>
