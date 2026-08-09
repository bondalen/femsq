/**
 * Предпросмотр годового свода D644: колонки как в Excel «СВОД по субсчетам Д644».
 */
import type { FemsqTableColumn } from 'fequlib';
import type { SudzSvodResult } from '@/types/sudz';

export type SudzSvodPreviewRow = {
  dbtKey: number;
  accountNum: string;
  accountName: string;
  overdBase: number | null;
  repaid: number | null;
  overdCurr: number | null;
  repaidPct: number | null;
  isTotal: boolean;
} & Record<string, unknown>;

export interface SudzSvodPreview {
  rows: SudzSvodPreviewRow[];
  columns: FemsqTableColumn<SudzSvodPreviewRow>[];
}

/**
 * Форматирует «Погашено в %» (SQL уже отдаёт шкалу 0..100, не долю 0..1).
 */
function formatPct(value: unknown): string {
  if (value == null || value === '') {
    return '';
  }
  const n = Number(value);
  if (Number.isNaN(n)) {
    return String(value);
  }
  return `${n.toFixed(2)}%`;
}

/**
 * Строит колонки/строки для native-предпросмотра Progress (Свод).
 *
 * @param svod результат {@code sudzD644Svod}
 */
export function buildSudzSvodPreview(svod: SudzSvodResult): SudzSvodPreview {
  const columns: FemsqTableColumn<SudzSvodPreviewRow>[] = [
    { name: 'accountNum', label: '№ счётов бухгалтерского учета', field: 'accountNum' },
    { name: 'accountName', label: 'Наименование счёта', field: 'accountName' },
    {
      name: 'overdBase',
      label: 'Сумма просроченной ДЗ на начало года',
      field: 'overdBase',
      headerClasses: 'proto-h--overd'
    },
    {
      name: 'repaid',
      label: 'Погашено просроченной ДЗ с начала года',
      field: 'repaid'
    },
    {
      name: 'overdCurr',
      label: 'Остаток просроченной ДЗ портфеля',
      field: 'overdCurr',
      headerClasses: 'proto-h--overd'
    },
    {
      name: 'repaidPct',
      label: 'Погашено в %',
      field: 'repaidPct',
      format: (v) => formatPct(v)
    }
  ];

  const rows: SudzSvodPreviewRow[] = (svod.accounts ?? []).map((a, idx) => ({
    dbtKey: idx + 1,
    accountNum: a.accountNum != null ? String(a.accountNum) : '',
    accountName: a.accountName ?? '',
    overdBase: a.overdBase,
    repaid: a.repaid,
    overdCurr: a.overdCurr,
    repaidPct: a.repaidPct,
    isTotal: false
  }));

  if (svod.total) {
    rows.push({
      dbtKey: 0,
      accountNum: 'ВСЕГО',
      accountName: '',
      overdBase: svod.total.overdBase,
      repaid: svod.total.repaid,
      overdCurr: svod.total.overdCurr,
      repaidPct: svod.total.repaidPct,
      isTotal: true
    });
  }

  return { rows, columns };
}
