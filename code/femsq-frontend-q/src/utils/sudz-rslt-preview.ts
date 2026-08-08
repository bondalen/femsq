/**
 * Предпросмотр Rslt в колонках, совпадающих с Excel-выгрузкой ({@link SudzRsltExcelExporter}).
 */

import type { FemsqTableColumn } from 'fequlib';

import type { SudzRsltDebt, SudzRsltPeriod } from '@/types/sudz';

/** Плоская строка предпросмотра (имена полей = техн. имена Excel row3). */
export type SudzRsltPreviewRow = Record<string, string | number | null> & {
  dbtKey: number;
};

export interface SudzRsltPreview {
  columns: FemsqTableColumn<SudzRsltPreviewRow>[];
  rows: SudzRsltPreviewRow[];
  sliceDates: string[];
}

interface SliceMeta {
  uplDate: string;
  labelDate: string;
}

const ROMAN = ['I', 'II', 'III', 'IV'] as const;
const MONTH_RU = [
  'январь',
  'февраль',
  'март',
  'апрель',
  'май',
  'июнь',
  'июль',
  'август',
  'сентябрь',
  'октябрь',
  'ноябрь',
  'декабрь'
] as const;

/**
 * Собирает предпросмотр Excel Rslt (сбор или повтор).
 *
 * @param debts долги из {@code sudzYrDbtChanges}
 * @param fillNew заполнять {@code *_new} (повтор) или оставлять пустыми (сбор)
 */
export function buildSudzRsltPreview(
  debts: SudzRsltDebt[],
  fillNew: boolean
): SudzRsltPreview {
  const slices = collectSlices(debts);
  const newAsOf = slices.length ? slices[slices.length - 1].labelDate : isoToday();
  const newSuffix = `новый, по состоянию на ${monthYearRu(newAsOf)}`;
  const columnDefs = buildColumnDefs(slices, newSuffix);
  const columns = columnDefs.map((def) => toFemsqColumn(def));
  const rows = debts.map((debt) => flattenDebt(debt, slices, fillNew));
  return {
    columns,
    rows,
    sliceDates: slices.map((s) => s.uplDate)
  };
}

function collectSlices(debts: SudzRsltDebt[]): SliceMeta[] {
  const asOfByUpl = new Map<string, string>();
  for (const debt of debts) {
    for (const period of debt.periods ?? []) {
      if (!period.uplDate) {
        continue;
      }
      const asOf = period.asOf ?? period.uplDate;
      const prev = asOfByUpl.get(period.uplDate);
      if (!prev || asOf > prev) {
        asOfByUpl.set(period.uplDate, asOf);
      }
    }
  }
  return [...asOfByUpl.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([uplDate, labelDate]) => ({ uplDate, labelDate }));
}

interface ColumnDef {
  name: string;
  label: string;
  band: 'key' | 'base' | 'inv' | 'quarter' | 'overd' | 'curator' | 'new';
  money?: boolean;
}

function buildColumnDefs(slices: SliceMeta[], newSuffix: string): ColumnDef[] {
  const cols: ColumnDef[] = [
    { name: 'dbtKey', label: 'dbtKey', band: 'key' },
    { name: 'account_num', label: 'Счет Главной книги', band: 'base' }
  ];

  slices.forEach((slice, index) => {
    const q = quarterLabel(slice.labelDate);
    const p = slice.uplDate;
    const first = index === 0;
    cols.push(
      {
        name: `${p}_invNumEnum`,
        label: 'Реквизиты документа основания…',
        band: 'inv'
      },
      { name: `${p}_idNum`, label: `${q}. № задолженности в СФ`, band: 'quarter' },
      { name: `${p}_cnNumEnum`, label: `${q}. Договор`, band: 'quarter' },
      { name: `${p}_csoCnDate`, label: `${q}. Дата договора`, band: 'quarter' },
      { name: `${p}_org_id_value_l`, label: `${q}. № контрагента`, band: 'quarter' },
      { name: `${p}_ITN`, label: `${q}. ИНН контрагента`, band: 'quarter' },
      { name: `${p}_CtptOrg`, label: `${q}. Контрагент`, band: 'quarter' },
      { name: `${p}_Maturity`, label: `${q}. Дата погашения`, band: 'quarter' },
      { name: `${p}_Ttl`, label: `${q}. Общая задолженность`, band: 'quarter', money: true },
      {
        name: `${p}_Overd`,
        label: `${q}. Просроченная задолженность`,
        band: 'overd',
        money: true
      },
      { name: `${p}_CstAgPnKey`, label: '', band: 'key' },
      { name: `${p}_CstAgPnCode`, label: `${q}. Код стройки`, band: 'quarter' },
      { name: `${p}_CstAgPnName`, label: `${q}. Наименование стройки`, band: 'quarter' },
      { name: `${p}_AgOrg`, label: `${q}. Агент`, band: 'quarter' }
    );
    if (!first) {
      cols.push({
        name: `${p}_погашено`,
        label: `${q}. Погашенная задолженность`,
        band: 'quarter',
        money: true
      });
    }
  });

  cols.push(
    { name: 'Куратор от Управления', label: 'Куратор от Управления', band: 'curator' },
    {
      name: 'Мероприятия по погашению дебиторской задолженности',
      label: 'Мероприятия по погашению…',
      band: 'curator'
    },
    { name: 'Код стройки', label: 'Код стройки', band: 'curator' },
    { name: 'Код стройкиN', label: 'Наименование стройки', band: 'curator' },
    { name: 'cur_new', label: `Куратор…, ${newSuffix}`, band: 'new' },
    { name: 'mery_new', label: `Мероприятия…, ${newSuffix}`, band: 'new' },
    { name: 'cstAgPn_new', label: `Код стройки, кратко, ${newSuffix}`, band: 'new' }
  );
  return cols;
}

function toFemsqColumn(def: ColumnDef): FemsqTableColumn<SudzRsltPreviewRow> {
  const headerClass =
    def.band === 'overd'
      ? 'proto-h--overd'
      : def.band === 'new'
        ? 'proto-h--new'
        : def.band === 'curator'
          ? 'proto-h--curator'
          : def.band === 'inv'
            ? 'proto-h--inv'
            : def.band === 'key'
              ? 'proto-h--key'
              : def.band === 'base'
                ? 'proto-h--base'
                : 'proto-h--quarter';

  return {
    name: def.name,
    label: def.label || def.name,
    field: def.name,
    align: def.money || def.name === 'dbtKey' ? 'right' : 'left',
    sortable: true,
    headerClasses: headerClass,
    classes: def.band === 'overd' ? 'proto-c--overd' : undefined,
    format: def.money
      ? (val) => formatMoney(typeof val === 'number' ? val : null)
      : (val) => (val == null || val === '' ? '' : String(val)),
    filterValue: (row) => {
      const raw = row[def.name];
      if (raw == null) return '';
      if (def.money && typeof raw === 'number') return formatMoney(raw);
      return String(raw);
    },
    style:
      'min-width: 96px; max-width: 220px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;'
  };
}

function flattenDebt(
  debt: SudzRsltDebt,
  slices: SliceMeta[],
  fillNew: boolean
): SudzRsltPreviewRow {
  const row: SudzRsltPreviewRow = {
    dbtKey: debt.dbtKey,
    account_num: debt.accountNum
  };

  slices.forEach((slice, index) => {
    const period = findPeriod(debt, slice.uplDate);
    const p = slice.uplDate;
    const first = index === 0;
    row[`${p}_invNumEnum`] = period?.invNumEnum ?? null;
    row[`${p}_idNum`] = period?.idNum ?? null;
    row[`${p}_cnNumEnum`] = period?.cnNumEnum ?? null;
    row[`${p}_csoCnDate`] = period?.csoCnDate ?? null;
    row[`${p}_org_id_value_l`] = period?.orgIdValueL ?? null;
    row[`${p}_ITN`] = period?.itn ?? null;
    row[`${p}_CtptOrg`] = period?.ctptOrg ?? null;
    row[`${p}_Maturity`] = period?.maturity ?? null;
    row[`${p}_Ttl`] = period?.ttl ?? null;
    row[`${p}_Overd`] = period?.overd ?? null;
    row[`${p}_CstAgPnKey`] = null;
    row[`${p}_CstAgPnCode`] = period?.cstAgPnCode ?? null;
    row[`${p}_CstAgPnName`] = period?.cstAgPnName ?? null;
    row[`${p}_AgOrg`] = period?.agOrg ?? null;
    if (!first) {
      row[`${p}_погашено`] = period?.pogasheno ?? null;
    }
  });

  row['Куратор от Управления'] = debt.curator;
  row['Мероприятия по погашению дебиторской задолженности'] = debt.mery;
  row['Код стройки'] = debt.cstCode;
  row['Код стройкиN'] = debt.cstName;
  row.cur_new = fillNew ? (debt.curatorNew ?? null) : null;
  row.mery_new = fillNew ? (debt.meryNew ?? null) : null;
  row.cstAgPn_new = fillNew ? (debt.cstCodeNew ?? null) : null;
  return row;
}

function findPeriod(debt: SudzRsltDebt, uplDate: string): SudzRsltPeriod | undefined {
  return (debt.periods ?? []).find((p) => p.uplDate === uplDate);
}

function quarterLabel(isoDate: string): string {
  const d = parseIso(isoDate);
  if (!d) return '';
  const q = Math.floor((d.getUTCMonth()) / 3);
  return `${d.getUTCFullYear()}. ${ROMAN[q]}-й квартал`;
}

function monthYearRu(isoDate: string): string {
  const d = parseIso(isoDate);
  if (!d) return '';
  return `${MONTH_RU[d.getUTCMonth()]} ${d.getUTCFullYear()}`;
}

function parseIso(isoDate: string): Date | null {
  if (!/^\d{4}-\d{2}-\d{2}/.test(isoDate)) {
    return null;
  }
  const d = new Date(`${isoDate.slice(0, 10)}T00:00:00Z`);
  return Number.isNaN(d.getTime()) ? null : d;
}

function isoToday(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

/**
 * Формат суммы близко к Excel (₽).
 */
export function formatMoney(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) {
    return '';
  }
  return (
    new Intl.NumberFormat('ru-RU', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(value) + ' ₽'
  );
}
