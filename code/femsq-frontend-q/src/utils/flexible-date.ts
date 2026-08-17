/**
 * Разбор дат из UI (копипаст из Access/Excel/доков).
 * На выходе ISO {@code YYYY-MM-DD} или {@code null} для пустой строки.
 */

/**
 * Парсит дату: {@code YYYY-MM-DD}, {@code ДД.ММ.ГГГГ}, {@code ДД/ММ/ГГГГ}, {@code ДД-ММ-ГГ}, и т.п.
 *
 * @param input сырой ввод
 * @returns ISO-дата или null если пусто
 * @throws Error если формат не распознан / дата невалидна
 */
export function parseFlexibleDate(input: string | null | undefined): string | null {
  const raw = (input ?? '').trim();
  if (raw === '') {
    return null;
  }

  const iso = raw.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (iso) {
    return toIso(Number(iso[1]), Number(iso[2]), Number(iso[3]), raw);
  }

  const dmy = raw.match(/^(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})$/);
  if (dmy) {
    let year = Number(dmy[3]);
    if (year < 100) {
      year += year >= 70 ? 1900 : 2000;
    }
    return toIso(year, Number(dmy[2]), Number(dmy[1]), raw);
  }

  throw new Error(`Не удалось разобрать дату: «${raw}». Ожидается ДД.ММ.ГГГГ или ГГГГ-ММ-ДД.`);
}

function toIso(year: number, month: number, day: number, raw: string): string {
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
    throw new Error(`Некорректная дата: «${raw}»`);
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    throw new Error(`Некорректная дата: «${raw}»`);
  }
  const dt = new Date(Date.UTC(year, month - 1, day));
  if (dt.getUTCFullYear() !== year || dt.getUTCMonth() !== month - 1 || dt.getUTCDate() !== day) {
    throw new Error(`Несуществующая дата: «${raw}»`);
  }
  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}
