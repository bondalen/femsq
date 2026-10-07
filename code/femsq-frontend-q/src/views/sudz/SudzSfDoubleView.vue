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
          :label="backLabel"
          data-test="sudz-sf-double-back"
          @click="goBack"
        />
        <div class="text-h6 col">Разбор СФ с совпадающими номерами</div>
        <div class="text-caption text-grey-6 shrink-0">
          {{ unloadLabel }}={{ unloadKey ?? '—' }} · очередь {{ rows.length }} · open {{ openCount }}
        </div>
      </div>

      <div v-if="!unloadKey" class="text-grey-6">{{ emptyUnloadHint }}</div>
      <div v-else-if="error" class="text-negative">{{ error }}</div>

      <!-- Вариант A: слева очередь+Excel столбиком; справа СФ и Суммы рядом (без вкладок) -->
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
                  row-key="ciusKey"
                  dense
                  flat
                  :loading="loading"
                  selection="single"
                  v-model:selected="selectedRows"
                  data-test="sudz-sf-double-queue"
                />
                <div class="row items-center q-gutter-sm q-pt-sm shrink-0 sudz-sf-queue-actions">
                  <QBtn
                    v-if="showAdvisorLinkBtn"
                    :color="advisorLinkHighlight ? 'positive' : 'primary'"
                    unelevated
                    dense
                    no-caps
                    icon="link"
                    label="Связать с договором Excel"
                    :disable="!canAdvisorLink"
                    :loading="advisorLinking"
                    data-test="sudz-sf-double-advisor-link"
                    @click="onAdvisorLink"
                  />
                  <QBtn
                    :color="advisorCreateHighlight ? 'positive' : 'grey-7'"
                    :outline="!advisorCreateHighlight"
                    :unelevated="advisorCreateHighlight"
                    dense
                    no-caps
                    label="Создать СФ по Excel"
                    :disable="!canCreate"
                    :loading="creating"
                    data-test="sudz-sf-double-create"
                    @click="onCreate"
                  />
                  <div v-if="advisorSummary" class="text-caption text-grey-7 col">
                    {{ advisorSummary }}
                  </div>
                </div>
              </div>
            </template>
            <template #after>
              <QSplitter
                v-model="excelAdvisorSplit"
                horizontal
                :limits="[25, 75]"
                separator-class="sudz-split-sep"
                class="fit sudz-sf-splitter"
                data-test="sudz-sf-excel-advisor-split"
              >
                <template #before>
                  <div class="column fill-pane no-wrap q-pa-sm" data-test="sudz-sf-excel-pane">
                    <div class="text-subtitle2 q-mb-sm shrink-0">Excel · кандидат</div>
                    <div v-if="!selected" class="text-grey-6">Выберите строку очереди.</div>
                    <div v-else-if="excelLoading" class="text-grey-6">Загрузка…</div>
                    <div v-else-if="!excel" class="text-grey-6">Строка Tbl не найдена.</div>
                    <QSplitter
                      v-else-if="excel.source === 'pmt' && pmtCaseRows.length"
                      v-model="excelCaseSplit"
                      horizontal
                      :limits="[20, 80]"
                      separator-class="sudz-split-sep"
                      class="col sudz-sf-splitter"
                      data-test="sudz-sf-excel-case-split"
                    >
                      <template #before>
                        <div
                          class="sudz-sf-excel-fields q-pr-xs"
                          data-test="sudz-sf-excel-fields"
                        >
                          <QMarkupTable dense flat bordered>
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
                        <div class="column fill-pane no-wrap q-pt-xs" data-test="sudz-sf-excel-case-pane">
                          <div class="text-caption text-grey-6 q-mb-xs shrink-0">
                            Белые строки кейса ({{ pmtCaseRows.length }})
                          </div>
                          <FemsqTable
                            class="col"
                            :rows="pmtCaseRows"
                            :columns="pmtCaseColumns"
                            row-key="ciputKey"
                            dense
                            flat
                            selection="single"
                            v-model:selected="selectedCaseRows"
                            data-test="sudz-sf-excel-case-rows"
                          />
                        </div>
                      </template>
                    </QSplitter>
                    <div
                      v-else
                      class="col sudz-sf-excel-fields"
                      data-test="sudz-sf-excel-fields"
                    >
                      <QMarkupTable dense flat bordered>
                        <tbody>
                          <tr v-for="row in excelRows" :key="row.label">
                            <td class="text-grey-6" style="width: 40%">{{ row.label }}</td>
                            <td>{{ row.value }}</td>
                          </tr>
                        </tbody>
                      </QMarkupTable>
                    </div>
                  </div>
                </template>
                <template #after>
                  <div
                    class="column fill-pane no-wrap q-pa-sm sudz-sf-messages"
                    data-test="sudz-sf-messages"
                  >
                    <div class="text-caption text-grey-6 q-mb-xs shrink-0">
                      Сообщения
                      <span v-if="advisorLoading" class="q-ml-xs">· советник…</span>
                    </div>
                    <pre
                      v-if="messagesText"
                      class="sudz-sf-messages-body col"
                    >{{ messagesText }}</pre>
                    <div v-else class="text-grey-6">Выберите строку очереди.</div>
                  </div>
                </template>
              </QSplitter>
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
              <div class="column fill-pane no-wrap q-pa-sm" data-test="sudz-sf-domain-pane">
                <div class="text-subtitle2 q-mb-xs shrink-0">Счета-фактуры</div>
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
                    <div class="q-pa-sm column fill-pane no-wrap">
                      <div v-if="!selectedDomain[0]" class="text-grey-6">
                        Выберите СФ в списке совпадений.
                      </div>
                      <template v-else-if="sumsPaneMode === 'pmt'">
                        <div class="row items-center q-mb-xs shrink-0 q-gutter-sm">
                          <div class="text-caption text-grey-7">Профиль кандидата СФ</div>
                          <QBtn
                            flat
                            dense
                            no-caps
                            size="sm"
                            color="primary"
                            :label="showPmtOutline ? 'Скрыть контур' : 'Техн. каталог'"
                            data-test="sudz-sf-decision-outline-toggle"
                            @click="showPmtOutline = !showPmtOutline"
                          />
                        </div>
                        <SfDecisionTree
                          class="col"
                          :inv-key="selectedDomain[0].invKey"
                          :current-upl-key="unloadKey"
                          :excel-cn-text="excel?.cidutCnName ?? null"
                          :excel-inv-num="excel?.cidutCnInv ?? null"
                          :excel-cntr-prt-num="excel?.cidutCntrPrtNum ?? null"
                          :excel-blns-sum="excel?.pmtSfBlnsSum ?? null"
                          :excel-cac="excel?.pmtCac ?? null"
                        />
                        <FemsqWalkTree
                          v-if="showPmtOutline"
                          :key="`outline-${relationTreeKey}`"
                          class="col q-mt-sm"
                          :spec="relationSpec"
                          :root-id="selectedDomain[0].invNumKey"
                          :fetch-node="fetchRelationNode"
                          :fetch-expand="fetchRelationExpand"
                          @action="onRelationAction"
                          data-test="sf-double-tree-outline"
                          root-class="sudz-sf-double-tree"
                        />
                      </template>
                      <FemsqWalkTree
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
                <div
                  class="sudz-sf-hints shrink-0 q-mt-sm q-pa-sm"
                  data-test="sudz-sf-hints"
                >
                  <div class="text-caption text-grey-6 q-mb-xs">
                    Подсказки по контрагенту (исполнитель · БУиРГ или ИНН)
                  </div>
                  <div v-if="hintsLoading" class="text-grey-6">Проверка…</div>
                  <template v-else-if="hints">
                    <div
                      v-for="section in hintSections"
                      :key="section.key"
                      class="sudz-sf-hint-section q-mb-xs"
                    >
                      <div class="text-body2">{{ section.data.message }}</div>
                      <div
                        v-if="section.data.items.length"
                        class="row q-gutter-xs q-mt-xs"
                      >
                        <QBtn
                          v-for="item in section.data.items"
                          :key="`${item.zone}-${item.pickValue}`"
                          dense
                          outline
                          no-caps
                          size="sm"
                          color="primary"
                          :label="item.label || `${item.pickKey}=${item.pickValue}`"
                          :title="`matchBy=${item.matchBy}`"
                          @click="onHintPick(item)"
                        />
                      </div>
                    </div>
                  </template>
                  <div v-else class="text-grey-6">Выберите строку очереди.</div>
                </div>
              </div>
            </template>

            <template #after>
              <QSplitter
                v-if="sumsPaneMode === 'pmt'"
                v-model="sumsForestSplit"
                horizontal
                :limits="[20, 80]"
                separator-class="sudz-split-sep"
                class="fit sudz-sf-splitter"
                data-test="sudz-sf-sums-forest-split"
              >
                <template #before>
                  <div
                    class="column fill-pane no-wrap q-pa-sm"
                    data-test="sudz-sf-sums-tab"
                  >
                    <div class="text-subtitle2 q-mb-xs shrink-0">Суммы</div>
                    <div
                      class="text-caption text-grey-6 q-mb-sm shrink-0"
                      data-test="sudz-sf-sums-pmt"
                    >
                      Итог сальдо по СФ
                      {{ formatMoneyOrDash(pmtSumCompare?.anchorSum ?? excel?.pmtSfBlnsSum ?? null) }}
                      · строк {{ pmtSumCompare?.anchorRows ?? excel?.pmtSfBlnsRows ?? '—' }}.
                      Сверка с долгом связанного свода (ε=0.01).
                    </div>
                    <div
                      class="col column no-wrap overflow-auto"
                      data-test="sudz-sf-sums-pmt-body"
                    >
                      <div class="text-body2 q-mb-sm" data-test="sudz-sf-sums-pmt-outcome">
                        {{ pmtSumOutcome }}
                      </div>
                      <div
                        v-for="match in pmtSumCompare?.matches ?? []"
                        :key="match.cidutKey"
                        class="text-caption q-mb-xs"
                        data-test="sudz-sf-sums-pmt-match"
                      >
                        свод {{ match.dbtUplKey }} · cidut {{ match.cidutKey }}
                        · {{ match.cnName ?? '—' }}
                        · долг {{ formatMoneyOrDash(match.debt) }}
                        · просрочка {{ formatMoneyOrDash(match.debtOverdue) }}
                        · разность {{ formatMoneyOrDash(pmtSumDiff(match.debt)) }}
                      </div>
                    </div>
                  </div>
                </template>
                <template #after>
                  <div class="column fill-pane no-wrap q-pa-sm" data-test="sudz-sf-pm-doc-pane">
                    <PmDocForest
                      v-if="selected"
                      class="col"
                      :cius-key="selected.ciusKey"
                      :doc-focus="caseDocFocus"
                      :doc-code="caseDocCode"
                      @open-inv="onPmDocOpenInv"
                    />
                    <div v-else class="text-grey-6">Выберите строку очереди.</div>
                  </div>
                </template>
              </QSplitter>
              <div
                v-else
                class="column fill-pane no-wrap q-pa-sm"
                data-test="sudz-sf-sums-tab"
              >
                <div class="text-subtitle2 q-mb-xs shrink-0">Суммы</div>
                <div class="text-caption text-grey-6 q-mb-xs shrink-0">
                  Якорь Excel: {{ excelDebtLabel }} · совпадение только по сумме
                  (ε={{ sumMatchEpsilon }})
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
                        Старая структура · cn_inv_dbt
                      </div>
                      <QSplitter
                        v-model="sumsOldSplit"
                        horizontal
                        :limits="[25, 70]"
                        separator-class="sudz-split-sep"
                        class="col sudz-sf-splitter"
                      >
                        <template #before>
                          <FemsqTable
                            fill
                            class="fit"
                            :rows="oldSumRows"
                            :columns="oldSumColumns"
                            row-key="rowKey"
                            dense
                            flat
                            :loading="oldSumLoading"
                            selection="single"
                            v-model:selected="selectedOldSum"
                            :show-filter="false"
                            data-test="sudz-sf-sums-old-list"
                          />
                        </template>
                        <template #after>
                          <div class="q-pa-sm column fill-pane no-wrap">
                            <div v-if="!selectedOldSumRow" class="text-grey-6">
                              Выберите сумму в таблице (старая структура).
                            </div>
                            <FemsqWalkTree
                              v-else
                              :key="`cid-sum-${selectedOldSumRow.cidKey}`"
                              class="col"
                              :spec="cidSumSpec"
                              :root-id="selectedOldSumRow.cidKey"
                              :fetch-node="fetchRelationNode"
                              :fetch-expand="fetchRelationExpand"
                              data-test="sudz-sf-sums-old-tree"
                              root-class="sudz-sf-double-tree"
                            />
                          </div>
                        </template>
                      </QSplitter>
                    </div>
                  </template>
                  <template #after>
                    <div class="column fill-pane no-wrap q-pa-xs">
                      <div class="text-subtitle2 q-px-sm shrink-0">
                        Новая структура · DbtValue
                      </div>
                      <QSplitter
                        v-model="sumsNewSplit"
                        horizontal
                        :limits="[25, 70]"
                        separator-class="sudz-split-sep"
                        class="col sudz-sf-splitter"
                      >
                        <template #before>
                          <FemsqTable
                            fill
                            class="fit"
                            :rows="newSumRows"
                            :columns="newSumColumns"
                            row-key="rowKey"
                            dense
                            flat
                            :loading="newSumLoading"
                            selection="single"
                            v-model:selected="selectedNewSum"
                            :show-filter="false"
                            data-test="sudz-sf-sums-new-list"
                          />
                        </template>
                        <template #after>
                          <div class="q-pa-sm column fill-pane no-wrap">
                            <div v-if="!selectedNewSumRow" class="text-grey-6">
                              Выберите сумму в таблице (новая структура).
                            </div>
                            <FemsqWalkTree
                              v-else
                              :key="`dv-sum-${selectedNewSumRow.dvKey}`"
                              class="col"
                              :spec="dvSumSpec"
                              :root-id="selectedNewSumRow.dvKey"
                              :fetch-node="fetchRelationNode"
                              :fetch-expand="fetchRelationExpand"
                              data-test="sudz-sf-sums-new-tree"
                              root-class="sudz-sf-double-tree"
                            />
                          </div>
                        </template>
                      </QSplitter>
                    </div>
                  </template>
                </QSplitter>
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

import { FemsqTable, FemsqWalkTree, formatMoneyOrDash, moneyColumn, type FemsqTableColumn } from 'fequlib';
import { deleteCnInv, fetchCnNums, updateCnInv } from '@/api/contracts-api';
import RecordModal from '@/components/relation/RecordModal.vue';
import {
  createSudzSfFromDouble,
  getSudzSfDoubleDomainMatches,
  getSudzSfDoubleExcelCandidate,
  getSudzPmtSfExcelCaseRows,
  getSudzPmtSfSumCompare,
  getSudzSfDoubleAdvice,
  getSudzSfDoubleHints,
  getSudzSfDoubleSumMatches,
  linkSudzSfDoubleToCn
} from '@/api/sudz-api';
import PmDocForest from '@/components/sudz/PmDocForest.vue';
import SfDecisionTree from '@/components/sudz/SfDecisionTree.vue';
import { fetchRelationExpand, fetchRelationNode } from '@/api/relation-api';
import { useConnectionStore } from '@/stores/connection';
import { useSudzDbtUplStore } from '@/stores/sudz-dbt-upl';
import { useSudzPmtUplStore } from '@/stores/sudz-pmt-upl';
import { useSudzSfDoubleSessionStore } from '@/stores/sudz-sf-double-session';
import type {
  SudzCnInvUplSfDouble,
  SudzPmtExcelCaseRow,
  SudzPmtSfSumCompare,
  SudzSfDoubleDomainMatch,
  SudzSfDoubleExcelCandidate,
  SudzSfDoubleAdvice,
  SudzSfDoubleHintItem,
  SudzSfDoubleHints
} from '@/types/sudz';
import * as cnPickerSpecJson from '@/trees/cn-picker.tree.json';
import * as contractsInvSpecJson from '@/trees/contracts-inv.tree.json';
import * as cidSumSpecJson from '@/trees/ksdsf-cid-sum.tree.json';
import * as dvSumSpecJson from '@/trees/ksdsf-dv-sum.tree.json';
import * as ksdsfSpec from '@/trees/ksdsf-inv-num.tree.json';
import { buildCnInvLinkForm } from '@/trees/relation-form-registry';
import type { RelationFormState, RelationPickerRow } from '@/trees/relation-forms';
import type { RelationTreeActionContext, RelationTreeSpec } from '@/trees/relation-tree';
import { QBtn, QMarkupTable, QPage, QSplitter, useQuasar } from 'quasar';

type DomainRow = SudzSfDoubleDomainMatch & { rowKey: string };
type PickerCandidateRow = RelationPickerRow & {
  rowKey: string;
  cnKey?: number | null;
  cnNum?: string | null;
  invKey?: number | null;
  invNum?: string | null;
};

/** Строка таблицы сумм старой структуры (`ags.cn_inv_dbt`). */
type OldSumRow = {
  rowKey: string;
  cidKey: number;
  dbtTtl: number | null;
  dbtOverd: number | null;
  number: number | null;
  debtType: string | null;
  ciaKey: number | null;
  ciaName: string | null;
};

/** Строка таблицы сумм новой структуры (`sudz.DbtValue`, M2). */
type NewSumRow = {
  rowKey: string;
  dvKey: number;
  dvTtl: number | null;
  dvOverd: number | null;
  dvUpl: number | null;
  dvInvDbt: number | null;
  dbtKey: number | null;
};

const relationSpec = ksdsfSpec as RelationTreeSpec;
const cnPickerSpec = cnPickerSpecJson as RelationTreeSpec;
const contractsInvSpec = contractsInvSpecJson as RelationTreeSpec;
const cidSumSpec = cidSumSpecJson as RelationTreeSpec;
const dvSumSpec = dvSumSpecJson as RelationTreeSpec;

/** Допуск совпадения суммы с Excel (рубли). */
const sumMatchEpsilon = 0.01;

const connection = useConnectionStore();
const dbtStore = useSudzDbtUplStore();
const pmtStore = useSudzPmtUplStore();
const session = useSudzSfDoubleSessionStore();
const $q = useQuasar();

/** Ширина левой колонки (очередь + Excel), %. */
const queueSplit = ref(22);
/** Высота очереди внутри левой колонки, % (Excel — остаток снизу). */
const queueExcelSplit = ref(55);
/** Высота Excel относительно советника, % — и в платежах, и в своде. */
const excelAdvisorSplit = ref(58);
/** Сводка Excel / белые строки кейса (pmt), %. */
const excelCaseSplit = ref(42);
/** Высота блока «Суммы» относительно леса документов, %. */
const sumsForestSplit = ref(38);
/** Ширина панели «СФ» относительно «Суммы», %. */
const sfSumsSplit = ref(50);
const domainSplit = ref(45);
const sumsOldNewSplit = ref(50);
const sumsOldSplit = ref(40);
const sumsNewSplit = ref(40);
const loading = ref(false);
const creating = ref(false);
const advisorLinking = ref(false);
const excelLoading = ref(false);
const domainLoading = ref(false);
const error = ref<string | null>(null);
const selectedRows = ref<SudzCnInvUplSfDouble[]>([]);
const excel = ref<SudzSfDoubleExcelCandidate | null>(null);
const pmtCaseRows = ref<SudzPmtExcelCaseRow[]>([]);
/** Выбранная белая строка кейса → фокус леса документов. */
const selectedCaseRows = ref<SudzPmtExcelCaseRow[]>([]);
const pmtSumCompare = ref<SudzPmtSfSumCompare | null>(null);

/** Фокус леса на белой строке (не весь кейс). */
const caseDocFocus = computed(
  () => excel.value?.source === 'pmt' && selectedCaseRows.value.length > 0
);

/** «№ докум.» выбранной белой строки; null если пусто. */
const caseDocCode = computed(() => {
  const raw = selectedCaseRows.value[0]?.docCode;
  if (raw == null || String(raw).trim() === '') {
    return null;
  }
  return String(raw).trim();
});

/**
 * Строка по умолчанию: якорь очереди (ciput) или первая белая.
 *
 * @param rows белые строки кейса
 * @param anchorCiput ciputKey якоря карточки
 */
function pickDefaultCaseRows(
  rows: SudzPmtExcelCaseRow[],
  anchorCiput: number | null | undefined
): SudzPmtExcelCaseRow[] {
  if (!rows.length) {
    return [];
  }
  const hit = anchorCiput != null
    ? rows.find((row) => row.ciputKey === anchorCiput)
    : undefined;
  return [hit ?? rows[0]];
}
const domainMatches = ref<DomainRow[]>([]);

/**
 * «Открыть дерево СФ» из леса документов: выбрать эту inv в списке совпадений.
 */
function onPmDocOpenInv(invKey: number): void {
  const row = domainMatches.value.find((item) => item.invKey === invKey);
  if (!row) {
    $q.notify({
      type: 'info',
      message: `СФ inv=${invKey} нет среди совпадений по номеру файла`
    });
    return;
  }
  selectedDomain.value = [row];
}
const selectedDomain = ref<DomainRow[]>([]);
const oldSumRows = ref<OldSumRow[]>([]);
const newSumRows = ref<NewSumRow[]>([]);
const selectedOldSum = ref<OldSumRow[]>([]);
const selectedNewSum = ref<NewSumRow[]>([]);
const oldSumLoading = ref(false);
const newSumLoading = ref(false);
const hintsLoading = ref(false);
const advisorLoading = ref(false);
const hints = ref<SudzSfDoubleHints | null>(null);
const advisor = ref<SudzSfDoubleAdvice | null>(null);
const relationAction = ref<RelationTreeActionContext | null>(null);
const linkModalOpen = ref(false);
const selectedCnCandidate = ref<PickerCandidateRow | null>(null);
const linkSaveError = ref<string | null>(null);
const linkSaveLoading = ref(false);
const relationTreeKey = ref(0);
/** Техн. outline ksdsf-inv-num под decision-TreeList (только pmt). */
const showPmtOutline = ref(false);
const cnInvFormMode = computed<'create' | 'edit'>(() =>
  relationAction.value?.actionId === 'cnInv.link.edit' ? 'edit' : 'create'
);

const cnAllRows = ref<PickerCandidateRow[]>([]);
const cnAllLoading = ref(false);

const unloadKey = computed(() =>
  session.source === 'pmt' ? pmtStore.selectedPmKey : dbtStore.selectedUplKey
);
const unloadLabel = computed(() => (session.source === 'pmt' ? 'pm' : 'upl'));
const backLabel = computed(() =>
  session.source === 'pmt' ? 'К загрузке платежей' : 'К загрузке свода'
);
const emptyUnloadHint = computed(() =>
  session.source === 'pmt'
    ? 'Выберите пакет на экране «Загрузка платежей».'
    : 'Выберите выгрузку на экране «Загрузка свода».'
);
const rows = computed(() =>
  session.source === 'pmt' ? pmtStore.sfDoubles : dbtStore.sfDoubles
);
const openCount = computed(() => rows.value.filter((r) => r.ciusStatus === 'open').length);
const selected = computed(() => selectedRows.value[0] ?? null);
const canCreate = computed(
  () => selected.value != null && selected.value.ciusStatus === 'open' && !!selected.value.ciusCnKey
);
const showAdvisorLinkBtn = computed(
  () => advisor.value?.action === 'link' || advisor.value?.action === 'alias_cn_num'
);
const advisorLinkHighlight = computed(() => {
  const adv = advisor.value;
  return adv?.action === 'link' && (adv.confidence === 'high' || adv.confidence === 'medium');
});
const canAdvisorLink = computed(() => {
  const row = selected.value;
  const adv = advisor.value;
  if (row == null || row.ciusStatus !== 'open' || adv == null) {
    return false;
  }
  if (adv.action !== 'link' && adv.action !== 'alias_cn_num') {
    return false;
  }
  const invKey = adv.recommendInvKey ?? selectedDomainRow.value?.invKey;
  const cnKey = adv.recommendCnKey ?? row.ciusCnKey;
  return invKey != null && cnKey != null && cnKey > 0;
});
const advisorCreateHighlight = computed(
  () => advisor.value?.action === 'create' && advisor.value?.confidence === 'high'
);
const messagesText = computed(() => advisor.value?.messageText?.trim() ?? '');
const advisorSummary = computed(() => {
  const adv = advisor.value;
  if (!adv?.action) return '';
  return `советник: ${actionRu(adv.action)} · уверенность: ${confidenceRu(adv.confidence)}`;
});
const selectedDomainRow = computed(() => selectedDomain.value[0] ?? null);
const selectedOldSumRow = computed(() => selectedOldSum.value[0] ?? null);
const selectedNewSumRow = computed(() => selectedNewSum.value[0] ?? null);
const excelDebtLabel = computed(() => {
  const e = excel.value;
  if (!e) {
    return 'сумма не загружена';
  }
  if (e.source === 'pmt') {
    return `платёж · итог сальдо ${formatMoneyOrDash(e.pmtSfBlnsSum)} · строк ${e.pmtSfBlnsRows ?? '—'}`;
  }
  const debt = e.cidutDebt;
  if (debt == null) {
    return 'сумма не загружена';
  }
  return String(debt);
});

/** Режим панели сумм: dbt — долг; pmt — итог сальдо против связанного свода. */
const sumsPaneMode = computed<'dbt' | 'pmt'>(() =>
  excel.value?.source === 'pmt' || session.source === 'pmt' ? 'pmt' : 'dbt'
);

const pmtSumOutcome = computed(() => {
  const compare = pmtSumCompare.value;
  if (!compare) {
    return 'Сверка со сводом не загружена.';
  }
  if (!compare.linked) {
    return 'Нет связи g_p пакета со сводом.';
  }
  if (compare.matches.length === 0) {
    return 'Строки свода нет.';
  }
  if (compare.matches.length > 1) {
    return 'Несколько строк свода — без автовыбора.';
  }
  const diff = pmtSumDiff(compare.matches[0].debt);
  if (diff != null && Math.abs(diff) <= 0.01) {
    return 'Совпало.';
  }
  return `Разошлось на ${formatMoneyOrDash(diff)}.`;
});

function pmtSumDiff(debt: number | null): number | null {
  const anchor = pmtSumCompare.value?.anchorSum ?? excel.value?.pmtSfBlnsSum ?? null;
  if (anchor == null || debt == null) {
    return null;
  }
  return Math.round((debt - anchor) * 100) / 100;
}

const hintSections = computed(() => {
  const data = hints.value;
  if (!data) return [];
  if (sumsPaneMode.value === 'pmt') {
    return [{ key: 'sfByNum', data: data.sfByNum }];
  }
  return [
    { key: 'sfByNum', data: data.sfByNum },
    { key: 'sumsOld', data: data.sumsOld },
    { key: 'sumsNew', data: data.sumsNew }
  ];
});

const queueColumns: FemsqTableColumn<SudzCnInvUplSfDouble>[] = [
  { name: 'ciusStatus', label: 'статус', field: 'ciusStatus', align: 'left' },
  { name: 'ciusCnNum', label: 'Договор', field: 'ciusCnNum', align: 'left' },
  { name: 'ciusInvNum', label: 'СФ', field: 'ciusInvNum', align: 'left' },
  { name: 'ciusInvNumCount', label: 'совпад.', field: 'ciusInvNumCount', align: 'right' },
  {
    name: 'tblKey',
    label: 'Tbl',
    field: (row) => row.ciusCiput ?? row.ciusCidut,
    align: 'right'
  }
];

const domainColumns: FemsqTableColumn<DomainRow>[] = [
  { name: 'invKey', label: 'inv', field: 'invKey', align: 'right' },
  { name: 'invNum', label: 'номер', field: 'invNum', align: 'left' },
  { name: 'cnNum', label: 'договор', field: 'cnNum', align: 'left' },
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  {
    name: 'party',
    label: 'исполнители',
    field: (row) => row.cntrPrtName ?? '—',
    align: 'left'
  }
];

const oldSumColumns: FemsqTableColumn<OldSumRow>[] = [
  { name: 'cidKey', label: 'cid', field: 'cidKey', align: 'right' },
  { name: 'number', label: '№', field: 'number', align: 'right' },
  { name: 'ciaName', label: 'ciaName', field: 'ciaName', align: 'left' },
  moneyColumn({ name: 'dbtTtl', label: 'сумма', field: 'dbtTtl' }),
  moneyColumn({ name: 'dbtOverd', label: 'просроч.', field: 'dbtOverd' }),
  { name: 'debtType', label: 'тип', field: 'debtType', align: 'left' }
];

const newSumColumns: FemsqTableColumn<NewSumRow>[] = [
  { name: 'dvKey', label: 'dv', field: 'dvKey', align: 'right' },
  { name: 'dvInvDbt', label: 'invDbt', field: 'dvInvDbt', align: 'right' },
  { name: 'dbtKey', label: 'dbt', field: 'dbtKey', align: 'right' },
  moneyColumn({ name: 'dvTtl', label: 'сумма', field: 'dvTtl' }),
  moneyColumn({ name: 'dvOverd', label: 'просроч.', field: 'dvOverd' }),
  { name: 'dvUpl', label: 'upl', field: 'dvUpl', align: 'right' }
];

const pickerColumns: FemsqTableColumn<PickerCandidateRow>[] = [
  { name: 'cnKey', label: 'cn', field: 'cnKey', align: 'right' },
  { name: 'cnNum', label: 'договор', field: 'cnNum', align: 'left' },
  { name: 'invKey', label: 'inv', field: 'invKey', align: 'right' },
  { name: 'invNum', label: 'СФ', field: 'invNum', align: 'left' }
];

const pmtCaseColumns: FemsqTableColumn<SudzPmtExcelCaseRow>[] = [
  { name: 'ciputKey', label: 'ciput', field: 'ciputKey', align: 'right' },
  { name: 'docCode', label: '№ докум.', field: 'docCode', align: 'left' },
  { name: 'link', label: 'Ссылка', field: 'link', align: 'left' },
  { name: 'cac', label: 'стройка', field: 'cac', align: 'left' },
  { name: 'entryDate', label: 'проводка', field: 'entryDate', align: 'left' },
  { name: 'dueDate', label: 'срок', field: 'dueDate', align: 'left' },
  moneyColumn({ name: 'blns', label: 'сальдо', field: 'blns' }),
  moneyColumn({ name: 'cdtBlns', label: 'кредит', field: 'cdtBlns' }),
  moneyColumn({ name: 'docSum', label: 'сумма док.', field: 'docSum' }),
  { name: 'dueGrp', label: 'due_grp', field: 'dueGrp', align: 'right' }
];

const excelRows = computed(() => {
  const e = excel.value;
  if (!e) return [];
  if (e.source === 'pmt') {
    return [
      { label: 'источник', value: 'платежи (ciput)' },
      { label: 'якорь ciputKey', value: String(e.cidutKey) },
      { label: 'лист', value: String(e.cidutSheetNum ?? '—') },
      { label: 'БЕ', value: e.pmtBe ?? '—' },
      { label: 'стройка (CAC)', value: e.pmtCac ?? '—' },
      { label: 'БУиРГ', value: String(e.cidutCntrPrtNum ?? '—') },
      { label: 'счёт ГК', value: e.cidutAccntNum ?? e.cidutAccount ?? '—' },
      {
        label: 'агент',
        value:
          e.pmtAgentNum != null || e.pmtAgentName
            ? `${e.pmtAgentNum ?? '—'} · ${e.pmtAgentName ?? '—'}`
            : '—'
      },
      { label: 'контрагент', value: e.cidutCntrPrtName ?? '—' },
      { label: 'договор (Excel)', value: e.cidutCnName ?? '—' },
      { label: 'СФ (присвоение)', value: e.cidutCnInv ?? '—' },
      {
        label: 'итог сальдо по СФ',
        value: `${formatMoneyOrDash(e.pmtSfBlnsSum)} · строк ${e.pmtSfBlnsRows ?? '—'}`
      }
    ];
  }
  return [
    { label: 'источник', value: 'свод (cidut)' },
    { label: 'FindDbtNum / cidutKey', value: `${e.findDbtNum ?? '—'} / ${e.cidutKey}` },
    { label: 'лист / строка', value: `${e.cidutSheet ?? '—'} / ${e.cidutSheetNum ?? '—'}` },
    { label: 'БУиРГ', value: String(e.cidutCntrPrtNum ?? '—') },
    { label: 'счёт ГК', value: e.cidutAccntNum ?? e.cidutAccount ?? '—' },
    { label: 'контрагент', value: e.cidutCntrPrtName ?? '—' },
    { label: 'ИНН', value: e.cidutCntrPrtITN ?? '—' },
    { label: 'договор', value: e.cidutCnName ?? '—' },
    { label: 'дата договора', value: e.cidutCnDate ?? '—' },
    { label: 'СФ', value: e.cidutCnInv ?? '—' },
    { label: 'имя СФ', value: e.cidutCnInvName ?? '—' },
    {
      label: 'дата обр. / погаш.',
      value: `${e.cidutFormtnDate ?? '—'} / ${e.cidutMatrtyDate ?? '—'}`
    },
    {
      label: 'долг / просрочка',
      value: `${formatMoneyOrDash(e.cidutDebt)} / ${formatMoneyOrDash(e.cidutDebtOverdue)}`
    },
    { label: '№ докум.', value: e.cidutDoc ?? '—' },
    { label: 'Ссылка', value: e.cidutLink ?? '—' }
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
  applyAnchorSelection();
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

/**
 * Выделяет строку очереди по якорю из session (вход с D / C).
 */
function applyAnchorSelection(): void {
  const key = session.anchorCiusKey;
  if (key == null) {
    return;
  }
  const row = rows.value.find((r) => r.ciusKey === key);
  if (row) {
    selectedRows.value = [row];
  }
  session.clearAnchor();
}

/**
 * Перечитывает очередь КСДСФ у источника (dbt launcher / pmt list).
 */
async function refreshQueue(): Promise<void> {
  if (session.source === 'pmt') {
    await pmtStore.refreshSfDoubles();
    return;
  }
  if (dbtStore.selectedUplKey != null) {
    await dbtStore.selectUpl(dbtStore.selectedUplKey);
  }
}

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
    pmtCaseRows.value = [];
    selectedCaseRows.value = [];
    pmtSumCompare.value = null;
    domainMatches.value = [];
    selectedDomain.value = [];
    oldSumRows.value = [];
    newSumRows.value = [];
    selectedOldSum.value = [];
    selectedNewSum.value = [];
    hints.value = null;
    advisor.value = null;
    relationAction.value = null;
    linkModalOpen.value = false;
    selectedCnCandidate.value = null;
    if (!row) return;
    excelLoading.value = true;
    domainLoading.value = true;
    oldSumLoading.value = true;
    newSumLoading.value = true;
    hintsLoading.value = true;
    advisorLoading.value = true;
    error.value = null;
    try {
      excel.value = await getSudzSfDoubleExcelCandidate(row.ciusKey);
      if (excel.value?.source === 'pmt') {
        pmtCaseRows.value = await getSudzPmtSfExcelCaseRows(row.ciusKey);
        selectedCaseRows.value = pickDefaultCaseRows(
          pmtCaseRows.value,
          excel.value.cidutKey
        );
        pmtSumCompare.value = await getSudzPmtSfSumCompare(row.ciusKey);
      } else {
        pmtCaseRows.value = [];
        selectedCaseRows.value = [];
        pmtSumCompare.value = null;
      }
      const inv = row.ciusInvNum ?? '';
      const matches = inv ? await getSudzSfDoubleDomainMatches(inv) : [];
      domainMatches.value = matches.map((m, i) => ({
        ...m,
        rowKey: `${m.invKey}-${m.ciKey ?? 'x'}-${i}`
      }));
      const debt = excel.value?.cidutDebt;
      if (debt != null && Number.isFinite(debt)) {
        const sums = await getSudzSfDoubleSumMatches(debt, sumMatchEpsilon);
        oldSumRows.value = sums.oldMatches.map((m) => ({
          rowKey: String(m.cidKey),
          cidKey: m.cidKey,
          number: m.number,
          dbtTtl: m.dbtTtl,
          dbtOverd: m.dbtOverd,
          debtType: m.debtType,
          ciaKey: m.ciaKey,
          ciaName: m.ciaName
        }));
        newSumRows.value = sums.newMatches.map((m) => ({
          rowKey: String(m.dvKey),
          dvKey: m.dvKey,
          dvTtl: m.dvTtl,
          dvOverd: m.dvOverd,
          dvUpl: m.dvUpl,
          dvInvDbt: m.dvInvDbt,
          dbtKey: m.dbtKey
        }));
      }
      const [hintsResult, advisorResult] = await Promise.all([
        getSudzSfDoubleHints(row.ciusKey, sumMatchEpsilon),
        getSudzSfDoubleAdvice(row.ciusKey, sumMatchEpsilon)
      ]);
      hints.value = hintsResult;
      advisor.value = advisorResult;
      applyAdvisorInvPick(advisorResult);
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e);
    } finally {
      excelLoading.value = false;
      domainLoading.value = false;
      oldSumLoading.value = false;
      newSumLoading.value = false;
      hintsLoading.value = false;
      advisorLoading.value = false;
    }
  },
  { immediate: true }
);

/**
 * Pre-select СФ по recommendInvKey из советника.
 *
 * @param adv ответ API
 */
function applyAdvisorInvPick(adv: SudzSfDoubleAdvice | null): void {
  const invKey = adv?.recommendInvKey;
  if (invKey == null) return;
  const row = domainMatches.value.find((m) => m.invKey === invKey);
  if (row) {
    selectedDomain.value = [row];
  }
}

/**
 * Человекочитаемый код действия советника.
 */
function actionRu(action: string | null | undefined): string {
  switch (action) {
    case 'link':
      return 'связать';
    case 'alias_cn_num':
      return 'добавить номер договора';
    case 'create':
      return 'создать СФ';
    case 'manual':
      return 'вручную';
    default:
      return action ?? '—';
  }
}

/**
 * Человекочитаемая уверенность советника.
 */
function confidenceRu(confidence: string | null | undefined): string {
  switch (confidence) {
    case 'high':
      return 'высокая';
    case 'medium':
      return 'средняя';
    case 'low':
      return 'низкая';
    case 'none':
      return 'нет';
    default:
      return confidence ?? '—';
  }
}

/**
 * Выбор строки СФ/сумм по ключу из подсказки.
 *
 * @param item элемент подсказки
 */
function onHintPick(item: SudzSfDoubleHintItem): void {
  if (item.zone === 'sf') {
    const row =
      domainMatches.value.find((m) => m.invNumKey === item.pickValue) ??
      domainMatches.value.find((m) => m.invKey === item.invKey);
    if (row) {
      selectedDomain.value = [row];
    }
    return;
  }
  if (item.zone === 'sumsOld') {
    const row = oldSumRows.value.find((m) => m.cidKey === item.pickValue);
    if (row) {
      selectedOldSum.value = [row];
    }
    return;
  }
  if (item.zone === 'sumsNew') {
    const row = newSumRows.value.find((m) => m.dvKey === item.pickValue);
    if (row) {
      selectedNewSum.value = [row];
    }
  }
}

/**
 * Возврат на экран-источник (свод или платежи).
 */
function goBack(): void {
  connection.navigate(session.source === 'pmt' ? 'sudz-pmt-upl' : 'sudz-dbt-upl');
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
 * Привязка по рекомендации советника (inv + cn из Excel).
 */
async function onAdvisorLink(): Promise<void> {
  const row = selected.value;
  const adv = advisor.value;
  if (row == null || !canAdvisorLink.value || adv == null) {
    return;
  }
  if (adv.action !== 'link' && adv.action !== 'alias_cn_num') {
    return;
  }
  const invKey = adv.recommendInvKey ?? selectedDomainRow.value?.invKey;
  const cnKey = adv.recommendCnKey ?? row.ciusCnKey;
  if (invKey == null || cnKey == null) {
    return;
  }
  advisorLinking.value = true;
  error.value = null;
  try {
    const updated = await linkSudzSfDoubleToCn({ ciusKey: row.ciusKey, invKey, cnKey });
    await refreshQueue();
    const refreshed = rows.value.find((r) => r.ciusKey === updated.ciusKey) ?? updated;
    selectedRows.value = [refreshed];
    $q.notify({
      type: 'positive',
      message: `Связано: inv=${invKey} · cn=${cnKey}`,
      timeout: 2500
    });
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  } finally {
    advisorLinking.value = false;
  }
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
    await refreshQueue();
    const refreshed = rows.value.find((r) => r.ciusKey === updated.ciusKey) ?? updated;
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
    await refreshQueue();
    const refreshed = rows.value.find((r) => r.ciusKey === updated.ciusKey) ?? updated;
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
/** Поля Excel-кандидата: вертикальный скролл (flex-col или панель splitter). */
.sudz-sf-excel-fields {
  min-height: 0;
  overflow: auto;
}
.sudz-sf-splitter :deep(> .q-splitter__panel) > .sudz-sf-excel-fields {
  height: 100%;
  box-sizing: border-box;
}
.sudz-sf-double-tree {
  min-height: 0;
}
.sudz-sf-hints {
  max-height: 28%;
  overflow: auto;
  border-top: 1px solid rgba(255, 255, 255, 0.12);
}
.sudz-sf-messages {
  overflow: hidden;
}
.sudz-sf-queue-actions {
  flex-wrap: wrap;
}
.sudz-sf-messages-body {
  margin: 0;
  min-height: 0;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.35;
}
.sudz-sf-hint-section {
  line-height: 1.35;
}
</style>
