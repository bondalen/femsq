<template>
  <QPage class="q-pa-none sudz-sf-page" data-test="sudz-inv-dbt-double-view">
    <div class="absolute-full q-pa-md column no-wrap sudz-sf-page-inner">
      <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
        <QBtn
          color="primary"
          unelevated
          dense
          no-caps
          icon="arrow_back"
          label="К загрузке свода"
          data-test="sudz-inv-dbt-double-back"
          @click="goBack"
        />
        <div class="text-h6 col">Разбор двоящих задолженностей СФ</div>
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
          <QSplitter
            v-model="queueExcelSplit"
            horizontal
            :limits="[30, 75]"
            separator-class="sudz-split-sep"
            class="fit sudz-sf-splitter"
          >
            <template #before>
              <div class="column fill-pane no-wrap q-pa-sm">
                <FemsqTable
                  fill
                  class="col"
                  :rows="rows"
                  :columns="queueColumns"
                  row-key="ciudKey"
                  dense
                  flat
                  :loading="loading"
                  selection="single"
                  v-model:selected="selectedRows"
                  data-test="sudz-inv-dbt-double-queue"
                />
                <div class="row items-center q-gutter-sm q-pt-sm shrink-0">
                  <QBtn
                    color="warning"
                    unelevated
                    dense
                    no-caps
                    label="Create var"
                    :disable="!canCreateVar"
                    :loading="acting"
                    data-test="sudz-inv-dbt-double-create-var"
                    @click="onOpenCreateVar"
                  />
                  <QBtn
                    color="primary"
                    unelevated
                    dense
                    no-caps
                    label="Create слот"
                    :disable="!canCreate"
                    :loading="acting"
                    data-test="sudz-inv-dbt-double-create"
                    @click="onCreate"
                  />
                  <QBtn
                    color="secondary"
                    unelevated
                    dense
                    no-caps
                    label="Link к слоту"
                    :disable="!canLink"
                    :loading="acting"
                    data-test="sudz-inv-dbt-double-link"
                    @click="onLink"
                  />
                  <div class="text-caption text-grey-6">
                    Без var — Create var; затем Create/Link слота.
                  </div>
                </div>
              </div>
            </template>
            <template #after>
              <div class="column fill-pane no-wrap q-pa-sm" data-test="sudz-inv-dbt-excel-pane">
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
                <div
                  class="sudz-inv-dbt-messages shrink-0 q-mt-sm q-pa-sm"
                  data-test="sudz-inv-dbt-messages"
                >
                  <div class="text-caption text-grey-6 q-mb-xs">Сообщения</div>
                  <pre
                    v-if="selected?.ciudReasonDetail"
                    class="sudz-inv-dbt-messages-body"
                  >{{ selected.ciudReasonDetail }}</pre>
                  <div v-else class="text-grey-6">
                    Нет сообщений (rebuild очереди заполнит [queue.build]).
                  </div>
                </div>
              </div>
            </template>
          </QSplitter>
        </template>

        <template #after>
          <QSplitter
            v-model="sfSumsSplit"
            :limits="[30, 70]"
            separator-class="sudz-split-sep"
            class="fit sudz-sf-splitter"
          >
            <template #before>
              <div class="column fill-pane no-wrap q-pa-sm">
                <div class="text-subtitle2 q-mb-xs shrink-0">Слоты invDbt · СФ</div>
                <QSplitter
                  v-model="domainSplit"
                  horizontal
                  :limits="[25, 70]"
                  separator-class="sudz-split-sep"
                  class="col sudz-sf-splitter"
                >
                  <template #before>
                    <FemsqTable
                      fill
                      class="fit"
                      :rows="slots"
                      :columns="slotColumns"
                      row-key="idKey"
                      dense
                      flat
                      :loading="slotsLoading"
                      selection="single"
                      v-model:selected="selectedSlots"
                      data-test="sudz-inv-dbt-slots"
                    />
                  </template>
                  <template #after>
                    <div class="q-pa-sm column fill-pane no-wrap">
                      <div v-if="!selected?.ciudIKey" class="text-grey-6">
                        Выберите строку с iKey.
                      </div>
                      <RelationTree
                        v-else
                        :key="`inv-${selected.ciudIKey}-${treeTick}`"
                        class="col"
                        :spec="invSlotsSpec"
                        :root-id="selected.ciudIKey"
                        :fetch-node="fetchRelationNode"
                        :fetch-expand="fetchRelationExpand"
                        data-test="sudz-inv-dbt-tree"
                        root-class="sudz-sf-double-tree"
                      />
                    </div>
                  </template>
                </QSplitter>
              </div>
            </template>

            <template #after>
              <div class="column fill-pane no-wrap q-pa-sm">
                <div class="text-subtitle2 q-mb-xs shrink-0">Суммы</div>
                <div class="text-caption text-grey-6 q-mb-xs shrink-0">
                  Якорь Excel: {{ excelDebtLabel }} · ε={{ sumMatchEpsilon }}
                </div>
                <QSplitter
                  v-model="sumsOldNewSplit"
                  horizontal
                  :limits="[30, 70]"
                  separator-class="sudz-split-sep"
                  class="col sudz-sf-splitter"
                >
                  <template #before>
                    <div class="column fill-pane no-wrap q-pa-xs">
                      <div class="text-subtitle2 q-px-sm shrink-0">
                        Старая · cn_inv_dbt (ciaKey)
                      </div>
                      <FemsqTable
                        fill
                        class="col"
                        :rows="oldSumRows"
                        :columns="oldSumColumns"
                        row-key="rowKey"
                        dense
                        flat
                        :show-filter="false"
                      />
                    </div>
                  </template>
                  <template #after>
                    <div class="column fill-pane no-wrap q-pa-xs">
                      <div class="text-subtitle2 q-px-sm shrink-0">
                        Новая · DbtValue
                      </div>
                      <FemsqTable
                        fill
                        class="col"
                        :rows="newSumRows"
                        :columns="newSumColumns"
                        row-key="rowKey"
                        dense
                        flat
                        :show-filter="false"
                      />
                    </div>
                  </template>
                </QSplitter>
              </div>
            </template>
          </QSplitter>
        </template>
      </QSplitter>
    </div>

    <QDialog v-model="varDialog" persistent>
      <QCard style="min-width: 640px; max-width: 90vw">
        <QCardSection class="row items-center q-pb-none">
          <div class="text-h6">Create invDbtVar · ciud={{ selected?.ciudKey }}</div>
          <QSpace />
          <QBtn icon="close" flat round dense v-close-popup />
        </QCardSection>
        <QCardSection class="column q-gutter-sm" style="max-height: 70vh; overflow: auto">
          <div class="text-caption text-grey-6">
            account={{ varCandidates?.accountKey ?? '—' }} · iKey={{ varCandidates?.iKey ?? '—' }}
          </div>
          <div class="text-subtitle2">Сторона (cn + cn_s_org)</div>
          <FemsqTable
            :rows="varCandidates?.sides ?? []"
            :columns="sideColumns"
            row-key="cnSOrgKey"
            dense
            flat
            selection="single"
            v-model:selected="selectedSides"
            data-test="sudz-inv-dbt-var-sides"
            style="max-height: 160px"
          />
          <div class="text-subtitle2">cnNum (type=1)</div>
          <FemsqTable
            :rows="cnNumsForSide"
            :columns="cnNumColumns"
            row-key="cnnKey"
            dense
            flat
            selection="single"
            v-model:selected="selectedCnNums"
            data-test="sudz-inv-dbt-var-cnnums"
            style="max-height: 160px"
          />
          <div class="text-subtitle2">invNum</div>
          <FemsqTable
            :rows="varCandidates?.invNums ?? []"
            :columns="invNumColumns"
            row-key="inKey"
            dense
            flat
            selection="single"
            v-model:selected="selectedInvNums"
            data-test="sudz-inv-dbt-var-invnums"
            style="max-height: 160px"
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать var"
            :disable="!canConfirmVar"
            :loading="acting"
            data-test="sudz-inv-dbt-var-confirm"
            @click="onConfirmCreateVar"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import RelationTree from '@/components/relation/RelationTree.vue';
import {
  createSudzInvDbtFromDouble,
  ensureSudzInvDbtVarForDouble,
  getSudzInvDbtDoubleExcelCandidate,
  getSudzInvDbtSlots,
  getSudzInvDbtVarCandidates,
  getSudzSfDoubleSumMatches,
  linkSudzInvDbtDouble
} from '@/api/sudz-api';
import { fetchRelationExpand, fetchRelationNode } from '@/api/relation-api';
import { useConnectionStore } from '@/stores/connection';
import { useSudzDbtUplStore } from '@/stores/sudz-dbt-upl';
import type {
  SudzCnInvUplInvDbtDouble,
  SudzInvDbtVarCandidates,
  SudzInvDbtVarCnNumCandidate,
  SudzInvDbtVarInvNumCandidate,
  SudzInvDbtVarSideCandidate,
  SudzSfDoubleExcelCandidate
} from '@/types/sudz';
import type { RelationTreeSpec } from '@/trees/relation-tree';
import invSlotsSpecJson from '@/trees/inv-dbt-slots.tree.json';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';
import {
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QMarkupTable,
  QPage,
  QSpace,
  QSplitter,
  useQuasar
} from 'quasar';
import { computed, ref, watch } from 'vue';
type SlotRow = { idKey: number; idInv: number; idNum: number; idNote: string | null };
type SumOld = {
  rowKey: string;
  cidKey: number;
  number: number | null;
  dbtTtl: number | null;
  dbtOverd: number | null;
  ciaKey: number | null;
};
type SumNew = {
  rowKey: string;
  dvKey: number;
  dvInvDbt: number | null;
  dbtKey: number | null;
  dvTtl: number | null;
  dvUpl: number | null;
};

const invSlotsSpec = invSlotsSpecJson as RelationTreeSpec;
const sumMatchEpsilon = 0.01;

const connection = useConnectionStore();
const store = useSudzDbtUplStore();
const $q = useQuasar();

const queueSplit = ref(28);
const queueExcelSplit = ref(55);
const sfSumsSplit = ref(50);
const domainSplit = ref(40);
const sumsOldNewSplit = ref(50);

const loading = ref(false);
const excelLoading = ref(false);
const slotsLoading = ref(false);
const acting = ref(false);
const error = ref<string | null>(null);
const rows = ref<SudzCnInvUplInvDbtDouble[]>([]);
const selectedRows = ref<SudzCnInvUplInvDbtDouble[]>([]);
const excel = ref<SudzSfDoubleExcelCandidate | null>(null);
const slots = ref<SlotRow[]>([]);
const selectedSlots = ref<SlotRow[]>([]);
const oldSumRows = ref<SumOld[]>([]);
const newSumRows = ref<SumNew[]>([]);
const treeTick = ref(0);
const varDialog = ref(false);
const varCandidates = ref<SudzInvDbtVarCandidates | null>(null);
const selectedSides = ref<SudzInvDbtVarSideCandidate[]>([]);
const selectedCnNums = ref<SudzInvDbtVarCnNumCandidate[]>([]);
const selectedInvNums = ref<SudzInvDbtVarInvNumCandidate[]>([]);

const uplKey = computed(() => store.selectedUplKey);
const selected = computed(() => selectedRows.value[0] ?? null);
const openCount = computed(() => rows.value.filter((r) => r.ciudStatus === 'open').length);
const canCreateVar = computed(
  () =>
    !!selected.value &&
    selected.value.ciudStatus === 'open' &&
    !!selected.value.ciudIKey &&
    !selected.value.ciudIdvvKey
);
const canCreate = computed(
  () =>
    !!selected.value &&
    selected.value.ciudStatus === 'open' &&
    !!selected.value.ciudIKey &&
    !!selected.value.ciudIdvvKey
);
const canLink = computed(
  () => canCreate.value && !!selectedSlots.value[0]
);
const cnNumsForSide = computed(() => {
  const side = selectedSides.value[0];
  const all = varCandidates.value?.cnNums ?? [];
  if (!side) return all;
  return all.filter((c) => c.cnKey === side.cnKey);
});
const canConfirmVar = computed(() => {
  const c = varCandidates.value;
  return (
    !!c?.accountKey &&
    !!selectedSides.value[0] &&
    !!selectedCnNums.value[0] &&
    !!selectedInvNums.value[0]
  );
});
const excelDebtLabel = computed(() => {
  const d = excel.value?.cidutDebt;
  return d == null ? '—' : String(d);
});

const queueColumns: FemsqTableColumn<SudzCnInvUplInvDbtDouble>[] = [
  { name: 'ciudIKey', label: 'iKey', field: 'ciudIKey', align: 'right', sortable: true },
  { name: 'ciudInvNum', label: 'СФ', field: 'ciudInvNum', align: 'left' },
  { name: 'ciudCnNum', label: 'договор', field: 'ciudCnNum', align: 'left' },
  { name: 'ciudDebt', label: 'сумма', field: 'ciudDebt', align: 'right' },
  { name: 'ciudIdvvKey', label: 'var', field: 'ciudIdvvKey', align: 'right' },
  { name: 'ciudReason', label: 'reason', field: 'ciudReason', align: 'left' },
  { name: 'ciudStatus', label: 'status', field: 'ciudStatus', align: 'left' }
];

const slotColumns: FemsqTableColumn<SlotRow>[] = [
  { name: 'idKey', label: 'idKey', field: 'idKey', align: 'right' },
  { name: 'idNum', label: 'idNum', field: 'idNum', align: 'right' },
  { name: 'idNote', label: 'note', field: 'idNote', align: 'left' }
];

const sideColumns: FemsqTableColumn<SudzInvDbtVarSideCandidate>[] = [
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  { name: 'cnSOrgKey', label: 'cn_s_org', field: 'cnSOrgKey', align: 'right' },
  { name: 'csoCnDate', label: 'дата', field: 'csoCnDate', align: 'left' }
];

const cnNumColumns: FemsqTableColumn<SudzInvDbtVarCnNumCandidate>[] = [
  { name: 'cnnKey', label: 'cnnKey', field: 'cnnKey', align: 'right' },
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  { name: 'cnnNumNull', label: 'номер', field: 'cnnNumNull', align: 'left' }
];

const invNumColumns: FemsqTableColumn<SudzInvDbtVarInvNumCandidate>[] = [
  { name: 'inKey', label: 'inKey', field: 'inKey', align: 'right' },
  { name: 'inInv', label: 'iKey', field: 'inInv', align: 'right' },
  { name: 'inNumNull', label: 'номер', field: 'inNumNull', align: 'left' }
];

const oldSumColumns: FemsqTableColumn<SumOld>[] = [
  { name: 'cidKey', label: 'cid', field: 'cidKey', align: 'right' },
  { name: 'ciaKey', label: 'cia', field: 'ciaKey', align: 'right' },
  { name: 'dbtTtl', label: 'сумма', field: 'dbtTtl', align: 'right' },
  { name: 'dbtOverd', label: 'просроч.', field: 'dbtOverd', align: 'right' }
];

const newSumColumns: FemsqTableColumn<SumNew>[] = [
  { name: 'dvKey', label: 'dv', field: 'dvKey', align: 'right' },
  { name: 'dvInvDbt', label: 'invDbt', field: 'dvInvDbt', align: 'right' },
  { name: 'dbtKey', label: 'dbt', field: 'dbtKey', align: 'right' },
  { name: 'dvTtl', label: 'сумма', field: 'dvTtl', align: 'right' },
  { name: 'dvUpl', label: 'upl', field: 'dvUpl', align: 'right' }
];

const excelRows = computed(() => {
  const e = excel.value;
  if (!e) return [];
  return [
    { label: 'cidutKey', value: String(e.cidutKey) },
    { label: 'контрагент', value: e.cidutCntrPrtName ?? '—' },
    { label: 'БУиРГ', value: e.cidutCntrPrtNum ?? '—' },
    { label: 'договор', value: e.cidutCnName ?? '—' },
    { label: 'СФ', value: e.cidutCnInv ?? '—' },
    { label: 'сумма', value: e.cidutDebt ?? '—' },
    { label: 'просроч.', value: e.cidutDebtOverdue ?? '—' },
    { label: 'образование', value: e.cidutFormtnDate ?? '—' },
    { label: 'срок', value: e.cidutMatrtyDate ?? '—' }
  ];
});

/**
 * Возврат на лаунчер.
 */
function goBack(): void {
  connection.navigate('sudz-dbt-upl');
}

/**
 * Перечитать очередь из лаунчера.
 */
async function reloadQueue(): Promise<void> {
  const key = uplKey.value;
  if (key == null) {
    rows.value = [];
    return;
  }
  loading.value = true;
  error.value = null;
  try {
    await store.selectUpl(key);
    rows.value = [...store.invDbtDoubles].sort((a, b) => {
      const ai = a.ciudIKey ?? Number.MAX_SAFE_INTEGER;
      const bi = b.ciudIKey ?? Number.MAX_SAFE_INTEGER;
      return ai - bi || a.ciudKey - b.ciudKey;
    });
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    loading.value = false;
  }
}

/**
 * Открыть диалог Create var.
 */
async function onOpenCreateVar(): Promise<void> {
  const row = selected.value;
  if (!row) return;
  acting.value = true;
  try {
    const c = await getSudzInvDbtVarCandidates(row.ciudKey);
    varCandidates.value = c;
    selectedSides.value = c.sides.length === 1 ? [...c.sides] : [];
    const cnFiltered =
      selectedSides.value[0] != null
        ? c.cnNums.filter((n) => n.cnKey === selectedSides.value[0]!.cnKey)
        : c.cnNums;
    selectedCnNums.value = cnFiltered.length === 1 ? [...cnFiltered] : [];
    selectedInvNums.value = c.invNums.length === 1 ? [...c.invNums] : [];
    varDialog.value = true;
  } catch (e) {
    $q.notify({
      type: 'negative',
      message: e instanceof Error ? e.message : String(e)
    });
  } finally {
    acting.value = false;
  }
}

/**
 * Подтвердить create/reuse invDbtVar.
 */
async function onConfirmCreateVar(): Promise<void> {
  const row = selected.value;
  const c = varCandidates.value;
  const side = selectedSides.value[0];
  const cn = selectedCnNums.value[0];
  const inv = selectedInvNums.value[0];
  if (!row || !c?.accountKey || !side || !cn || !inv) return;
  acting.value = true;
  try {
    const updated = await ensureSudzInvDbtVarForDouble({
      ciudKey: row.ciudKey,
      idvvCnNum: cn.cnnKey,
      idvvInvNum: inv.inKey,
      idvvAccnt: c.accountKey,
      idvvCnSOrg: side.cnSOrgKey
    });
    $q.notify({
      type: 'positive',
      message: `var=${updated.ciudIdvvKey} для ciud=${row.ciudKey}`
    });
    varDialog.value = false;
    await reloadQueue();
    const refreshed = rows.value.find((r) => r.ciudKey === row.ciudKey);
    if (refreshed) {
      selectedRows.value = [refreshed];
    }
  } catch (e) {
    $q.notify({
      type: 'negative',
      message: e instanceof Error ? e.message : String(e)
    });
  } finally {
    acting.value = false;
  }
}

/**
 * Create нового слота + Value.
 */
async function onCreate(): Promise<void> {
  const row = selected.value;
  if (!row) return;
  acting.value = true;
  try {
    await createSudzInvDbtFromDouble(row.ciudKey);
    $q.notify({ type: 'positive', message: `Create слота для ciud=${row.ciudKey}` });
    await reloadQueue();
    treeTick.value += 1;
  } catch (e) {
    $q.notify({
      type: 'negative',
      message: e instanceof Error ? e.message : String(e)
    });
  } finally {
    acting.value = false;
  }
}

/**
 * Link к выбранному слоту + Value.
 */
async function onLink(): Promise<void> {
  const row = selected.value;
  const slot = selectedSlots.value[0];
  if (!row || !slot) return;
  acting.value = true;
  try {
    await linkSudzInvDbtDouble(row.ciudKey, slot.idKey);
    $q.notify({
      type: 'positive',
      message: `Link ciud=${row.ciudKey} → idKey=${slot.idKey}`
    });
    await reloadQueue();
    treeTick.value += 1;
  } catch (e) {
    $q.notify({
      type: 'negative',
      message: e instanceof Error ? e.message : String(e)
    });
  } finally {
    acting.value = false;
  }
}

watch(
  selectedSides,
  () => {
    const side = selectedSides.value[0];
    const pick = selectedCnNums.value[0];
    if (side && pick && pick.cnKey !== side.cnKey) {
      selectedCnNums.value = [];
    }
  },
  { deep: true }
);

watch(
  uplKey,
  () => {
    void reloadQueue();
  },
  { immediate: true }
);

watch(selected, async (row) => {
  excel.value = null;
  slots.value = [];
  selectedSlots.value = [];
  oldSumRows.value = [];
  newSumRows.value = [];
  if (!row) return;
  excelLoading.value = true;
  slotsLoading.value = true;
  try {
    excel.value = await getSudzInvDbtDoubleExcelCandidate(row.ciudKey);
    if (row.ciudIKey != null) {
      slots.value = await getSudzInvDbtSlots(row.ciudIKey);
    }
    const debt = excel.value?.cidutDebt ?? row.ciudDebt;
    if (debt != null && Number.isFinite(debt)) {
      const sums = await getSudzSfDoubleSumMatches(debt, sumMatchEpsilon);
      oldSumRows.value = sums.oldMatches.map((m) => ({
        rowKey: String(m.cidKey),
        cidKey: m.cidKey,
        number: m.number,
        dbtTtl: m.dbtTtl,
        dbtOverd: m.dbtOverd,
        ciaKey: m.ciaKey
      }));
      newSumRows.value = sums.newMatches.map((m) => ({
        rowKey: String(m.dvKey),
        dvKey: m.dvKey,
        dvInvDbt: m.dvInvDbt,
        dbtKey: m.dbtKey,
        dvTtl: m.dvTtl,
        dvUpl: m.dvUpl
      }));
    }
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    excelLoading.value = false;
    slotsLoading.value = false;
  }
});
</script>

<style scoped>
.sudz-sf-page-inner {
  min-height: 0;
}
.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}
:deep(.sudz-split-sep) {
  background: rgba(0, 0, 0, 0.08);
}
.sudz-inv-dbt-messages {
  border-top: 1px solid rgba(0, 0, 0, 0.08);
  max-height: 40%;
  overflow: auto;
}
.sudz-inv-dbt-messages-body {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.35;
}
</style>
