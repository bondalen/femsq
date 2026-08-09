/**
 * Предпросмотр D644: колонки как в Excel-приложении (без dbtKey в шапке Excel;
 * dbtKey оставляем для detail-панели).
 */
import type { FemsqTableColumn } from 'fequlib';
import type { SudzD644Row } from '@/types/sudz';

export type SudzD644PreviewRow = SudzD644Row & Record<string, unknown>;

export interface SudzD644Preview {
  rows: SudzD644PreviewRow[];
  columns: FemsqTableColumn<SudzD644PreviewRow>[];
}

/**
 * Строит колонки/строки для native-предпросмотра Progress.
 */
export function buildSudzD644Preview(rows: SudzD644Row[]): SudzD644Preview {
  const columns: FemsqTableColumn<SudzD644PreviewRow>[] = [
    { name: 'dbtKey', label: 'dbtKey', field: 'dbtKey' },
    { name: 'accountNum', label: 'Счёт Главной книги', field: 'accountNum' },
    { name: 'agent', label: 'Агент', field: 'agent' },
    { name: 'orgId', label: '№ контрагента', field: 'orgId' },
    { name: 'itn', label: 'ИНН', field: 'itn' },
    { name: 'counterpart', label: 'Контрагент', field: 'counterpart' },
    { name: 'contract', label: 'Договор', field: 'contract' },
    { name: 'contractDate', label: 'Дата договора', field: 'contractDate' },
    { name: 'invoice', label: 'Реквизиты документа…', field: 'invoice' },
    { name: 'dateStart', label: 'Дата образования', field: 'dateStart' },
    { name: 'maturityBase', label: 'Срок погашения (base)', field: 'maturityBase' },
    { name: 'ttlBase', label: 'Всего (base)', field: 'ttlBase' },
    { name: 'overdBase', label: 'Просрочка (base)', field: 'overdBase', headerClasses: 'proto-h--overd' },
    { name: 'maturityCurr', label: 'Срок погашения (curr)', field: 'maturityCurr' },
    { name: 'overdCurr', label: 'Просрочка (curr)', field: 'overdCurr', headerClasses: 'proto-h--overd' },
    { name: 'repaid', label: 'Погашено с начала года', field: 'repaid' },
    { name: 'cstCode', label: 'Код стройки', field: 'cstCode' },
    { name: 'cstName', label: 'Наименование стройки', field: 'cstName' },
    { name: 'comment644', label: 'Комментарий Филиала 644', field: 'comment644', headerClasses: 'proto-h--curator' }
  ];
  return {
    rows: rows.map((r) => ({ ...r })),
    columns
  };
}
