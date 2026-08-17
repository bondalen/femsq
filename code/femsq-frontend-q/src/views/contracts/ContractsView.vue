<template>
  <QPage class="contracts-view q-pa-md column no-wrap" data-test="contracts-view">
    <div class="row items-center q-mb-sm q-gutter-sm">
      <div class="col">
        <div class="femsq-page-title">Договоры</div>
        <div class="femsq-page-subtitle">
          Access <code>cnNum</code> → <code>cn</code> → стороны
        </div>
      </div>
      <QBtn
        flat
        dense
        no-caps
        color="primary"
        icon="add"
        label="Договор"
        data-test="cn-create-btn"
        @click="openCreateDialog"
      />
      <QBtn
        flat
        dense
        icon="refresh"
        :loading="store.loadingList"
        aria-label="Обновить"
        @click="store.loadCnNums()"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-sm" rounded>
      {{ store.error }}
    </QBanner>

    <QSplitter
      v-model="masterSplit"
      :limits="[22, 55]"
      separator-class="cn-split-sep"
      class="cn-main-splitter"
      data-test="cn-main-splitter"
    >
      <template #before>
        <section class="master-block fill-pane" data-test="cn-master">
          <FemsqTable
            class="master-table"
            root-class="master-table"
            row-key="cnnKey"
            :rows="store.cnNums"
            :columns="masterColumns"
            :loading="store.loadingList"
            :show-filter="true"
            v-model:pagination="cnNumPagination"
            selection="single"
            v-model:selected="selectedRows"
            @row-click="onCnNumRowClick"
          />
        </section>
      </template>

      <template #after>
        <section class="detail-block fill-pane column no-wrap" data-test="cn-detail">
          <div v-if="store.loadingDetail" class="text-caption text-grey-7 q-pa-sm">Загрузка…</div>
          <template v-else-if="store.selectedCn">
            <div class="cn-card-bar row items-center q-gutter-sm q-mb-xs q-px-xs">
              <span class="text-caption text-grey-8">
                cn_key={{ store.selectedCn.cnKey }}
                · {{ store.selectedCn.cnNumber || '—' }}
                · cn_date={{ store.selectedCn.cnDate || '—' }}
              </span>
              <QBtn
                flat
                dense
                no-caps
                size="sm"
                color="primary"
                icon="edit"
                label="cn_date"
                data-test="cn-edit-btn"
                @click="openEditCnDialog"
              />
            </div>
            <QSplitter
              v-model="detailSplit"
              horizontal
              :limits="[20, 70]"
              separator-class="cn-split-sep"
              class="cn-detail-splitter col"
            >
              <template #before>
                <FemsqTable
                  class="nested-table"
                  root-class="nested-table"
                  row-key="cnnKey"
                  :rows="store.cnNumsForCn"
                  :columns="detailColumns"
                  :loading="store.loadingDetail"
                  :show-filter="false"
                  v-model:pagination="nestedPagination"
                  selection="single"
                  v-model:selected="nestedSelectedRows"
                  @row-click="onNestedCnNumClick"
                />
              </template>
              <template #after>
                <ContractPartiesPanel />
              </template>
            </QSplitter>
          </template>
          <div v-else class="text-grey-7 q-pa-sm">Выберите номер договора слева</div>
        </section>
      </template>
    </QSplitter>

    <QDialog v-model="createDialog.open" persistent>
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">Новый договор</QCardSection>
        <QCardSection class="text-caption text-grey-7">
          Создаёт <code>cn</code> + номер. Обязателен только тип номера (<code>cnnType</code> NOT NULL в БД).
          Дата из свода пишется в <code>csoCnDate</code> исполнителя; <code>cn_date</code> при создании
          остаётся пустым (правка отдельно на карточке). Без исполнителя дату стороны добавить позже.
          Коллизию номера система не разрешает автоматически.
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput v-model="createDialog.cnnNum" label="Номер" hint="Можно пусто (NULL в БД)" dense autofocus />
          <QInput
            v-model="createDialog.csoCnDate"
            label="Дата для стороны (csoCnDate)"
            hint="Из Excel/свода → cn_s_org; пусто = дата отсутствует. Только при выборе исполнителя."
            dense
          />
          <QSelect
            v-model="createDialog.cnnType"
            :options="numTypeOptions"
            emit-value
            map-options
            label="Тип номера *"
            dense
            options-dense
          />
          <QSelect
            v-model="createDialog.csosOrgId"
            :options="orgIdOptions"
            emit-value
            map-options
            use-input
            clearable
            input-debounce="200"
            @filter="filterOrgIds"
            label="Исполнитель (org_id / БУиРГ)"
            hint="Необязательно; можно добавить smpl позже"
            dense
            options-dense
          />
          <QBanner v-if="createDialog.duplicateHint" class="bg-warning text-dark" rounded dense>
            {{ createDialog.duplicateHint }}
          </QBanner>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn
            flat
            dense
            no-caps
            color="primary"
            label="Создать"
            :loading="store.saving"
            @click="saveCreate"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="editCnDialog.open" persistent>
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">Карточка договора (cn)</QCardSection>
        <QCardSection class="text-caption text-grey-7">
          Справочная дата <code>cn_date</code> — не путать с <code>csoCnDate</code> в сторонах.
          Пустое значение допустимо (как у большинства договоров в БД).
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput
            v-model="editCnDialog.cnDate"
            label="cn_date"
            hint="ДД.ММ.ГГГГ или ГГГГ-ММ-ДД; пусто = NULL"
            dense
            autofocus
          />
          <QInput
            v-model="editCnDialog.cnNote"
            label="cn_note"
            type="textarea"
            autogrow
            dense
          />
          <QInput
            v-model.number="editCnDialog.cnMark"
            label="cnMark"
            type="number"
            clearable
            dense
          />
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat dense no-caps label="Отмена" v-close-popup />
          <QBtn
            flat
            dense
            no-caps
            color="primary"
            label="Сохранить"
            :loading="store.saving"
            @click="saveEditCn"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QPage,
  QSelect,
  QSplitter,
  useQuasar
} from 'quasar';
import { FemsqTable, type FemsqTableColumn } from 'fequlib';

import ContractPartiesPanel from '@/views/contracts/ContractPartiesPanel.vue';
import { useContractsStore } from '@/stores/contracts';
import type { CnNumDto } from '@/types/contracts';
import { parseFlexibleDate } from '@/utils/flexible-date';

const store = useContractsStore();
const $q = useQuasar();
/** Доля ширины левой панели (список cnNum), как Access. */
const masterSplit = ref(36);
/** Доля высоты блока номеров над сторонами. */
const detailSplit = ref(32);
const cnNumPagination = ref({ page: 1, rowsPerPage: 25 });
const nestedPagination = ref({ page: 1, rowsPerPage: 10 });
const orgIdFilter = ref('');

const createDialog = reactive({
  open: false,
  cnnNum: '',
  csoCnDate: '',
  cnnType: 1,
  csosOrgId: null as number | null,
  duplicateHint: '' as string
});

const editCnDialog = reactive({
  open: false,
  cnDate: '',
  cnNote: '',
  cnMark: null as number | null
});

const masterColumns: FemsqTableColumn<CnNumDto>[] = [
  {
    name: 'cnnNum',
    label: 'Номер',
    field: 'cnnNum',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.cnnNum ?? ''
  },
  {
    name: 'cnnTypeName',
    label: 'Тип',
    field: 'cnnTypeName',
    sortable: true,
    align: 'left',
    filterValue: (row) => row.cnnTypeName ?? ''
  }
];

const detailColumns: FemsqTableColumn<CnNumDto>[] = [
  ...masterColumns,
  {
    name: 'cnnKey',
    label: 'cnnKey',
    field: 'cnnKey',
    sortable: true,
    align: 'right'
  },
  {
    name: 'cnnCn',
    label: 'cn_key',
    field: 'cnnCn',
    sortable: true,
    align: 'right'
  }
];

const numTypeOptions = computed(() =>
  store.numTypes.map((row) => ({
    label: row.cnntName || String(row.cnntKey),
    value: row.cnntKey
  }))
);

const orgIdOptions = computed(() => {
  const q = orgIdFilter.value.trim().toLowerCase();
  return store.orgIdLookups
    .filter((row) => !q || row.label.toLowerCase().includes(q) || String(row.orgIdKey).includes(q))
    .map((row) => ({ label: row.label, value: row.orgIdKey }));
});

const selectedRows = computed({
  get: () => {
    const row = store.selectedCnNum;
    return row ? [row] : [];
  },
  set: (rows: CnNumDto[]) => {
    const first = rows[0];
    if (first) {
      void store.selectCnNum(first.cnnKey);
    }
  }
});

const nestedSelectedRows = computed({
  get: () => {
    const key = store.selectedCnnKey;
    const row = store.cnNumsForCn.find((item) => item.cnnKey === key);
    return row ? [row] : [];
  },
  set: (rows: CnNumDto[]) => {
    const first = rows[0];
    if (first) {
      void store.selectCnNum(first.cnnKey);
    }
  }
});

function onCnNumRowClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

function onNestedCnNumClick(_evt: Event, row: CnNumDto): void {
  void store.selectCnNum(row.cnnKey);
}

function filterOrgIds(val: string, update: (fn: () => void) => void): void {
  update(() => {
    orgIdFilter.value = val;
  });
}

/**
 * Открывает диалог нового договора.
 */
async function openCreateDialog(): Promise<void> {
  await Promise.all([store.ensureNumTypes(), store.ensureOrgIdLookups()]);
  createDialog.cnnNum = '';
  createDialog.csoCnDate = '';
  createDialog.cnnType = 1;
  createDialog.csosOrgId = null;
  createDialog.duplicateHint = '';
  createDialog.open = true;
}

/**
 * Открывает правку карточки cn (cn_date и пр.).
 */
function openEditCnDialog(): void {
  const cn = store.selectedCn;
  if (!cn) {
    return;
  }
  editCnDialog.cnDate = cn.cnDate ?? '';
  editCnDialog.cnNote = cn.cnNote ?? '';
  editCnDialog.cnMark = cn.cnMark;
  editCnDialog.open = true;
}

/**
 * Сохраняет cn_date / note / mark.
 */
async function saveEditCn(): Promise<void> {
  let cnDate: string | null;
  try {
    cnDate = parseFlexibleDate(editCnDialog.cnDate);
  } catch (err) {
    $q.notify({
      type: 'warning',
      message: err instanceof Error ? err.message : 'Некорректная дата'
    });
    return;
  }
  try {
    await store.saveCn({
      cnDate,
      cnNote: editCnDialog.cnNote.trim() === '' ? null : editCnDialog.cnNote,
      cnMark: editCnDialog.cnMark == null || Number.isNaN(editCnDialog.cnMark) ? null : editCnDialog.cnMark
    });
    editCnDialog.open = false;
    $q.notify({ type: 'positive', message: 'Карточка cn сохранена' });
  } catch {
    /* error в store */
  }
}

/**
 * Создаёт договор; при коллизии номера — предупреждение, решение за оператором.
 */
async function saveCreate(): Promise<void> {
  if (createDialog.cnnType == null || createDialog.cnnType <= 0) {
    $q.notify({ type: 'warning', message: 'Укажите тип номера (обязательное поле БД)' });
    return;
  }
  const cnnNumRaw = createDialog.cnnNum.trim();
  const cnnNum = cnnNumRaw === '' ? null : cnnNumRaw;
  let csoCnDate: string | null;
  try {
    csoCnDate = parseFlexibleDate(createDialog.csoCnDate);
  } catch (err) {
    $q.notify({
      type: 'warning',
      message: err instanceof Error ? err.message : 'Некорректная дата'
    });
    return;
  }
  if (csoCnDate != null && createDialog.csosOrgId == null) {
    $q.notify({
      type: 'warning',
      message: 'Дата csoCnDate сохраняется только вместе с исполнителем — выберите org_id или очистите дату'
    });
    return;
  }

  let duplicates = 0;
  try {
    duplicates = await store.duplicateCount(cnnNum ?? '');
  } catch {
    /* не блокируем создание */
  }

  const doCreate = async (): Promise<void> => {
    try {
      await store.createContract({
        cnnNum,
        csoCnDate,
        cnnType: createDialog.cnnType,
        csosOrgId: createDialog.csosOrgId
      });
      createDialog.open = false;
      $q.notify({ type: 'positive', message: 'Договор создан' });
    } catch {
      /* error в store */
    }
  };

  if (duplicates > 0) {
    const label = cnnNum ?? '(пустой номер)';
    createDialog.duplicateHint =
      `Уже есть ${duplicates} номер(ов) «${label}». Коллизию система не разрешает — ` +
      'если это новый договор, создавайте; если старый — отмените и добавьте smpl к существующему.';
    $q.dialog({
      title: 'Коллизия номера',
      message:
        `В БД уже есть ${duplicates} записей с номером «${label}». ` +
        'Автоматически выбрать «тот самый» договор нельзя. Продолжить создание нового?',
      cancel: { flat: true, label: 'Отмена' },
      ok: { flat: true, color: 'primary', label: 'Создать новый' }
    }).onOk(() => {
      void doCreate();
    });
    return;
  }

  await doCreate();
}

onMounted(() => {
  void store.loadCnNums();
});
</script>

<style scoped>
.contracts-view {
  min-height: 0;
  height: calc(100vh - 100px);
}

.cn-main-splitter,
.cn-detail-splitter {
  flex: 1 1 auto;
  min-height: 0;
}

.fill-pane {
  min-height: 0;
  height: 100%;
  overflow: hidden;
  padding-right: 4px;
}

.detail-block {
  overflow: hidden;
}

.master-table,
.nested-table {
  width: 100%;
}

.cn-split-sep {
  background: var(--femsq-border, #555);
}

.dialog-card {
  min-width: 420px;
  max-width: 520px;
}

.dialog-title {
  font-weight: 600;
}

.cn-card-bar {
  flex: 0 0 auto;
  min-height: 28px;
}
</style>
