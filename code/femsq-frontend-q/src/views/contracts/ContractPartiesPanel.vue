<template>
  <div class="parties-panel column no-wrap" data-test="cn-parties">
    <div class="row items-center q-mb-xs">
      <div class="femsq-section-title col">Стороны · smpl · org</div>
      <QBtn
        flat
        dense
        no-caps
        color="primary"
        icon="add"
        label="Сторона"
        :disable="!store.selectedCn"
        @click="openSideDialog()"
      />
    </div>

    <div class="parties-tree col" data-test="cn-parties-tree">
      <QInnerLoading :showing="store.loadingSides">
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
          <template v-for="side in store.displaySides" :key="'s-' + side.cnSType">
            <tr
              class="tree-row tree-row--l1"
              :class="{
                'tree-row--expanded': side.cnSKey != null && store.isSideExpanded(side.cnSKey),
                'tree-row--virtual': side.virtual
              }"
            >
              <td class="col-expand">
                <QBtn
                  v-if="side.cnSKey != null"
                  flat
                  dense
                  size="sm"
                  :icon="store.isSideExpanded(side.cnSKey) ? 'expand_more' : 'chevron_right'"
                  aria-label="Раскрыть сторону"
                  @click="store.toggleSide(side.cnSKey)"
                />
              </td>
              <td class="col-label">
                <span class="level-tag">сторона</span>
                {{ side.cnSTypeName || side.cnSType }}
                <span v-if="side.virtual" class="text-grey-6"> · нет записи</span>
              </td>
              <td class="col-meta">{{ side.cnSKey ?? '—' }}</td>
              <td class="col-meta">type={{ side.cnSType }}</td>
              <td class="col-actions">
                <QBtn
                  flat
                  dense
                  icon="add"
                  size="sm"
                  aria-label="Добавить smpl"
                  @click="openSmplDialog(undefined, side.cnSType, side.cnSKey)"
                />
                <QBtn
                  v-if="!side.virtual && side.cnSKey != null"
                  flat
                  dense
                  icon="edit"
                  size="sm"
                  aria-label="Изменить сторону"
                  @click="openSideDialog(side)"
                />
                <QBtn
                  v-if="!side.virtual && side.cnSKey != null"
                  flat
                  dense
                  icon="delete"
                  size="sm"
                  color="negative"
                  aria-label="Удалить сторону"
                  @click="confirmDeleteSide(side.cnSKey, side.cnSTypeName)"
                />
              </td>
            </tr>

            <template v-if="side.cnSKey != null && store.isSideExpanded(side.cnSKey)">
              <template v-if="side.smpls.length === 0">
                <tr class="tree-row tree-row--l2 tree-row--empty">
                  <td />
                  <td colspan="4" class="empty-cell">Нет организаций (smpl)</td>
                </tr>
              </template>
              <template v-for="smpl in side.smpls" :key="'m-' + smpl.csosKey">
                <tr
                  class="tree-row tree-row--l2"
                  :class="{ 'tree-row--expanded': store.isSmplExpanded(smpl.csosKey) }"
                >
                  <td class="col-expand">
                    <QBtn
                      flat
                      dense
                      size="sm"
                      :icon="store.isSmplExpanded(smpl.csosKey) ? 'expand_more' : 'chevron_right'"
                      aria-label="Раскрыть smpl"
                      @click="store.toggleSmpl(smpl.csosKey)"
                    />
                  </td>
                  <td class="col-label">
                    <span class="level-tag">smpl</span>
                    {{ smpl.orgLabel || smpl.csosOrgId }}
                  </td>
                  <td class="col-meta">{{ smpl.csosKey }}</td>
                  <td class="col-meta">org_id={{ smpl.csosOrgId }}</td>
                  <td class="col-actions">
                    <QBtn
                      flat
                      dense
                      icon="add"
                      size="sm"
                      aria-label="Добавить org"
                      @click="openOrgDialog(undefined, smpl.csosKey)"
                    />
                    <QBtn
                      flat
                      dense
                      icon="edit"
                      size="sm"
                      aria-label="Изменить smpl"
                      @click="openSmplDialog(smpl, side.cnSType, side.cnSKey)"
                    />
                    <QBtn
                      flat
                      dense
                      icon="delete"
                      size="sm"
                      color="negative"
                      aria-label="Удалить smpl"
                      @click="confirmDeleteSmpl(smpl.csosKey)"
                    />
                  </td>
                </tr>

                <template v-if="store.isSmplExpanded(smpl.csosKey)">
                  <template v-if="smpl.orgs.length === 0">
                    <tr class="tree-row tree-row--l3 tree-row--empty">
                      <td />
                      <td colspan="4" class="empty-cell">Нет записей org с датами</td>
                    </tr>
                  </template>
                  <tr
                    v-for="org in smpl.orgs"
                    :key="'o-' + org.cnSOrgKey"
                    class="tree-row tree-row--l3"
                  >
                    <td class="col-expand" />
                    <td class="col-label">
                      <span class="level-tag">org</span>
                      csoCnDate={{ org.csoCnDate || '—' }}
                    </td>
                    <td class="col-meta">{{ org.cnSOrgKey }}</td>
                    <td class="col-meta">{{ formatPeriod(org.dateBeg, org.dateEnd) }}</td>
                    <td class="col-actions">
                      <QBtn
                        flat
                        dense
                        icon="edit"
                        size="sm"
                        aria-label="Изменить org"
                        @click="openOrgDialog(org, smpl.csosKey)"
                      />
                      <QBtn
                        flat
                        dense
                        icon="delete"
                        size="sm"
                        color="negative"
                        aria-label="Удалить org"
                        @click="confirmDeleteOrg(org.cnSOrgKey)"
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

    <QDialog v-model="sideDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">
          {{ sideDialog.id == null ? 'Новая сторона' : 'Сторона' }}
        </QCardSection>
        <QCardSection>
          <QSelect
            v-model="sideDialog.cnSType"
            :options="sideTypeOptions"
            emit-value
            map-options
            label="Роль *"
            dense
            options-dense
            :disable="sideDialog.id != null"
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
            @click="saveSide"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="smplDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">
          {{ smplDialog.id == null ? 'Новая организация (smpl)' : 'Организация (smpl)' }}
        </QCardSection>
        <QCardSection>
          <QSelect
            v-model="smplDialog.csosOrgId"
            :options="orgIdOptions"
            emit-value
            map-options
            use-input
            input-debounce="200"
            @filter="filterOrgIds"
            label="org_id (БУиРГ) *"
            dense
            options-dense
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
            @click="saveSmpl"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="orgDialog.open">
      <QCard class="dialog-card">
        <QCardSection class="dialog-title">
          {{ orgDialog.id == null ? 'Новая запись org' : 'Запись org' }}
        </QCardSection>
        <QCardSection class="q-gutter-sm">
          <QInput
            v-model="orgDialog.csoCnDate"
            label="csoCnDate"
            hint="ДД.ММ.ГГГГ или ГГГГ-ММ-ДД; пусто = дата отсутствует"
            dense
          />
          <QInput v-model="orgDialog.dateBeg" label="date_beg" hint="ДД.ММ.ГГГГ или ГГГГ-ММ-ДД" dense />
          <QInput v-model="orgDialog.dateEnd" label="date_end" hint="ДД.ММ.ГГГГ или ГГГГ-ММ-ДД" dense />
          <QInput v-model="orgDialog.csoAsbuId" label="ID в АСБУ" dense />
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
            @click="saveOrg"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import {
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInnerLoading,
  QInput,
  QSelect,
  QSpinner,
  useQuasar
} from 'quasar';

import { createCnSide } from '@/api/contracts-api';
import { useContractsStore } from '@/stores/contracts';
import type { CnSideDto, CnSOrgDto, CnSOrgSmplDto } from '@/types/contracts';
import { parseFlexibleDate } from '@/utils/flexible-date';

const store = useContractsStore();
const $q = useQuasar();

const sideTypeOptions = [
  { label: 'заказчик', value: 1 },
  { label: 'исполнитель', value: 2 }
];

const sideDialog = reactive({
  open: false,
  id: null as number | null,
  cnSType: 2
});

const smplDialog = reactive({
  open: false,
  id: null as number | null,
  cnSType: 2,
  cnSKey: null as number | null,
  csosOrgId: null as number | null
});

const orgDialog = reactive({
  open: false,
  id: null as number | null,
  csosKey: 0,
  csoCnDate: '' as string,
  dateBeg: '' as string,
  dateEnd: '' as string,
  csoAsbuId: '' as string
});

const orgIdFilter = ref('');

const orgIdOptions = computed(() => {
  const q = orgIdFilter.value.trim().toLowerCase();
  return store.orgIdLookups
    .filter((row) => !q || row.label.toLowerCase().includes(q) || String(row.orgIdKey).includes(q))
    .map((row) => ({ label: row.label, value: row.orgIdKey }));
});

/**
 * Форматирует период дат.
 */
function formatPeriod(beg: string | null, end: string | null): string {
  if (!beg && !end) {
    return '—';
  }
  return `${beg || '…'} — ${end || '…'}`;
}

/**
 * Открывает диалог стороны.
 */
function openSideDialog(side?: Pick<CnSideDto, 'cnSKey' | 'cnSType'> & { virtual?: boolean }): void {
  if (!store.selectedCn) {
    return;
  }
  sideDialog.id = side?.cnSKey ?? null;
  sideDialog.cnSType = side?.cnSType ?? 2;
  sideDialog.open = true;
}

/**
 * Сохраняет сторону.
 */
async function saveSide(): Promise<void> {
  const cnKey = store.selectedCn?.cnKey;
  if (cnKey == null) {
    return;
  }
  try {
    await store.saveSide({ cnKey, cnSType: sideDialog.cnSType }, sideDialog.id ?? undefined);
    sideDialog.open = false;
  } catch {
    /* error в store */
  }
}

/**
 * Открывает диалог smpl; при виртуальной роли сначала создаст cn_s.
 */
async function openSmplDialog(
  smpl: CnSOrgSmplDto | undefined,
  cnSType: number,
  cnSKey: number | null | undefined
): Promise<void> {
  await store.ensureOrgIdLookups();
  smplDialog.id = smpl?.csosKey ?? null;
  smplDialog.cnSType = cnSType;
  smplDialog.cnSKey = cnSKey ?? null;
  smplDialog.csosOrgId = smpl?.csosOrgId ?? null;
  smplDialog.open = true;
}

/**
 * Сохраняет smpl (при необходимости создаёт сторону).
 */
async function saveSmpl(): Promise<void> {
  const cnKey = store.selectedCn?.cnKey;
  if (cnKey == null || smplDialog.csosOrgId == null) {
    $q.notify({ type: 'warning', message: 'Выберите организацию (org_id)' });
    return;
  }
  try {
    let cnSKey = smplDialog.cnSKey;
    if (cnSKey == null) {
      const created = await createCnSide({ cnKey, cnSType: smplDialog.cnSType });
      cnSKey = created.cnSKey;
    }
    await store.saveSmpl(
      { csosCnS: cnSKey, csosOrgId: smplDialog.csosOrgId },
      smplDialog.id ?? undefined
    );
    smplDialog.open = false;
  } catch {
    /* error в store */
  }
}

/**
 * Открывает диалог org; csoCnDate только из строки org (не из cn_date карточки).
 */
function openOrgDialog(org: CnSOrgDto | undefined, csosKey: number): void {
  orgDialog.id = org?.cnSOrgKey ?? null;
  orgDialog.csosKey = csosKey;
  orgDialog.csoCnDate = org?.csoCnDate ?? '';
  orgDialog.dateBeg = org?.dateBeg ?? '';
  orgDialog.dateEnd = org?.dateEnd ?? '';
  orgDialog.csoAsbuId = org?.csoAsbuId ?? '';
  orgDialog.open = true;
}

/**
 * Сохраняет org.
 */
async function saveOrg(): Promise<void> {
  let csoCnDate: string | null;
  let dateBeg: string | null;
  let dateEnd: string | null;
  try {
    csoCnDate = parseFlexibleDate(orgDialog.csoCnDate);
    dateBeg = parseFlexibleDate(orgDialog.dateBeg);
    dateEnd = parseFlexibleDate(orgDialog.dateEnd);
  } catch (err) {
    $q.notify({
      type: 'warning',
      message: err instanceof Error ? err.message : 'Некорректная дата'
    });
    return;
  }
  try {
    await store.saveOrg(
      {
        csoCnSOrgSmpl: orgDialog.csosKey,
        csoCnDate,
        dateBeg,
        dateEnd,
        csoAsbuId: emptyToNull(orgDialog.csoAsbuId)
      },
      orgDialog.id ?? undefined
    );
    orgDialog.open = false;
  } catch {
    /* error в store */
  }
}

function emptyToNull(value: string): string | null {
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed;
}

function filterOrgIds(val: string, update: (fn: () => void) => void): void {
  update(() => {
    orgIdFilter.value = val;
  });
}

function confirmDeleteSide(id: number, name: string | null): void {
  $q.dialog({
    title: 'Удалить сторону?',
    message: `Будут удалены все smpl/org роли «${name || id}».`,
    cancel: { flat: true, label: 'Отмена' },
    ok: { flat: true, color: 'negative', label: 'Удалить' }
  }).onOk(() => {
    void store.removeSide(id);
  });
}

function confirmDeleteSmpl(id: number): void {
  $q.dialog({
    title: 'Удалить smpl?',
    message: 'Будут удалены вложенные записи org.',
    cancel: { flat: true, label: 'Отмена' },
    ok: { flat: true, color: 'negative', label: 'Удалить' }
  }).onOk(() => {
    void store.removeSmpl(id);
  });
}

function confirmDeleteOrg(id: number): void {
  $q.dialog({
    title: 'Удалить org?',
    message: `Удалить запись cn_s_org_key=${id}?`,
    cancel: { flat: true, label: 'Отмена' },
    ok: { flat: true, color: 'negative', label: 'Удалить' }
  }).onOk(() => {
    void store.removeOrg(id);
  });
}
</script>

<style scoped>
.parties-panel {
  min-height: 0;
  height: 100%;
}

.parties-tree {
  position: relative;
  min-height: 0;
  flex: 1 1 auto;
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
  margin-right: 6px;
  font-size: 0.75em;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: color-mix(in srgb, var(--q-primary) 75%, white);
}

.tree-row--l2 .level-tag {
  color: color-mix(in srgb, var(--q-primary) 55%, #7ec8e3);
}

.tree-row--l3 .level-tag {
  color: color-mix(in srgb, var(--q-primary) 40%, #a8d5e5);
}

.empty-cell {
  color: var(--femsq-text-muted, #888);
  font-style: italic;
}

.dialog-card {
  min-width: 360px;
}

.dialog-title {
  font-weight: 600;
}
</style>
