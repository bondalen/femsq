<template>
  <QPage class="sudz-sf-page column no-wrap absolute-full">
    <div class="row items-center q-px-md q-py-sm shrink-0 q-gutter-sm">
      <QBtn flat dense no-caps icon="arrow_back" label="К загрузке свода" @click="goBack" />
      <div class="text-subtitle1">Разбор СФ с совпадающими номерами</div>
      <QSpace />
      <div class="text-caption text-grey-6">
        upl={{ uplKey ?? '—' }} · очередь {{ rows.length }} · open {{ openCount }}
      </div>
    </div>

    <div v-if="!uplKey" class="q-pa-md text-grey-6">Выберите выгрузку на экране «Загрузка свода».</div>
    <div v-else-if="error" class="q-pa-md text-negative">{{ error }}</div>

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
                      <div class="q-pa-sm overflow-auto">
                        <div v-if="!selectedDomain[0]" class="text-grey-6">
                          Выберите СФ в списке совпадений.
                        </div>
                        <QMarkupTable v-else dense flat bordered>
                          <tbody>
                            <tr>
                              <td class="text-grey-6">invKey</td>
                              <td>{{ selectedDomain[0].invKey }}</td>
                            </tr>
                            <tr>
                              <td class="text-grey-6">номер</td>
                              <td>{{ selectedDomain[0].invNum ?? '—' }}</td>
                            </tr>
                            <tr>
                              <td class="text-grey-6">ввод</td>
                              <td>{{ selectedDomain[0].invEntered ?? '—' }}</td>
                            </tr>
                            <tr>
                              <td class="text-grey-6">ciKey</td>
                              <td>{{ selectedDomain[0].ciKey ?? '—' }}</td>
                            </tr>
                            <tr>
                              <td class="text-grey-6">договор</td>
                              <td>
                                {{ selectedDomain[0].cnNum ?? '—' }}
                                <span v-if="selectedDomain[0].cnKey">
                                  (cn={{ selectedDomain[0].cnKey }})
                                </span>
                              </td>
                            </tr>
                          </tbody>
                        </QMarkupTable>
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
  </QPage>
</template>

<script setup lang="ts">
/**
 * Экран КСДСФ: разбор СФ с совпадающими номерами (S68).
 */
import { computed, ref, watch } from 'vue';

import { FemsqTable, type FemsqTableColumn } from 'fequlib';
import {
  createSudzSfFromDouble,
  getSudzSfDoubleDomainMatches,
  getSudzSfDoubleExcelCandidate
} from '@/api/sudz-api';
import { useConnectionStore } from '@/stores/connection';
import { useSudzDbtUplStore } from '@/stores/sudz-dbt-upl';
import type {
  SudzCnInvUplSfDouble,
  SudzSfDoubleDomainMatch,
  SudzSfDoubleExcelCandidate
} from '@/types/sudz';
import {
  QBtn,
  QMarkupTable,
  QPage,
  QSpace,
  QSplitter,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs
} from 'quasar';

type DomainRow = SudzSfDoubleDomainMatch & { rowKey: string };

const connection = useConnectionStore();
const store = useSudzDbtUplStore();

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

const uplKey = computed(() => store.selectedUplKey);
const rows = computed(() => store.sfDoubles);
const openCount = computed(() => rows.value.filter((r) => r.ciusStatus === 'open').length);
const selected = computed(() => selectedRows.value[0] ?? null);
const canCreate = computed(
  () => selected.value != null && selected.value.ciusStatus === 'open' && !!selected.value.ciusCnKey
);

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

watch(
  selected,
  async (row) => {
    excel.value = null;
    domainMatches.value = [];
    selectedDomain.value = [];
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
</script>

<style scoped>
.sudz-sf-page {
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
</style>
