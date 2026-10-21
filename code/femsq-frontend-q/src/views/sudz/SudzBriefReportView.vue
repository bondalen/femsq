<template>
  <QPage class="q-pa-none" data-test="sudz-brief-report-view">
    <div class="absolute-full q-pa-md column no-wrap sudz-brief-report-view">
      <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
        <div class="text-h6 col">Краткий отчёт по своду</div>
        <QBtn
          flat
          dense
          no-caps
          icon="clear_all"
          label="Очистить лог"
          :disable="!store.result && !store.error"
          data-test="sudz-brief-clear-log"
          @click="store.clearLog()"
        />
      </div>

      <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm shrink-0" rounded dense>
        {{ store.error }}
      </QBanner>

      <QCard flat bordered class="col column no-wrap min-h-0">
        <QTabs
          v-model="mainTab"
          dense
          class="text-primary shrink-0"
          active-color="primary"
          indicator-color="primary"
          align="left"
          @update:model-value="onMainTab"
        >
          <QTab name="report" label="отчёт" data-test="sudz-brief-tab-report" />
          <QTab name="dict" label="словарь" data-test="sudz-brief-tab-dict" />
        </QTabs>
        <QSeparator />

        <QTabPanels v-model="mainTab" animated class="col min-h-0">
          <QTabPanel name="report" class="q-pa-sm column no-wrap fill-pane">
            <div class="row q-col-gutter-sm items-start q-mb-sm shrink-0">
              <div class="col-12 col-md">
                <QInput
                  :model-value="store.svodPath"
                  dense
                  outlined
                  label="Файл свода"
                  hint="Путь как в Проводнике или POSIX (/mnt/nb-win-share/…)."
                  hint-persistent
                  :disable="store.running"
                  data-test="sudz-brief-svod-path"
                  @update:model-value="(v) => store.onPathChanged(String(v ?? ''))"
                />
              </div>
              <div class="col-auto" style="min-width: 160px">
                <QInput
                  v-model="store.asOf"
                  dense
                  outlined
                  type="date"
                  label="Дата отчёта"
                  hint="L6; для QI 2026_03 — 2026-03-31"
                  hint-persistent
                  :disable="store.running"
                  data-test="sudz-brief-as-of"
                />
              </div>
              <div class="col-auto self-center">
                <QBtn
                  color="primary"
                  unelevated
                  no-caps
                  dense
                  label="Подготовить"
                  :loading="store.running"
                  :disable="!store.canPrepare"
                  data-test="sudz-brief-prepare"
                  @click="onPrepare"
                />
              </div>
            </div>

            <QBanner
              v-if="store.result"
              class="bg-positive text-white q-mb-sm shrink-0"
              rounded
              dense
              data-test="sudz-brief-result-banner"
            >
              Готово:
              {{ store.result.outputPath }}
              · H={{ formatMoney(store.result.totalDebtH) }}
              · FIO={{ store.result.fioTransformed }}
            </QBanner>

            <QCard flat bordered class="col column no-wrap min-h-0">
              <QCardSection class="q-py-xs q-px-sm shrink-0 text-caption text-grey-7">
                Ход подготовки
              </QCardSection>
              <QSeparator />
              <QCardSection class="col q-pa-sm scroll" data-test="sudz-brief-log">
                <pre v-if="store.logText" class="sudz-brief-log-pre">{{ store.logText }}</pre>
                <div v-else class="text-grey-6">Нажмите «Подготовить» — здесь появится лог прогона.</div>
              </QCardSection>
            </QCard>
          </QTabPanel>

          <QTabPanel name="dict" class="q-pa-sm column no-wrap fill-pane">
            <div class="row items-center q-gutter-sm q-mb-sm shrink-0">
              <div class="text-subtitle2 col">Словарь имён и отчеств (ags.fioDict)</div>
              <QBtn
                flat
                dense
                no-caps
                icon="refresh"
                label="Обновить"
                :loading="store.dictLoading"
                data-test="sudz-fio-dict-refresh"
                @click="store.loadDict(true)"
              />
              <QBtn
                color="primary"
                unelevated
                dense
                no-caps
                icon="add"
                label="Добавить"
                :disable="store.dictSaving"
                data-test="sudz-fio-dict-add"
                @click="openCreate"
              />
            </div>

            <QBanner
              v-if="store.dictError"
              class="bg-negative text-white q-mb-sm shrink-0"
              rounded
              dense
              data-test="sudz-fio-dict-error"
            >
              {{ store.dictError }}
            </QBanner>

            <FemsqTable
              class="col min-h-0"
              root-class="sudz-fio-dict-table"
              row-key="fioDictKey"
              :rows="store.dictRows"
              :columns="dictColumns"
              :loading="store.dictLoading"
              v-model:filter="dictFilter"
              v-model:pagination="dictPagination"
              filter-label="Фильтр словаря"
              filter-test-id="sudz-fio-dict-filter"
              data-test="sudz-fio-dict-table"
            >
              <template #body-cell-actions="props">
                <QTd :props="props">
                  <QBtn
                    flat
                    dense
                    round
                    icon="edit"
                    size="sm"
                    data-test="sudz-fio-dict-edit"
                    @click.stop="openEdit(props.row)"
                  />
                  <QBtn
                    flat
                    dense
                    round
                    icon="delete"
                    size="sm"
                    color="negative"
                    data-test="sudz-fio-dict-delete"
                    @click.stop="confirmDelete(props.row)"
                  />
                </QTd>
              </template>
            </FemsqTable>
          </QTabPanel>
        </QTabPanels>
      </QCard>
    </div>

    <QDialog v-model="dlg.open" persistent>
      <QCard style="min-width: 420px; max-width: 560px" data-test="sudz-fio-dict-dialog">
        <QCardSection class="text-subtitle1">
          {{ dlg.mode === 'create' ? 'Новая строка словаря' : `Строка #${dlg.fioDictKey}` }}
        </QCardSection>
        <QSeparator />
        <QCardSection class="q-gutter-sm">
          <QInput v-model="dlg.fdName" dense outlined label="Имя (fdName)" maxlength="50" data-test="sudz-fio-fdName" />
          <QInput v-model="dlg.fdNameF" dense outlined label="Имя жен. (fdNameF)" maxlength="50" data-test="sudz-fio-fdNameF" />
          <QInput v-model="dlg.fdPatrM" dense outlined label="Отчество муж. (fdPatrM)" maxlength="50" data-test="sudz-fio-fdPatrM" />
          <QInput v-model="dlg.fdPatrM2" dense outlined label="Отчество муж. 2 (fdPatrM2)" maxlength="50" data-test="sudz-fio-fdPatrM2" />
          <QInput v-model="dlg.fdPatrF2" dense outlined label="Отчество жен. 2 (fdPatrF2)" maxlength="50" data-test="sudz-fio-fdPatrF2" />
          <QInput v-model="dlg.fdPatrF" dense outlined label="Отчество жен. (fdPatrF)" maxlength="50" data-test="sudz-fio-fdPatrF" />
          <div class="text-caption text-grey-7">Нужно хотя бы одно непустое поле.</div>
        </QCardSection>
        <QSeparator />
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" data-test="sudz-fio-dict-cancel" @click="dlg.open = false" />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Сохранить"
            :loading="store.dictSaving"
            data-test="sudz-fio-dict-save"
            @click="saveDlg"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="deleteDlg.open">
      <QCard style="min-width: 320px" data-test="sudz-fio-dict-delete-dialog">
        <QCardSection>
          Удалить строку #{{ deleteDlg.fioDictKey }}?
          <div class="text-caption text-grey-7 q-mt-xs">{{ deleteDlg.preview }}</div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" @click="deleteDlg.open = false" />
          <QBtn
            color="negative"
            unelevated
            no-caps
            label="Удалить"
            :loading="store.dictSaving"
            data-test="sudz-fio-dict-delete-confirm"
            @click="doDelete"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QPage,
  QSeparator,
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QTd
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import { useSudzBriefReportStore } from '@/stores/sudz-brief-report';
import type { SudzFioDict } from '@/types/sudz';

const store = useSudzBriefReportStore();
const mainTab = ref<'report' | 'dict'>('report');
const dictFilter = ref('');
const dictPagination = ref({
  page: 1,
  rowsPerPage: 50,
  sortBy: 'fioDictKey',
  descending: false
});

const dictColumns: FemsqTableColumn<SudzFioDict>[] = [
  { name: 'fioDictKey', label: '#', field: 'fioDictKey', align: 'right', sortable: true, style: 'width: 64px' },
  { name: 'fdName', label: 'Имя', field: 'fdName', align: 'left', sortable: true },
  { name: 'fdNameF', label: 'Имя ж.', field: 'fdNameF', align: 'left', sortable: true },
  { name: 'fdPatrM', label: 'Отч. м.', field: 'fdPatrM', align: 'left', sortable: true },
  { name: 'fdPatrM2', label: 'Отч. м.2', field: 'fdPatrM2', align: 'left', sortable: true },
  { name: 'fdPatrF2', label: 'Отч. ж.2', field: 'fdPatrF2', align: 'left', sortable: true },
  { name: 'fdPatrF', label: 'Отч. ж.', field: 'fdPatrF', align: 'left', sortable: true },
  { name: 'actions', label: '', field: 'fioDictKey', align: 'center', sortable: false, style: 'width: 88px' }
];

const dlg = reactive({
  open: false,
  mode: 'create' as 'create' | 'edit',
  fioDictKey: 0,
  fdName: '',
  fdNameF: '',
  fdPatrM: '',
  fdPatrM2: '',
  fdPatrF2: '',
  fdPatrF: ''
});

const deleteDlg = reactive({
  open: false,
  fioDictKey: 0,
  preview: ''
});

/**
 * Загрузка словаря при первом открытии вкладки.
 *
 * @param tab имя вкладки
 */
function onMainTab(tab: string | number | null): void {
  if (tab === 'dict') {
    void store.loadDict();
  }
}

/**
 * Запуск подготовки краткого отчёта.
 */
async function onPrepare(): Promise<void> {
  await store.prepare();
}

/**
 * Диалог создания.
 */
function openCreate(): void {
  dlg.mode = 'create';
  dlg.fioDictKey = 0;
  dlg.fdName = '';
  dlg.fdNameF = '';
  dlg.fdPatrM = '';
  dlg.fdPatrM2 = '';
  dlg.fdPatrF2 = '';
  dlg.fdPatrF = '';
  dlg.open = true;
}

/**
 * Диалог правки.
 *
 * @param row строка
 */
function openEdit(row: SudzFioDict): void {
  dlg.mode = 'edit';
  dlg.fioDictKey = row.fioDictKey;
  dlg.fdName = row.fdName ?? '';
  dlg.fdNameF = row.fdNameF ?? '';
  dlg.fdPatrM = row.fdPatrM ?? '';
  dlg.fdPatrM2 = row.fdPatrM2 ?? '';
  dlg.fdPatrF2 = row.fdPatrF2 ?? '';
  dlg.fdPatrF = row.fdPatrF ?? '';
  dlg.open = true;
}

/**
 * Сохранить create/update.
 */
async function saveDlg(): Promise<void> {
  const payload = {
    fdName: emptyToNull(dlg.fdName),
    fdNameF: emptyToNull(dlg.fdNameF),
    fdPatrM: emptyToNull(dlg.fdPatrM),
    fdPatrM2: emptyToNull(dlg.fdPatrM2),
    fdPatrF2: emptyToNull(dlg.fdPatrF2),
    fdPatrF: emptyToNull(dlg.fdPatrF)
  };
  const saved =
    dlg.mode === 'create'
      ? await store.createDictRow(payload)
      : await store.updateDictRow({ fioDictKey: dlg.fioDictKey, ...payload });
  if (saved) {
    dlg.open = false;
  }
}

/**
 * Подтверждение удаления.
 *
 * @param row строка
 */
function confirmDelete(row: SudzFioDict): void {
  deleteDlg.fioDictKey = row.fioDictKey;
  deleteDlg.preview = [row.fdName, row.fdNameF, row.fdPatrM, row.fdPatrM2, row.fdPatrF2, row.fdPatrF]
    .filter((v) => v && String(v).trim())
    .join(' · ');
  deleteDlg.open = true;
}

/**
 * Удалить после подтверждения.
 */
async function doDelete(): Promise<void> {
  const ok = await store.deleteDictRow(deleteDlg.fioDictKey);
  if (ok) {
    deleteDlg.open = false;
  }
}

/**
 * Краткая запись суммы для баннера.
 *
 * @param value сумма
 * @returns строка
 */
function formatMoney(value: number): string {
  return value.toLocaleString('ru-RU', { maximumFractionDigits: 2 });
}

/**
 * Пустая строка → null для GraphQL.
 *
 * @param value ввод
 * @returns null или trim
 */
function emptyToNull(value: string): string | null {
  const t = value.trim();
  return t.length === 0 ? null : t;
}
</script>

<style scoped>
.sudz-brief-report-view {
  min-height: 0;
}

.fill-pane {
  height: 100%;
  min-height: 0;
}

.sudz-brief-log-pre {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  line-height: 1.35;
}
</style>
