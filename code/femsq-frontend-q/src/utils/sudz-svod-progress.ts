/**
 * Протокол одного прогона «Свод · Выгрузить». Заменяет текст yr_Progress.
 */

export interface SudzSvodProgressInput {
  now: Date;
  yr: number;
  currUpl: number;
  statusOnDate: string | null;
  mode: 'preview' | 'excel';
  accountCount: number | null;
  fileName?: string | null;
  savedWhere?: string | null;
  failureReason?: string | null;
}

/**
 * Текст протокола предпросмотра или Excel.
 */
export function formatSudzSvodProgress(input: SudzSvodProgressInput): string {
  const lines: string[] = [
    'Свод · Выгрузить',
    formatStamp(input.now),
    `Год: ${input.yr}`
  ];
  const status = input.statusOnDate?.trim();
  lines.push(status ? `Срез: ${input.currUpl}, состояние ${status}` : `Срез: ${input.currUpl}`);
  lines.push(input.mode === 'excel' ? 'Режим: Excel' : 'Режим: предпросмотр');
  if (input.accountCount != null) {
    lines.push(`Счетов: ${input.accountCount}`);
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
    lines.push(`Итог: сохранено ${input.accountCount ?? 0}`);
  } else {
    lines.push(`Итог: показано ${input.accountCount ?? 0}`);
  }
  return lines.join('\n');
}

function formatStamp(now: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
}
