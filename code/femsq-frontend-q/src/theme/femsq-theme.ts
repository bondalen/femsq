/**
 * Глобальные темы FEMSQ UI (задача 0050).
 * Чистые функции — применимы до инициализации Pinia / Quasar.
 */

export type FemsqThemeId = 'kimbie-dark' | 'vs-light';

export const FEMSQ_THEME_STORAGE_KEY = 'femsq.theme';
export const LEGACY_AUDIT_LOG_THEME_KEY = 'femsq.auditLogTheme';

export const DEFAULT_FEMSQ_THEME: FemsqThemeId = 'kimbie-dark';

/**
 * Проверяет, что строка — допустимый идентификатор темы.
 */
export function isFemsqThemeId(value: string | null | undefined): value is FemsqThemeId {
  return value === 'kimbie-dark' || value === 'vs-light';
}

/**
 * Читает тему из localStorage с миграцией с устаревшего {@link LEGACY_AUDIT_LOG_THEME_KEY}.
 */
export function readStoredFemsqTheme(): FemsqThemeId {
  try {
    const stored = localStorage.getItem(FEMSQ_THEME_STORAGE_KEY);
    if (isFemsqThemeId(stored)) {
      return stored;
    }
    const legacy = localStorage.getItem(LEGACY_AUDIT_LOG_THEME_KEY);
    if (isFemsqThemeId(legacy)) {
      localStorage.setItem(FEMSQ_THEME_STORAGE_KEY, legacy);
      return legacy;
    }
  } catch {
    // localStorage недоступен
  }
  return DEFAULT_FEMSQ_THEME;
}

/**
 * Сохраняет выбранную тему в localStorage.
 */
export function persistFemsqTheme(theme: FemsqThemeId): void {
  try {
    localStorage.setItem(FEMSQ_THEME_STORAGE_KEY, theme);
  } catch {
    // ignore
  }
}

/**
 * Применяет тему к {@code document.documentElement} (без Quasar).
 */
export function applyFemsqThemeToDocument(theme: FemsqThemeId): void {
  if (typeof document === 'undefined') {
    return;
  }
  document.documentElement.dataset.femsqTheme = theme;
}

/**
 * Возвращает противоположную тему.
 */
export function toggleFemsqThemeId(theme: FemsqThemeId): FemsqThemeId {
  return theme === 'kimbie-dark' ? 'vs-light' : 'kimbie-dark';
}

/**
 * Иконка Material для кнопки переключения (показать целевое действие).
 */
export function themeToggleIcon(theme: FemsqThemeId): 'light_mode' | 'dark_mode' {
  return theme === 'kimbie-dark' ? 'light_mode' : 'dark_mode';
}

/**
 * Подпись для aria-label переключателя темы.
 */
export function themeToggleAriaLabel(theme: FemsqThemeId): string {
  return theme === 'kimbie-dark'
    ? 'Включить светлую тему (Visual Studio)'
    : 'Включить тёмную тему (Kimbie Dark)';
}
