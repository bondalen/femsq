<template>
  <div class="column no-wrap sf-decision-tree" data-test="sudz-sf-decision-tree">
    <div
      v-if="profile"
      class="row q-gutter-xs q-mb-xs items-center shrink-0"
      data-test="sudz-sf-decision-compare"
    >
      <span class="text-caption text-grey-7">Сверка Excel:</span>
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.invNumVerdict)"
        text-color="white"
        :label="`номер · ${decisionVerdictLabel(profile.compare.invNumVerdict)}`"
        data-test="sudz-sf-decision-cmp-inv"
      />
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.cnVerdict)"
        text-color="white"
        :label="`договор · ${decisionVerdictLabel(profile.compare.cnVerdict)}`"
        data-test="sudz-sf-decision-cmp-cn"
      />
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.executorVerdict)"
        text-color="white"
        :label="`исполнитель · ${decisionVerdictLabel(profile.compare.executorVerdict)}`"
        data-test="sudz-sf-decision-cmp-executor"
      />
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.sumVerdict)"
        text-color="white"
        :label="`сумма · ${decisionVerdictLabel(profile.compare.sumVerdict)}`"
        data-test="sudz-sf-decision-cmp-sum"
      />
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.cstVerdict)"
        text-color="white"
        :label="`стройка · ${decisionVerdictLabel(profile.compare.cstVerdict)}`"
        data-test="sudz-sf-decision-cmp-cst"
      />
      <QChip
        dense
        size="sm"
        :color="decisionVerdictColor(profile.compare.docTransferVerdict)"
        text-color="white"
        :label="`доки · ${decisionVerdictLabel(profile.compare.docTransferVerdict)}`"
        data-test="sudz-sf-decision-cmp-docxfer"
      />
      <span class="text-caption text-grey-6">
        inv {{ profile.invKey }}
        · cnInv {{ profile.preferredCiKey ?? '—' }}
        · pm {{ profile.pmCount }}
        · Σ {{ formatMoneyOrDash(profile.blnsSum) }}
        <template v-if="(profile.invNums?.length ?? 0) > 1">
          · номеров {{ profile.invNums.length }}
        </template>
        <template v-if="profile.currentUplKey != null">
          · пакет {{ profile.currentUplKey }} Σ
          {{ formatMoneyOrDash(profile.currentUplBlnsSum) }}
        </template>
      </span>
      <span
        v-if="profile.cntrPrtNum != null || profile.cntrPrtName"
        class="text-caption text-grey-6"
        data-test="sudz-sf-decision-party"
      >
        · {{ profile.cntrPrtNum ?? '—' }}
        {{ profile.cntrPrtName ? ` · ${profile.cntrPrtName}` : '' }}
      </span>
    </div>
    <div v-if="loading" class="text-grey-6">Загрузка профиля СФ…</div>
    <div v-else-if="errorText" class="text-negative">{{ errorText }}</div>
    <div v-else-if="!invKey" class="text-grey-6">Выберите СФ в списке совпадений.</div>
    <FemsqWalkTree
      v-else-if="profile"
      class="col"
      :key="treeKey"
      :spec="spec"
      :root-id="invKey"
      :roots-token="token"
      :fetch-node="fetchNode"
      :fetch-expand="fetchExpand"
      :fetch-query="fetchQuery"
      data-test="sudz-sf-decision-walk"
      root-class="sudz-sf-decision-walk"
    />
  </div>
</template>

<script setup lang="ts">
/**
 * Центр КСДСФ pmt: decision-TreeList кандидата СФ (платежи / документы / cias).
 */
import { computed, ref, watch } from 'vue';
import { FemsqWalkTree, formatMoneyOrDash, type FemsqWalkFetchRow, type FemsqWalkTreeSpec } from 'fequlib';
import { QChip } from 'quasar';

import { getSudzSfDecisionProfile } from '@/api/sudz-api';
import {
  decisionQueryRows,
  decisionRootRow,
  decisionRootsToken,
  decisionVerdictColor,
  decisionVerdictLabel
} from '@/sudz/ksdsf-inv-decision';
import type { SudzSfDecisionProfile } from '@/types/sudz';
import * as specJson from '@/trees/ksdsf-inv-decision.tree.json';

const props = defineProps<{
  invKey: number | null;
  currentUplKey?: number | null;
  excelCnText?: string | null;
  excelInvNum?: string | null;
  excelCntrPrtNum?: number | null;
  excelBlnsSum?: number | null;
  excelCac?: string | null;
}>();

const spec = specJson as FemsqWalkTreeSpec;
const profile = ref<SudzSfDecisionProfile | null>(null);
const loading = ref(false);
const errorText = ref('');
const treeKey = ref(0);

const token = computed(() => decisionRootsToken(profile.value));

watch(
  () =>
    [
      props.invKey,
      props.currentUplKey ?? null,
      props.excelCnText ?? null,
      props.excelInvNum ?? null,
      props.excelCntrPrtNum ?? null,
      props.excelBlnsSum ?? null,
      props.excelCac ?? null
    ] as const,
  () => {
    void load();
  },
  { immediate: true }
);

/**
 * Грузит профиль кандидата.
 */
async function load(): Promise<void> {
  errorText.value = '';
  if (props.invKey == null || props.invKey <= 0) {
    profile.value = null;
    return;
  }
  loading.value = true;
  try {
    profile.value = await getSudzSfDecisionProfile({
      invKey: props.invKey,
      currentUplKey: props.currentUplKey,
      excelCnText: props.excelCnText,
      excelInvNum: props.excelInvNum,
      excelCntrPrtNum: props.excelCntrPrtNum,
      excelBlnsSum: props.excelBlnsSum,
      excelCac: props.excelCac
    });
    treeKey.value += 1;
  } catch (error) {
    profile.value = null;
    errorText.value =
      error instanceof Error ? error.message : 'Не удалось прочитать профиль СФ';
  } finally {
    loading.value = false;
  }
}

/**
 * Корень inv из кэша профиля.
 */
async function fetchNode(table: string, id: number): Promise<FemsqWalkFetchRow | null> {
  if (table !== 'inv' || !profile.value || id !== profile.value.invKey) {
    return null;
  }
  return decisionRootRow(profile.value);
}

/**
 * Рёбра каталога не используются.
 */
async function fetchExpand(): Promise<FemsqWalkFetchRow[]> {
  return [];
}

/**
 * Платежи / документы / cias / долги.
 */
async function fetchQuery(queryId: string, fromId: number): Promise<FemsqWalkFetchRow[]> {
  if (!profile.value) {
    return [];
  }
  return decisionQueryRows(queryId, fromId, profile.value);
}
</script>

<style scoped>
.sf-decision-tree {
  min-height: 0;
  height: 100%;
  flex: 1 1 auto;
  overflow: auto;
}
</style>
