import { afterEach, describe, expect, it, vi } from 'vitest';

import {
  DEFAULT_FEMSQ_THEME,
  FEMSQ_THEME_STORAGE_KEY,
  LEGACY_AUDIT_LOG_THEME_KEY,
  readStoredFemsqTheme,
  toggleFemsqThemeId
} from '@/theme/femsq-theme';

describe('femsq-theme', () => {
  afterEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('возвращает Kimbie Dark по умолчанию', () => {
    expect(readStoredFemsqTheme()).toBe(DEFAULT_FEMSQ_THEME);
  });

  it('читает сохранённую тему из femsq.theme', () => {
    localStorage.setItem(FEMSQ_THEME_STORAGE_KEY, 'vs-light');
    expect(readStoredFemsqTheme()).toBe('vs-light');
  });

  it('мигрирует устаревший femsq.auditLogTheme в femsq.theme', () => {
    localStorage.setItem(LEGACY_AUDIT_LOG_THEME_KEY, 'vs-light');
    expect(readStoredFemsqTheme()).toBe('vs-light');
    expect(localStorage.getItem(FEMSQ_THEME_STORAGE_KEY)).toBe('vs-light');
  });

  it('переключает тему', () => {
    expect(toggleFemsqThemeId('kimbie-dark')).toBe('vs-light');
    expect(toggleFemsqThemeId('vs-light')).toBe('kimbie-dark');
  });
});
