<template>
  <QDialog :model-value="modelValue" maximized @update:model-value="onDialogToggle">
    <QCard class="column no-wrap">
      <QCardSection class="row items-center q-gutter-sm">
        <div class="text-subtitle1">{{ form.title }}</div>
        <QSpace />
        <QBtn flat dense icon="close" @click="close" />
      </QCardSection>

      <QCardSection class="q-pt-none">
        <QBanner v-if="props.saveError" class="bg-negative text-white q-mb-sm" rounded dense>
          {{ props.saveError }}
        </QBanner>
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
            <div v-if="picker.kind === 'lookup-list'" class="col column no-wrap">
              <div v-if="picker.searchPlaceholder" class="row items-end q-col-gutter-sm q-pa-sm">
                <div class="col">
                  <QInput
                    :model-value="pickerSearch[picker.id] ?? ''"
                    :label="picker.searchPlaceholder"
                    :hint="picker.searchHint"
                    :loading="picker.searchLoading"
                    dense
                    outlined
                    @update:model-value="setPickerSearch(picker, $event)"
                    @keyup.enter="emitSearch(picker)"
                  />
                </div>
                <div class="shrink-0">
                  <QBtn
                    color="primary"
                    unelevated
                    no-caps
                    label="Найти"
                    :loading="picker.searchLoading"
                    @click="emitSearch(picker)"
                  />
                </div>
                <div class="shrink-0">
                  <QBtn flat no-caps label="Очистить" @click="clearSearch(picker)" />
                </div>
              </div>
              <div v-if="picker.searchStatus" class="q-px-sm q-pb-sm text-caption text-grey-7">
                {{ picker.searchStatus }}
              </div>
              <FemsqTable
                class="fit"
                :rows="picker.rows"
                :columns="picker.columns"
                row-key="rowKey"
                dense
                flat
                :show-filter="false"
                selection="single"
                :selected="picker.selected"
                @update:selected="emitSelect(picker, $event)"
              />
            </div>
            <QSplitter v-else v-model="pickerSplit" :limits="[25, 70]" horizontal class="col">
              <template #before>
                <div class="fit column no-wrap">
                  <div v-if="picker.searchPlaceholder" class="row items-end q-col-gutter-sm q-pa-sm">
                    <div class="col">
                      <QInput
                        :model-value="pickerSearch[picker.id] ?? ''"
                        :label="picker.searchPlaceholder"
                        :hint="picker.searchHint"
                        :loading="picker.searchLoading"
                        dense
                        outlined
                        @update:model-value="setPickerSearch(picker, $event)"
                        @keyup.enter="emitSearch(picker)"
                      />
                    </div>
                    <div class="shrink-0">
                      <QBtn
                        color="primary"
                        unelevated
                        no-caps
                        label="Найти"
                        :loading="picker.searchLoading"
                        @click="emitSearch(picker)"
                      />
                    </div>
                    <div class="shrink-0">
                      <QBtn flat no-caps label="Очистить" @click="clearSearch(picker)" />
                    </div>
                  </div>
                  <div v-if="picker.searchStatus" class="q-px-sm q-pb-sm text-caption text-grey-7">
                    {{ picker.searchStatus }}
                  </div>
                  <FemsqTable
                    class="col"
                    :rows="picker.rows"
                    :columns="picker.columns"
                    row-key="rowKey"
                    dense
                    flat
                    :show-filter="false"
                    selection="single"
                    :selected="picker.selected"
                    @update:selected="emitSelect(picker, $event)"
                  />
                </div>
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
        <QBtn
          color="primary"
          unelevated
          no-caps
          :label="props.form.mode === 'edit' ? 'Сохранить' : 'OK'"
          :loading="props.saveLoading"
          @click="emit('save')"
        />
      </QCardActions>
    </QCard>
  </QDialog>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

import { FemsqTable } from 'fequlib';
import { QBanner, QBtn, QCard, QCardActions, QCardSection, QDialog, QInput, QSeparator, QSpace, QSplitter, QTab, QTabPanel, QTabPanels, QTabs } from 'quasar';

import RelationTree from '@/components/relation/RelationTree.vue';
import type { RelationFetchExpand, RelationFetchNode } from '@/trees/relation-tree';
import type { RelationFormFieldState, RelationFormState, RelationPickerState } from '@/trees/relation-forms';

const props = defineProps<{
  modelValue: boolean;
  form: RelationFormState;
  fetchNode: RelationFetchNode;
  fetchExpand: RelationFetchExpand;
  saveError?: string | null;
  saveLoading?: boolean;
}>();

const emit = defineEmits<{
  'update:modelValue': [value: boolean];
  'picker-select': [pickerId: string, rowKey: string | null];
  'picker-search': [pickerId: string, value: string];
  save: [];
}>();

const pickerSplit = ref(38);
const activePickerId = ref('');
const pickerSearch = ref<Record<string, string>>({});
const searchTimers = new Map<string, ReturnType<typeof setTimeout>>();

watch(
  () => props.form.id,
  () => {
    activePickerId.value = props.form.pickers[0]?.id ?? '';
    for (const timer of searchTimers.values()) {
      clearTimeout(timer);
    }
    searchTimers.clear();
    pickerSearch.value = Object.fromEntries(
      props.form.pickers.map((picker) => [picker.id, picker.searchValue ?? ''])
    );
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

function setPickerSearch(picker: RelationPickerState, value: string | number | null): void {
  const pickerId = picker.id;
  pickerSearch.value = {
    ...pickerSearch.value,
    [pickerId]: value == null ? '' : String(value)
  };
  if (!picker.searchDebounceMs || picker.searchDebounceMs <= 0) {
    return;
  }
  const prev = searchTimers.get(pickerId);
  if (prev) {
    clearTimeout(prev);
  }
  const timer = setTimeout(() => {
    emit('picker-search', pickerId, pickerSearch.value[pickerId] ?? '');
    searchTimers.delete(pickerId);
  }, picker.searchDebounceMs);
  searchTimers.set(pickerId, timer);
}

function emitSearch(picker: RelationPickerState): void {
  emit('picker-search', picker.id, pickerSearch.value[picker.id] ?? '');
}

function clearSearch(picker: RelationPickerState): void {
  const prev = searchTimers.get(picker.id);
  if (prev) {
    clearTimeout(prev);
    searchTimers.delete(picker.id);
  }
  pickerSearch.value = {
    ...pickerSearch.value,
    [picker.id]: ''
  };
  emit('picker-search', picker.id, '');
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
