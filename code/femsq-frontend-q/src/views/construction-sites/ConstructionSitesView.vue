<template>
  <QPage class="construction-sites-view q-pa-md column no-wrap" data-test="construction-sites-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Стройки</div>
        <div class="femsq-page-subtitle">Форма Access <code>cst</code> · агенты / отчёты</div>
      </div>
      <QBtn
        flat
        dense
        icon="refresh"
        :loading="store.loadingSites"
        aria-label="Обновить"
        @click="store.loadSites()"
      />
      <QBtn
        flat
        dense
        no-caps
        color="primary"
        icon="add"
        label="Стройка"
        data-test="cst-add-site"
        @click="openSiteDialog()"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>
      {{ store.error }}
    </QBanner>

    <QSplitter
      v-if="store.selectedSite"
      v-model="masterSplit"
      horizontal
      :limits="[15, 70]"
      separator-class="cst-split-sep"
      class="cst-main-splitter"
      data-test="cst-main-splitter"
    >
      <template #before>
        <section class="master-block fill-pane" data-test="cst-master">
          <FemsqTable
            class="master-table"
            root-class="master-table"
            row-key="cstKey"
            :rows="store.sites"
            :columns="siteColumns"
            :loading="store.loadingSites"
            v-model:filter="siteFilter"
            v-model:pagination="sitePagination"
            filter-label="Фильтр по имени / cstKey"
            filter-test-id="cst-site-filter"
            selection="single"
            v-model:selected="selectedSiteRows"
            @row-click="onSiteRowClick"
          >
            <template #body-cell-cstName="slotProps">
              <QTd :props="slotProps" class="master-name-cell">
                {{ slotProps.row.cstName }}
              </QTd>
            </template>
            <template #body-cell-actions="slotProps">
              <QTd :props="slotProps" auto-width>
                <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click.stop="openSiteDialog(slotProps.row)" />
                <QBtn
                  flat
                  dense
                  icon="delete"
                  size="sm"
                  color="negative"
                  aria-label="Удалить"
                  @click.stop="confirmDeleteSite(slotProps.row)"
                />
              </QTd>
            </template>
          </FemsqTable>

          <div v-if="store.selectedSite" class="name-context q-mt-sm" data-test="cst-name-context">
            {{ store.selectedSite.cstName }}
            <span class="text-caption femsq-text-muted q-ml-sm">cstKey={{ store.selectedSite.cstKey }}</span>
          </div>
        </section>
      </template>

      <template #after>
        <div class="detail-pane fill-pane column no-wrap">
          <QTabs v-model="activeTab" dense align="left" class="q-mb-sm" data-test="cst-tabs">
            <QTab name="agents" label="агенты" />
            <QTab name="reports" label="отчёты" />
            <QTab name="rent" label="отчёты, аренда" />
            <QTab name="ipg" label="инвестпрограммы" disable />
            <QTab name="common" label="общее" disable />
            <QTab name="osv" label="освоение" disable />
            <QTab name="chart-total" label="график, всего" disable />
            <QTab name="chart-types" label="график, виды" disable />
          </QTabs>

          <QTabPanels v-model="activeTab" class="detail-tab-panels col">
            <QTabPanel name="agents" class="q-pa-none fill-pane column no-wrap">
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

              <div class="agents-tree col" data-test="cst-agents-tree">
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
                    <td colspan="5" class="empty-cell">Нет агентов. Добавьте первого.</td>
                  </tr>
                </template>

                <template v-for="agent in store.agents" :key="'a-' + agent.cstaKey">
                  <tr
                    class="tree-row tree-row--l1"
                    :class="{ 'tree-row--expanded': store.isAgentExpanded(agent.cstaKey) }"
                  >
                    <td class="col-expand">
                      <QBtn
                        flat
                        dense
                        size="sm"
                        :icon="store.isAgentExpanded(agent.cstaKey) ? 'expand_more' : 'chevron_right'"
                        :loading="store.isLoadingPoints(agent.cstaKey)"
                        aria-label="Раскрыть агента"
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
                      <QBtn flat dense icon="add" size="sm" aria-label="Добавить САК" @click="openPointDialog(undefined, agent.cstaKey)" />
                      <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click="openAgentDialog(agent)" />
                      <QBtn flat dense icon="delete" size="sm" color="negative" aria-label="Удалить" @click="confirmDeleteAgent(agent)" />
                    </td>
                  </tr>

                  <template v-if="store.isAgentExpanded(agent.cstaKey)">
                    <template v-if="(store.pointsByCsta[agent.cstaKey] || []).length === 0">
                      <tr class="tree-row tree-row--l2 tree-row--empty">
                        <td />
                        <td colspan="4" class="empty-cell">Нет САК</td>
                      </tr>
                    </template>
                    <template v-for="point in store.pointsByCsta[agent.cstaKey] || []" :key="'p-' + point.cstapKey">
                      <tr
                        class="tree-row tree-row--l2"
                        :class="{ 'tree-row--expanded': store.isPointExpanded(point.cstapKey) }"
                      >
                        <td class="col-expand">
                          <QBtn
                            flat
                            dense
                            size="sm"
                            :icon="store.isPointExpanded(point.cstapKey) ? 'expand_more' : 'chevron_right'"
                            :loading="store.isLoadingBranches(point.cstapKey)"
                            aria-label="Раскрыть САК"
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
                            aria-label="Добавить филиал"
                            @click="openBranchDialog(undefined, point.cstapKey)"
                          />
                          <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click="openPointDialog(point, agent.cstaKey)" />
                          <QBtn
                            flat
                            dense
                            icon="delete"
                            size="sm"
                            color="negative"
                            aria-label="Удалить"
                            @click="confirmDeletePoint(point, agent.cstaKey)"
                          />
                        </td>
                      </tr>

                      <template v-if="store.isPointExpanded(point.cstapKey)">
                        <template v-if="(store.branchesByCstap[point.cstapKey] || []).length === 0">
                          <tr class="tree-row tree-row--l3 tree-row--empty">
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
                              aria-label="Изменить"
                              @click="openBranchDialog(branch, point.cstapKey)"
                            />
                            <QBtn
                              flat
                              dense
                              icon="delete"
                              size="sm"
                              color="negative"
                              aria-label="Удалить"
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
        <QTabPanel name="reports" class="q-pa-none fill-pane">
          <CstReportsTab />
        </QTabPanel>
        <QTabPanel name="rent" class="q-pa-none fill-pane">
          <CstRentReportsTab />
        </QTabPanel>
          </QTabPanels>
        </div>
      </template>
    </QSplitter>

    <section v-else class="master-block" data-test="cst-master">
      <FemsqTable
        class="master-table"
        root-class="master-table"
        row-key="cstKey"
        :rows="store.sites"
        :columns="siteColumns"
        :loading="store.loadingSites"
        v-model:filter="siteFilter"
        v-model:pagination="sitePagination"
        filter-label="Фильтр по имени / cstKey"
        filter-test-id="cst-site-filter"
        selection="single"
        v-model:selected="selectedSiteRows"
        @row-click="onSiteRowClick"
      >
        <template #body-cell-cstName="slotProps">
          <QTd :props="slotProps" class="master-name-cell">
            {{ slotProps.row.cstName }}
          </QTd>
        </template>
        <template #body-cell-actions="slotProps">
          <QTd :props="slotProps" auto-width>
            <QBtn flat dense icon="edit" size="sm" aria-label="Изменить" @click.stop="openSiteDialog(slotProps.row)" />
            <QBtn
              flat
              dense
              icon="delete"
              size="sm"
              color="negative"
              aria-label="Удалить"
              @click.stop="confirmDeleteSite(slotProps.row)"
            />
          </QTd>
        </template>
      </FemsqTable>
      <div class="text-caption femsq-text-muted q-mt-sm">Выберите стройку, чтобы открыть вкладки.</div>
    </section>

    <!-- Dialogs -->
    <QDialog v-model="siteDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">{{ siteDialog.id == null ? 'Новая стройка' : 'Стройка' }}</QCardSection>
        <QCardSection>
          <QInput v-model="siteDialog.cstName" label="cstName *" dense autofocus type="textarea" autogrow />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn flat dense no-caps color="primary" label="Сохранить" :loading="store.saving" @click="saveSite" />
        </QCardActions>
      </QCard>
    </QDialog>

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
import { onMounted, reactive, ref, watch } from 'vue';

import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInnerLoading,
  QInput,
  QPage,
  QSelect,
  QSpinner,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QTd,
  useQuasar,
  type QTableProps
} from 'quasar';

import { FemsqTable, actionsColumn, type FemsqTableColumn } from 'fequlib';
import { useConstructionSitesStore } from '@/stores/construction-sites';
import type {
  ConstructionSiteDto,
  CstAgPnBranchDto,
  CstAgPointDto,
  CstAgentDto
} from '@/types/construction-sites';
import CstReportsTab from '@/views/construction-sites/CstReportsTab.vue';
import CstRentReportsTab from '@/views/construction-sites/CstRentReportsTab.vue';
/**
 * Экран «Стройки»: master сверху (как Access), дерево агент→САК→филиал с multi-expand.
 */
const store = useConstructionSitesStore();
const $q = useQuasar();

const siteFilter = ref('');
const activeTab = ref('agents');
const selectedSiteRows = ref<ConstructionSiteDto[]>([]);
const MASTER_SPLIT_KEY = 'femsq.cst.masterSplit';
const masterSplit = ref(readSplit(MASTER_SPLIT_KEY, 32));
watch(masterSplit, (value) => {
  localStorage.setItem(MASTER_SPLIT_KEY, String(value));
});

function readSplit(key: string, fallback: number): number {
  const raw = localStorage.getItem(key);
  if (raw == null) {
    return fallback;
  }
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

const sitePagination = ref<QTableProps['pagination']>({
  page: 1,
  rowsPerPage: 8,
  sortBy: 'cstName',
  descending: false
});

const siteDialog = reactive<{ open: boolean; id: number | null; cstName: string }>({
  open: false,
  id: null,
  cstName: ''
});
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

const siteColumns: FemsqTableColumn<ConstructionSiteDto>[] = [
  {
    name: 'cstName',
    label: 'cstName',
    field: 'cstName',
    align: 'left',
    sortable: true,
    filterValue: (row) => String(row.cstName ?? '')
  },
  { name: 'cstKey', label: 'cstKey', field: 'cstKey', align: 'right', style: 'width: 88px' },
  actionsColumn({ style: 'width: 88px' })
];

watch(
  () => store.selectedSite,
  (site) => {
    selectedSiteRows.value = site ? [site] : [];
  }
);

onMounted(() => {
  void store.loadSites();
});

function formatPeriod(start?: string | null, end?: string | null): string {
  if (!start && !end) {
    return '';
  }
  return `${start ?? '…'} — ${end ?? '…'}`;
}

function onSiteRowClick(_evt: Event, row: ConstructionSiteDto): void {
  void store.selectSite(row.cstKey);
}

function openSiteDialog(row?: ConstructionSiteDto): void {
  siteDialog.id = row?.cstKey ?? null;
  siteDialog.cstName = row?.cstName ?? '';
  siteDialog.open = true;
}

async function saveSite(): Promise<void> {
  const name = siteDialog.cstName.trim();
  if (!name) {
    $q.notify({ type: 'warning', message: 'Укажите наименование стройки' });
    return;
  }
  await store.saveSite({ cstName: name }, siteDialog.id ?? undefined);
  siteDialog.open = false;
}

function confirmDeleteSite(row: ConstructionSiteDto): void {
  $q.dialog({
    title: 'Удалить стройку?',
    message: `${row.cstName} (cstKey=${row.cstKey})`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeSite(row.cstKey);
  });
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
    message: `${row.agentLabel ?? row.cstaAg} (cstaKey=${row.cstaKey})`,
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
}

function confirmDeletePoint(row: CstAgPointDto, cstaKey: number): void {
  $q.dialog({
    title: 'Удалить САК?',
    message: `${row.cstapIpgPnN} (cstapKey=${row.cstapKey})`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removePoint(row.cstapKey, cstaKey);
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
    message: `${row.branchName ?? row.cstapbBranch} (cstapbKey=${row.cstapbKey})`,
    cancel: true,
    persistent: true
  }).onOk(() => {
    void store.removeBranch(row.cstapbKey, cstapKey);
  });
}
</script>

<style scoped>
.construction-sites-view {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap; /* Quasar .column по умолчанию wrap → при height лимит уезжает во 2-ю колонку */
  align-items: stretch;
  width: 100%;
  /* Явная высота нужна QSplitter; box-sizing включает q-pa-md в лимит */
  height: calc(100vh - 40px - 28px);
  max-height: calc(100vh - 40px - 28px);
  min-height: 0 !important;
  overflow: hidden;
  box-sizing: border-box;
}

.cst-main-splitter {
  flex: 1 1 auto;
  min-height: 0;
  width: 100%;
}

/* Панели splitter режут контент; скролл только внутри таблиц/деревьев */
.cst-main-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  width: 100%;
}

.fill-pane {
  width: 100%;
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.detail-pane {
  min-height: 0;
  padding-left: 2px;
  overflow: hidden;
  flex-wrap: nowrap;
}

.detail-tab-panels {
  min-height: 0;
  overflow: hidden;
}

.detail-tab-panels :deep(.q-panel),
.detail-tab-panels :deep(.q-tab-panel) {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.cst-split-sep {
  background: var(--femsq-border, rgba(127, 127, 127, 0.45));
}

.cst-main-splitter :deep(.q-splitter__separator) {
  height: 5px;
  background: transparent;
}

.cst-main-splitter :deep(.q-splitter__separator-area) {
  height: 5px;
  background: color-mix(in srgb, var(--q-primary) 35%, var(--femsq-border, #666));
  border-radius: 2px;
  opacity: 0.85;
}

.cst-main-splitter :deep(.q-splitter__separator-area:hover) {
  opacity: 1;
  background: var(--q-primary);
}

.master-block {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  width: 100%;
  border: 1px solid var(--femsq-border, rgba(127, 127, 127, 0.35));
  border-radius: var(--femsq-control-radius, 4px);
  padding: 10px 12px;
  box-sizing: border-box;
  min-height: 0;
  overflow: hidden;
}

.master-table {
  flex: 1 1 auto;
  min-height: 0;
  height: 0;
}

.master-table :deep(.master-name-cell) {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 0;
}

.master-table :deep(td.master-name-cell),
.master-table :deep(.q-td.master-name-cell) {
  max-width: 48rem;
}

.name-context {
  padding: 8px 10px;
  border-radius: var(--femsq-control-radius, 4px);
  background: color-mix(in srgb, var(--q-primary) 18%, transparent);
  border: 1px solid color-mix(in srgb, var(--q-primary) 35%, transparent);
  white-space: normal;
  word-break: break-word;
  line-height: 1.35;
  font-size: var(--femsq-content-body-size);
}

.agents-tree {
  position: relative;
  min-height: 0;
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
  background: color-mix(in srgb, var(--femsq-surface, transparent) 80%, black);
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
