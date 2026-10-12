/**
 * Протокол одного прогона «D644 · Выгрузить». Заменяет текст yr_Progress.
 */

import type { SudzD644Row } from '@/types/sudz';

export interface SudzD644ProgressInput {
  now: Date;
  yr: number;
  cmmGr: number | null;
  currUpl: number;
  statusOnDate: string | null;
  mode: 'preview' | 'excel';
  rows: SudzD644Row[] | null;
  fileName?: string | null;
  savedWhere?: string | null;
  failureReason?: string | null;
}

/**
 * Текст протокола предпросмотра или Excel.
 */
export function formatSudzD644Progress(input: SudzD644ProgressInput): string {
  const lines: string[] = [
    'D644 · Выгрузить',
    formatStamp(input.now),
    `Год: ${input.yr}`,
    `Группа: ${input.cmmGr ?? '—'}`
  ];
  const status = input.statusOnDate?.trim();
  lines.push(status ? `Срез: ${input.currUpl}, состояние ${status}` : `Срез: ${input.currUpl}`);
  lines.push(input.mode === 'excel' ? 'Режим: Excel' : 'Режим: предпросмотр');
  if (input.rows) {
    lines.push(`Строк: ${input.rows.length}`);
    const accounts = countAccounts(input.rows);
    if (accounts.length > 0) {
      lines.push(`Счета: ${accounts.map(([account, count]) => `${account} — ${count}`).join(', ')}`);
    }
    const empty = input.rows.filter((row) => !row.comment644 || row.comment644.trim() === '').length;
    lines.push(`Комментарий филиала: заполнено ${input.rows.length - empty}, пусто ${empty}`);
  }
  if (input.mode === 'excel' && input.fileName) {
    lines.push(`Файл: ${input.fileName}`);
  }
  if (input.mode === 'excel' && input.savedWhere) {
    lines.push(`Куда: ${input.savedWhere}`);
  }
  if (input.failureReason) {
    lines.push('Итог: показано 0');
    lines.push(`Причина: ${input.failureReason.trim()}`);
  } else if (input.mode === 'excel') {
    lines.push(`Итог: сохранено ${input.rows?.length ?? 0}`);
  } else {
    lines.push(`Итог: показано ${input.rows?.length ?? 0}`);
  }
  return lines.join('\n');
}

function formatStamp(now: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
}

function countAccounts(rows: SudzD644Row[]): Array<[string, number]> {
  const counts = new Map<string, number>();
  for (const row of rows) {
    const account = row.accountNum == null ? '—' : String(row.accountNum);
    counts.set(account, (counts.get(account) ?? 0) + 1);
  }
  return [...counts.entries()].sort((left, right) => left[0].localeCompare(right[0], 'ru'));
}
