<template>
  <!-- absolute-full на внутреннем div, как на экране «Загрузка свода» — иначе шапка с «Назад» обрезается -->
  <QPage class="q-pa-none sudz-sf-page" data-test="sudz-sf-double-view">
    <div class="absolute-full q-pa-md column no-wrap sudz-sf-page-inner">
      <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
        <QBtn
          color="primary"
          unelevated
          dense
          no-caps
          icon="arrow_back"
          label="К загрузке свода"
          data-test="sudz-sf-double-back"
          @click="goBack"
        />
        <div class="text-h6 col">Разбор СФ с совпадающими номерами</div>
        <div class="text-caption text-grey-6 shrink-0">
          upl={{ uplKey ?? '—' }} · очередь {{ rows.length }} · open {{ openCount }}
        </div>
      </div>

      <div v-if="!uplKey" class="text-grey-6">Выберите выгрузку на экране «Загрузка свода».</div>
      <div v-else-if="error" class="text-negative">{{ error }}</div>

      <QSplitter
        v-else
        v-model="queueSplit"
        :limits="[15, 40]"
        separator-class="sudz-split-sep"
        class="col sudz-sf-splitter"
      >
      <template #before>
        <div class="column fill-pane no-wrap q-pa-sm">
          <FemsqTable
            class="col"
            :rows="rows"
            :columns="queueColumns"
            row-key="ciusKey"
            dense
            flat
            :loading="loading"
            selection="single"
            v-model:selected="selectedRows"
            data-test="sudz-sf-double-queue"
          />
          <div class="row items-center q-gutter-sm q-pt-sm shrink-0">
            <QBtn
              color="primary"
              unelevated
              dense
              no-caps
              label="Создать СФ по Excel"
              :disable="!canCreate"
              :loading="creating"
              data-test="sudz-sf-double-create"
              @click="onCreate"
            />
            <div class="text-caption text-grey-6">
              Перепривязка — вручную в «Договоры» (позже).
            </div>
          </div>
        </div>
      </template>

      <template #after>
        <QSplitter
          v-model="ksdsfSplit"
          :limits="[25, 50]"
          separator-class="sudz-split-sep"
          class="fit sudz-sf-splitter"
        >
          <template #before>
            <div class="column fill-pane no-wrap q-pa-sm">
              <div class="text-subtitle2 q-mb-sm shrink-0">Excel · кандидат</div>
              <div v-if="!selected" class="text-grey-6">Выберите строку очереди.</div>
              <div v-else-if="excelLoading" class="text-grey-6">Загрузка…</div>
              <div v-else-if="!excel" class="text-grey-6">Строка Tbl не найдена.</div>
              <QMarkupTable v-else dense flat bordered class="col overflow-auto">
                <tbody>
                  <tr v-for="row in excelRows" :key="row.label">
                    <td class="text-grey-6" style="width: 40%">{{ row.label }}</td>
                    <td>{{ row.value }}</td>
                  </tr>
                </tbody>
              </QMarkupTable>
            </div>
          </template>

          <template #after>
            <div class="column fill-pane no-wrap q-pa-sm">
              <QTabs v-model="domainTab" dense class="shrink-0" active-color="primary">
                <QTab name="sf" label="Счета-фактуры" no-caps />
                <QTab name="sums" label="Суммы" no-caps disable />
              </QTabs>
              <QTabPanels v-model="domainTab" class="col column no-wrap" animated>
                <QTabPanel name="sf" class="q-pa-none column fill-pane no-wrap">
                  <QSplitter
                    v-model="domainSplit"
                    horizontal
                    :limits="[25, 70]"
                    separator-class="sudz-split-sep"
                    class="col sudz-sf-splitter"
                  >
                    <template #before>
                      <FemsqTable
                        class="fit"
                        :rows="domainMatches"
                        :columns="domainColumns"
                        row-key="rowKey"
                        dense
                        flat
                        :loading="domainLoading"
                        selection="single"
                        v-model:selected="selectedDomain"
                        data-test="sudz-sf-domain-list"
                      />
                    </template>
                    <template #after>
                      <div class="q-pa-sm overflow-auto column fill-pane no-wrap">
                        <div v-if="!selectedDomain[0]" class="text-grey-6">
                          Выберите СФ в списке совпадений.
                        </div>
                        <RelationTree
                          v-else
                          :key="relationTreeKey"
                          class="col"
                          :spec="relationSpec"
                          :root-id="selectedDomain[0].invNumKey"
                          :fetch-node="fetchRelationNode"
                          :fetch-expand="fetchRelationExpand"
                          @action="onRelationAction"
                          data-test="sf-double-tree"
                          root-class="sudz-sf-double-tree"
                        />
                      </div>
                    </template>
                  </QSplitter>
                </QTabPanel>
                <QTabPanel name="sums" class="q-pa-md text-grey-6">
                  Вкладка «суммы» — отдельное ТЗ (S68).
                </QTabPanel>
              </QTabPanels>
            </div>
          </template>
        </QSplitter>
      </template>
      </QSplitter>
    </div>
    <RecordModal
      v-if="linkForm"
      v-model="linkModalOpen"
      :form="linkForm"
      :fetch-node="fetchRelationNode"
      :fetch-expand="fetchRelationExpand"
      :save-error="linkSaveError"
      :save-loading="linkSaveLoading"
      @picker-select="onPickerSelect"
      @save="onLinkSave"
    />
  </QPage>
</template>

<script setup lang="ts">
/**
 * Экран КСДСФ: разбор СФ с совпадающими номерами (S68).
 */
import { computed, onMounted, ref, watch } from 'vue';

import { FemsqTable, type FemsqTableColumn } from 'fequlib';
import { deleteCnInv, fetchCnNums, updateCnInv } from '@/api/contracts-api';
import RecordModal from '@/components/relation/RecordModal.vue';
import RelationTree from '@/components/relation/RelationTree.vue';
import {
  createSudzSfFromDouble,
  getSudzSfDoubleDomainMatches,
  getSudzSfDoubleExcelCandidate,
  linkSudzSfDoubleToCn
} from '@/api/sudz-api';
import { fetchRelationExpand, fetchRelationNode } from '@/api/relation-api';
import { useConnectionStore } from '@/stores/connection';
import { useSudzDbtUplStore } from '@/stores/sudz-dbt-upl';
import type {
  SudzCnInvUplSfDouble,
  SudzSfDoubleDomainMatch,
  SudzSfDoubleExcelCandidate
} from '@/types/sudz';
import * as cnPickerSpecJson from '@/trees/cn-picker.tree.json';
import * as contractsInvSpecJson from '@/trees/contracts-inv.tree.json';
import * as ksdsfSpec from '@/trees/ksdsf-inv-num.tree.json';
import { buildCnInvLinkForm } from '@/trees/relation-form-registry';
import type { RelationFormState, RelationPickerRow } from '@/trees/relation-forms';
import type { RelationTreeActionContext, RelationTreeSpec } from '@/trees/relation-tree';
import {
  QBtn,
  QMarkupTable,
  QPage,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  useQuasar
} from 'quasar';

type DomainRow = SudzSfDoubleDomainMatch & { rowKey: string };
type PickerCandidateRow = RelationPickerRow & {
  rowKey: string;
  cnKey?: number | null;
  cnNum?: string | null;
  invKey?: number | null;
  invNum?: string | null;
};

const relationSpec = ksdsfSpec as RelationTreeSpec;
const cnPickerSpec = cnPickerSpecJson as RelationTreeSpec;
const contractsInvSpec = contractsInvSpecJson as RelationTreeSpec;

const connection = useConnectionStore();
const store = useSudzDbtUplStore();
const $q = useQuasar();

const queueSplit = ref(22);
const ksdsfSplit = ref(34);
const domainSplit = ref(45);
const domainTab = ref('sf');
const loading = ref(false);
const creating = ref(false);
const excelLoading = ref(false);
const domainLoading = ref(false);
const error = ref<string | null>(null);
const selectedRows = ref<SudzCnInvUplSfDouble[]>([]);
const excel = ref<SudzSfDoubleExcelCandidate | null>(null);
const domainMatches = ref<DomainRow[]>([]);
const selectedDomain = ref<DomainRow[]>([]);
const relationAction = ref<RelationTreeActionContext | null>(null);
const linkModalOpen = ref(false);
const selectedCnCandidate = ref<PickerCandidateRow | null>(null);
const linkSaveError = ref<string | null>(null);
const linkSaveLoading = ref(false);
const relationTreeKey = ref(0);
const cnInvFormMode = computed<'create' | 'edit'>(() =>
  relationAction.value?.actionId === 'cnInv.link.edit' ? 'edit' : 'create'
);

const cnAllRows = ref<PickerCandidateRow[]>([]);
const cnAllLoading = ref(false);

const uplKey = computed(() => store.selectedUplKey);
const rows = computed(() => store.sfDoubles);
const openCount = computed(() => rows.value.filter((r) => r.ciusStatus === 'open').length);
const selected = computed(() => selectedRows.value[0] ?? null);
const canCreate = computed(
  () => selected.value != null && selected.value.ciusStatus === 'open' && !!selected.value.ciusCnKey
);
const selectedDomainRow = computed(() => selectedDomain.value[0] ?? null);

const queueColumns: FemsqTableColumn<SudzCnInvUplSfDouble>[] = [
  { name: 'ciusStatus', label: 'статус', field: 'ciusStatus', align: 'left' },
  { name: 'ciusCnNum', label: 'Договор', field: 'ciusCnNum', align: 'left' },
  { name: 'ciusInvNum', label: 'СФ', field: 'ciusInvNum', align: 'left' },
  { name: 'ciusInvNumCount', label: 'совпад.', field: 'ciusInvNumCount', align: 'right' },
  { name: 'ciusCidut', label: 'Tbl', field: 'ciusCidut', align: 'right' }
];

const domainColumns: FemsqTableColumn<DomainRow>[] = [
  { name: 'invKey', label: 'inv', field: 'invKey', align: 'right' },
  { name: 'invNum', label: 'номер', field: 'invNum', align: 'left' },
  { name: 'cnNum', label: 'договор', field: 'cnNum', align: 'left' },
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' }
];

const pickerColumns: FemsqTableColumn<PickerCandidateRow>[] = [
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  { name: 'cnNum', label: 'договор', field: 'cnNum', align: 'left' },
  { name: 'invKey', label: 'inv', field: 'invKey', align: 'right' },
  { name: 'invNum', label: 'СФ', field: 'invNum', align: 'left' }
];

const excelRows = computed(() => {
  const e = excel.value;
  if (!e) return [];
  return [
    { label: 'FindDbtNum / cidutKey', value: `${e.findDbtNum ?? '—'} / ${e.cidutKey}` },
    { label: 'лист / строка', value: `${e.cidutSheet ?? '—'} / ${e.cidutSheetNum ?? '—'}` },
    { label: 'БУиРГ', value: String(e.cidutCntrPrtNum ?? '—') },
    { label: 'контрагент', value: e.cidutCntrPrtName ?? '—' },
    { label: 'ИНН', value: e.cidutCntrPrtITN ?? '—' },
    { label: 'договор', value: e.cidutCnName ?? '—' },
    { label: 'дата договора', value: e.cidutCnDate ?? '—' },
    { label: 'СФ', value: e.cidutCnInv ?? '—' },
    { label: 'имя СФ', value: e.cidutCnInvName ?? '—' },
    { label: 'дата обр. / погаш.', value: `${e.cidutFormtnDate ?? '—'} / ${e.cidutMatrtyDate ?? '—'}` },
    { label: 'долг / просрочка', value: `${e.cidutDebt ?? '—'} / ${e.cidutDebtOverdue ?? '—'}` },
    { label: 'doc / link', value: `${e.cidutDoc ?? '—'} / ${e.cidutLink ?? '—'}` }
  ];
});

const cnPickerRows = computed<PickerCandidateRow[]>(() => {
  return cnAllRows.value.length > 0 ? cnAllRows.value : cnPickerRowsFromDomainMatches.value;
});

const cnPickerRowsFromDomainMatches = computed<PickerCandidateRow[]>(() => {
  const map = new Map<string, PickerCandidateRow>();
  for (const row of domainMatches.value) {
    if (row.cnKey == null) continue;
    const key = String(row.cnKey);
    if (!map.has(key)) {
      map.set(key, {
        rowKey: key,
        cnKey: row.cnKey,
        cnNum: row.cnNum,
        invKey: row.invKey,
        invNum: row.invNum
      });
    }
  }
  return Array.from(map.values());
});

onMounted(async () => {
  if (cnAllRows.value.length > 0 || cnAllLoading.value) {
    return;
  }
  cnAllLoading.value = true;
  try {
    const cnNums = await fetchCnNums();
    const map = new Map<number, PickerCandidateRow>();
    for (const row of cnNums) {
      const cnKey = row.cnnCn;
      if (map.has(cnKey)) continue;
      map.set(cnKey, {
        rowKey: String(cnKey),
        cnKey,
        cnNum: row.cnnNum,
        invKey: null,
        invNum: null
      });
    }
    cnAllRows.value = Array.from(map.values());
  } catch (e) {
    // Если полный список договоров не загрузился — откатываемся к domainMatches как "best effort".
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    cnAllLoading.value = false;
  }
});

const linkForm = computed<RelationFormState | null>(() => {
  const action = relationAction.value;
  const domain = selectedDomainRow.value;
  if (!linkModalOpen.value || action == null || domain == null) {
    return null;
  }
  return buildCnInvLinkForm({
    context: action,
    mode: cnInvFormMode.value,
    domain,
    cnCandidates: cnPickerRows.value,
    invCandidates: domain ? [domain] : [],
    selectedCnCandidate: selectedCnCandidate.value,
    selectedInvCandidate: domain,
    cnPickerSpec,
    invPickerSpec: contractsInvSpec,
    pickerColumns
  });
});

watch(
  selected,
  async (row) => {
    excel.value = null;
    domainMatches.value = [];
    selectedDomain.value = [];
    relationAction.value = null;
    linkModalOpen.value = false;
    selectedCnCandidate.value = null;
    if (!row) return;
    excelLoading.value = true;
    domainLoading.value = true;
    error.value = null;
    try {
      excel.value = await getSudzSfDoubleExcelCandidate(row.ciusKey);
      const inv = row.ciusInvNum ?? '';
      const matches = inv ? await getSudzSfDoubleDomainMatches(inv) : [];
      domainMatches.value = matches.map((m, i) => ({
        ...m,
        rowKey: `${m.invKey}-${m.ciKey ?? 'x'}-${i}`
      }));
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      excelLoading.value = false;
      domainLoading.value = false;
    }
  },
  { immediate: true }
);

/**
 * Возврат на экран загрузки свода.
 */
function goBack(): void {
  connection.navigate('sudz-dbt-upl');
}

function cnCandidateFromContext(context: RelationTreeActionContext): PickerCandidateRow | null {
  const cnKeyRaw = Number(context.node.fields.ciCn ?? null);
  if (!Number.isFinite(cnKeyRaw) || cnKeyRaw <= 0) {
    return null;
  }
  const cnKey = cnKeyRaw;
  return (
    cnPickerRows.value.find((row) => row.cnKey === cnKey) ?? {
      rowKey: String(cnKey),
      cnKey,
      cnNum: null,
      invKey: null,
      invNum: null
    }
  );
}

/**
 * Создаёт новый СФ по выбранной строке очереди.
 */
async function onCreate(): Promise<void> {
  const row = selected.value;
  if (!row || !canCreate.value) return;
  creating.value = true;
  error.value = null;
  try {
    const updated = await createSudzSfFromDouble(row.ciusKey);
    if (store.selectedUplKey != null) {
      await store.selectUpl(store.selectedUplKey);
    }
    const refreshed = store.sfDoubles.find((r) => r.ciusKey === updated.ciusKey) ?? updated;
    selectedRows.value = [refreshed];
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    creating.value = false;
  }
}

/**
 * Skeleton T6b: action открывает универсальную модалку host-side.
 *
 * @param context действие с контекстом узла
 */
function onRelationAction(context: RelationTreeActionContext): void {
  if (context.actionId === 'cnInv.link.create') {
    relationAction.value = context;
    linkSaveError.value = null;
    const preferredCnKey = selectedDomainRow.value?.cnKey ?? null;
    selectedCnCandidate.value =
      (preferredCnKey != null ? cnPickerRows.value.find((r) => r.cnKey === preferredCnKey) : null) ??
      cnPickerRows.value[0] ??
      null;
    linkModalOpen.value = true;
    return;
  }
  if (context.actionId === 'cnInv.link.edit' && context.node.table === 'cnInv') {
    relationAction.value = context;
    linkSaveError.value = null;
    selectedCnCandidate.value = cnCandidateFromContext(context);
    linkModalOpen.value = true;
    return;
  }
  if (context.actionId === 'cnInv.link.delete' && context.node.table === 'cnInv') {
    void onDeleteCnInv(context);
    return;
  }
  error.value = `Действие ${context.actionId} ещё не реализовано на экране КСДСФ.`;
}

/**
 * Обновляет выбор строки во вкладках модалки.
 *
 * @param pickerId идентификатор вкладки выбора
 * @param rowKey ключ выбранной строки
 */
function onPickerSelect(pickerId: string, rowKey: string | null): void {
  if (pickerId !== 'cn') {
    return;
  }
  selectedCnCandidate.value =
    cnPickerRows.value.find((row) => row.rowKey === rowKey) ??
    (rowKey != null
      ? {
          rowKey,
          cnKey: Number(rowKey) || null,
          cnNum: null,
          invKey: null,
          invNum: null
        }
      : null);
}

/**
 * Выполняет реальную GraphQL mutation ручной привязки.
 */
async function onLinkSave(): Promise<void> {
  if (selectedCnCandidate.value == null) {
    linkSaveError.value = 'Выберите договор для новой связи cnInv.';
    return;
  }
  const mode = cnInvFormMode.value;
  const ciusKey = selected.value?.ciusKey;
  const currentInvFromAction = Number(relationAction.value?.node.fields.ciInv ?? null);
  const invKey =
    relationAction.value?.node.fromId ??
    selectedDomainRow.value?.invKey ??
    (currentInvFromAction > 0 ? currentInvFromAction : null);
  const cnKey = selectedCnCandidate.value.cnKey;
  if (ciusKey == null || invKey == null || cnKey == null) {
    linkSaveError.value = 'Недостаточно данных для создания связи cnInv.';
    return;
  }
  linkSaveLoading.value = true;
  linkSaveError.value = null;
  error.value = null;
  try {
    if (mode === 'edit') {
      const ciKey = relationAction.value?.node.rowKey;
      if (ciKey == null) {
        throw new Error('Не найден ciKey для правки cnInv.');
      }
      await updateCnInv(ciKey, { ciInv: invKey, ciCn: cnKey });
      relationTreeKey.value += 1;
      linkModalOpen.value = false;
      relationAction.value = null;
      return;
    }
    const updated = await linkSudzSfDoubleToCn({ ciusKey, invKey, cnKey });
    if (store.selectedUplKey != null) {
      await store.selectUpl(store.selectedUplKey);
    }
    const refreshed = store.sfDoubles.find((r) => r.ciusKey === updated.ciusKey) ?? updated;
    selectedRows.value = [refreshed];
    linkModalOpen.value = false;
    relationAction.value = null;
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    linkSaveError.value = message;
    error.value = message;
  } finally {
    linkSaveLoading.value = false;
  }
}

async function onDeleteCnInv(context: RelationTreeActionContext): Promise<void> {
  const ciKey = context.node.rowKey;
  if (ciKey == null) {
    error.value = 'Не найден ciKey для удаления cnInv.';
    return;
  }
  const confirmed = await new Promise<boolean>((resolve) => {
    $q.dialog({
      title: 'Удалить связь с договором',
      message: `Удалить запись cnInv ciKey=${ciKey}?`,
      cancel: true,
      persistent: true
    })
      .onOk(() => resolve(true))
      .onCancel(() => resolve(false))
      .onDismiss(() => resolve(false));
  });
  if (!confirmed) {
    return;
  }
  try {
    await deleteCnInv(ciKey);
    relationTreeKey.value += 1;
    error.value = null;
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
}
</script>

<style scoped>
.sudz-sf-page {
  min-height: 0;
}

.sudz-sf-page-inner {
  box-sizing: border-box;
  min-height: 0;
}
.sudz-sf-splitter {
  min-height: 0;
}
.sudz-sf-splitter :deep(> .q-splitter__panel) {
  overflow: hidden;
  min-height: 0;
}
.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}
.sudz-sf-double-tree {
  min-height: 0;
}
</style>
