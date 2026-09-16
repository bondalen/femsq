/**
 * Нормализация пути из поля «Файл» (как в Проводнике / «Копировать как путь»).
 */

/**
 * Снимает кавычки и ложный ведущий `/` перед Windows-диском (`/D:\…` → `D:\…`).
 *
 * @param raw значение из input
 * @returns путь для записи в БД
 */
export function normalizeExplorerPath(raw: string): string {
  let trimmed = raw.trim();
  if (trimmed.length >= 2) {
    const first = trimmed[0];
    const last = trimmed[trimmed.length - 1];
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      trimmed = trimmed.slice(1, -1).trim();
    }
  }
  // Linux/браузер иногда даёт /D:\… или /D:/… — для Java/Excel нужен Windows-путь оператора
  if (/^\/[A-Za-z]:[\\/]/.test(trimmed)) {
    trimmed = trimmed.slice(1);
  }
  return trimmed;
}
