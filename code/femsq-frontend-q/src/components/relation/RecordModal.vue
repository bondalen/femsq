<template>
  <QDialog :model-value="modelValue" maximized @update:model-value="onDialogToggle">
    <QCard class="column no-wrap">
      <QCardSection class="row items-center q-gutter-sm">
        <div class="text-subtitle1">{{ form.title }}</div>
        <QSpace />
        <QBtn flat dense icon="close" @click="close" />
      </QCardSection>

      <QCardSection class="q-pt-none">
        <div class="column q-gutter-sm">
          <QInput
            v-for="field in form.fields"
            :key="field.name"
            :model-value="formatField(field)"
            :label="field.label"
            dense
            outlined
            readonly
          />
        </div>
      </QCardSection>

      <QSeparator />

      <QCardSection class="col column no-wrap q-pa-sm">
        <QTabs v-model="activePickerId" dense active-color="primary" class="shrink-0">
          <QTab
            v-for="picker in form.pickers"
            :key="picker.id"
            :name="picker.id"
            :label="picker.tabLabel"
            :disable="picker.disabled"
            no-caps
          />
        </QTabs>
        <QTabPanels v-model="activePickerId" animated class="col column no-wrap">
          <QTabPanel
            v-for="picker in form.pickers"
            :key="picker.id"
            :name="picker.id"
            class="q-pa-none col column no-wrap"
          >
            <div v-if="picker.kind === 'lookup-list'" class="q-pa-md text-grey-6">
              Lookup-list skeleton.
            </div>
            <QSplitter v-else v-model="pickerSplit" :limits="[25, 70]" horizontal class="col">
              <template #before>
                <FemsqTable
                  class="fit"
                  :rows="picker.rows"
                  :columns="picker.columns"
                  row-key="rowKey"
                  dense
                  flat
                  selection="single"
                  :selected="picker.selected"
                  @update:selected="emitSelect(picker, $event)"
                />
              </template>
              <template #after>
                <div class="q-pa-sm column fill-pane no-wrap">
                  <div v-if="picker.treeSpec == null || picker.treeRootId == null" class="text-grey-6">
                    Выберите строку в таблице.
                  </div>
                  <RelationTree
                    v-else
                    class="col"
                    :spec="picker.treeSpec"
                    :root-id="picker.treeRootId"
                    :fetch-node="props.fetchNode"
                    :fetch-expand="props.fetchExpand"
                    root-class="relation-record-modal-tree"
                  />
                </div>
              </template>
            </QSplitter>
          </QTabPanel>
        </QTabPanels>
      </QCardSection>

      <QSeparator />

      <QCardActions align="right">
        <QBtn flat no-caps label="Отмена" @click="close" />
        <QBtn color="primary" unelevated no-caps label="OK" @click="emit('save')" />
      </QCardActions>
    </QCard>
  </QDialog>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

import { FemsqTable } from 'fequlib';
import { QBtn, QCard, QCardActions, QCardSection, QDialog, QInput, QSeparator, QSpace, QSplitter, QTab, QTabPanel, QTabPanels, QTabs } from 'quasar';

import RelationTree from '@/components/relation/RelationTree.vue';
import type { RelationFetchExpand, RelationFetchNode } from '@/trees/relation-tree';
import type { RelationFormFieldState, RelationFormState, RelationPickerState } from '@/trees/relation-forms';

const props = defineProps<{
  modelValue: boolean;
  form: RelationFormState;
  fetchNode: RelationFetchNode;
  fetchExpand: RelationFetchExpand;
}>();

const emit = defineEmits<{
  'update:modelValue': [value: boolean];
  'picker-select': [pickerId: string, rowKey: string | null];
  save: [];
}>();

const pickerSplit = ref(38);
const activePickerId = ref('');

watch(
  () => props.form.id,
  () => {
    activePickerId.value = props.form.pickers[0]?.id ?? '';
  },
  { immediate: true }
);

function formatField(field: RelationFormFieldState): string {
  const display = field.displayValue ?? field.value;
  if (display == null || display === '') {
    return '—';
  }
  return String(display);
}

function onDialogToggle(value: boolean): void {
  emit('update:modelValue', value);
}

function close(): void {
  emit('update:modelValue', false);
}

function emitSelect(
  picker: RelationPickerState,
  selected: Array<{ rowKey?: string | null }> | undefined
): void {
  emit('picker-select', picker.id, selected?.[0]?.rowKey ?? null);
}
</script>

<style scoped>
.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.relation-record-modal-tree {
  min-height: 0;
}
</style>
