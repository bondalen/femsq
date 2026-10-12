/**
 * Протокол одного прогона «Rslt повтор · Выгрузить». Заменяет текст yr_Progress.
 */

import type { SudzRsltDebt } from '@/types/sudz';

export interface SudzRsltPovtorProgressInput {
  now: Date;
  yr: number;
  cmmGr: number | null;
  cmmGrNew: number | null;
  asOfUpl: number;
  statusOnDate: string | null;
  mode: 'preview' | 'excel';
  debts: SudzRsltDebt[] | null;
  rowCount: number | null;
  sliceCount: number | null;
  fileName?: string | null;
  savedWhere?: string | null;
  failureReason?: string | null;
}

/**
 * Текст протокола предпросмотра или Excel.
 */
export function formatSudzRsltPovtorProgress(input: SudzRsltPovtorProgressInput): string {
  const lines: string[] = [
    'Rslt повтор · Выгрузить',
    formatStamp(input.now),
    `Год: ${input.yr}`,
    `Группа: ${input.cmmGr ?? '—'}`,
    `Группа новых: ${input.cmmGrNew ?? '—'}`
  ];
  const status = input.statusOnDate?.trim();
  lines.push(status ? `Срез: ${input.asOfUpl}, состояние ${status}` : `Срез: ${input.asOfUpl}`);
  lines.push(input.mode === 'excel' ? 'Режим: Excel' : 'Режим: предпросмотр');
  if (input.debts) {
    lines.push(`Долгов: ${input.debts.length}`);
    if (input.rowCount != null) {
      lines.push(`Строк: ${input.rowCount}`);
    }
    if (input.sliceCount != null) {
      lines.push(`Срезов: ${input.sliceCount}`);
    }
    lines.push(
      `*_new заполнено: куратор ${countFilled(input.debts, 'curatorNew')}, мероприятие ${countFilled(input.debts, 'meryNew')}, код ${countFilled(input.debts, 'cstCodeNew')}`
    );
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
    lines.push(`Итог: сохранено ${input.rowCount ?? input.debts?.length ?? 0}`);
  } else {
    lines.push(`Итог: показано ${input.rowCount ?? input.debts?.length ?? 0}`);
  }
  return lines.join('\n');
}

function formatStamp(now: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
}

function countFilled(debts: SudzRsltDebt[], field: 'curatorNew' | 'meryNew' | 'cstCodeNew'): number {
  return debts.filter((debt) => {
    const value = debt[field];
    return value != null && String(value).trim() !== '';
  }).length;
}
