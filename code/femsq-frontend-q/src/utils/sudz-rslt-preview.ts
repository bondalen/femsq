/**
 * Предпросмотр Rslt в колонках, совпадающих с Excel-выгрузкой ({@link SudzRsltExcelExporter}).
 */

import type { FemsqTableColumn } from 'fequlib';

import type { SudzRsltDebt, SudzRsltPeriod } from '@/types/sudz';

/** Плоская строка предпросмотра (имена полей = техн. имена Excel row3). */
export type SudzRsltPreviewRow = Record<string, string | number | null> & {
  dbtKey: number;
  /** Уникальный ключ полосы: канон + индекс строки факта (S77.5). */
  rowKey: string;
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
  const rows = debts.flatMap((debt) => flattenDebt(debt, slices, fillNew));
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

/**
 * Полоса канона: N строк = max(Value по срезам). Зерно 1 (QIV Ttl, погашено) — только первая строка.
 *
 * @param debt канон
 * @param slices срезы книги
 * @param fillNew колонки *_new
 * @return строки предпросмотра
 */
function flattenDebt(
  debt: SudzRsltDebt,
  slices: SliceMeta[],
  fillNew: boolean
): SudzRsltPreviewRow[] {
  const nRows = bandRowCount(debt, slices);
  const basePeriods = slices.length ? periodsOn(debt, slices[0].uplDate) : [];
  const baseOverd = sumOverd(basePeriods);
  const rows: SudzRsltPreviewRow[] = [];
  for (let r = 0; r < nRows; r++) {
    const row: SudzRsltPreviewRow = {
      dbtKey: debt.dbtKey,
      rowKey: `${debt.dbtKey}:${r}`,
      account_num: debt.accountNum
    };
    slices.forEach((slice, index) => {
      const periods = periodsOn(debt, slice.uplDate);
      const p = slice.uplDate;
      const first = index === 0;
      row[`${p}_invNumEnum`] = pick(mapPeriod(periods, (x) => x.invNumEnum), r, nRows);
      row[`${p}_idNum`] = pick(mapPeriod(periods, (x) => x.idNum), r, nRows);
      row[`${p}_cnNumEnum`] = pick(mapPeriod(periods, (x) => x.cnNumEnum), r, nRows);
      row[`${p}_csoCnDate`] = pick(mapPeriod(periods, (x) => x.csoCnDate), r, nRows);
      row[`${p}_org_id_value_l`] = pick(mapPeriod(periods, (x) => x.orgIdValueL), r, nRows);
      row[`${p}_ITN`] = pick(mapPeriod(periods, (x) => x.itn), r, nRows);
      row[`${p}_CtptOrg`] = pick(mapPeriod(periods, (x) => x.ctptOrg), r, nRows);
      row[`${p}_Maturity`] = pick(mapPeriod(periods, (x) => x.maturity), r, nRows);
      row[`${p}_Ttl`] = pick(mapPeriod(periods, (x) => x.ttl), r, nRows);
      row[`${p}_Overd`] = pick(mapPeriod(periods, (x) => x.overd), r, nRows);
      row[`${p}_CstAgPnKey`] = null;
      row[`${p}_CstAgPnCode`] = pick(mapPeriod(periods, (x) => x.cstAgPnCode), r, nRows);
      row[`${p}_CstAgPnName`] = pick(mapPeriod(periods, (x) => x.cstAgPnName), r, nRows);
      row[`${p}_AgOrg`] = pick(mapPeriod(periods, (x) => x.agOrg), r, nRows);
      if (!first) {
        const curr = periods.length ? sumOverd(periods) : null;
        row[`${p}_погашено`] = pick([pogashenoAccess(baseOverd, curr)], r, nRows);
      }
    });
    row['Куратор от Управления'] = debt.curator;
    row['Мероприятия по погашению дебиторской задолженности'] = debt.mery;
    row['Код стройки'] = debt.cstCode;
    row['Код стройкиN'] = debt.cstName;
    row.cur_new = fillNew ? (debt.curatorNew ?? null) : null;
    row.mery_new = fillNew ? (debt.meryNew ?? null) : null;
    row.cstAgPn_new = fillNew ? (debt.cstCodeNew ?? null) : null;
    rows.push(row);
  }
  return rows;
}

function bandRowCount(debt: SudzRsltDebt, slices: SliceMeta[]): number {
  let n = 1;
  for (const slice of slices) {
    n = Math.max(n, periodsOn(debt, slice.uplDate).length);
  }
  return n;
}

function periodsOn(debt: SudzRsltDebt, uplDate: string): SudzRsltPeriod[] {
  return (debt.periods ?? []).filter((period) => period.uplDate === uplDate);
}

function mapPeriod<T>(
  periods: SudzRsltPeriod[],
  getter: (period: SudzRsltPeriod) => T
): Array<T | null> {
  return periods.map((period) => getter(period) ?? null);
}

/**
 * Как Excel writeBandCol: одно значение на полосе — только первая строка (merge).
 */
function pick(
  values: Array<string | number | null>,
  rowIndex: number,
  nRows: number
): string | number | null {
  const merge = nRows > 1 && values.length <= 1;
  if (merge) {
    return rowIndex === 0 && values.length > 0 ? (values[0] ?? null) : null;
  }
  return rowIndex < values.length ? (values[rowIndex] ?? null) : null;
}

function sumOverd(periods: SudzRsltPeriod[]): number | null {
  let sum: number | null = null;
  for (const period of periods) {
    if (period.overd == null) {
      continue;
    }
    sum = sum == null ? period.overd : sum + period.overd;
  }
  return sum;
}

/** Access / S42d: NULLIF(Overd(база) − ISNULL(Overd(d), 0), 0); отрицательную дельту не пишем. */
export function pogashenoAccess(
  baseOverd: number | null | undefined,
  currOverdOrNull: number | null | undefined
): number | null {
  if (baseOverd == null) {
    return null;
  }
  const curr = currOverdOrNull ?? 0;
  const delta = baseOverd - curr;
  if (delta <= 0) {
    return null;
  }
  return delta;
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
