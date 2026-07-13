import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import type { QVueGlobals } from 'quasar';

import {
  applyFemsqThemeToDocument,
  persistFemsqTheme,
  readStoredFemsqTheme,
  toggleFemsqThemeId,
  type FemsqThemeId
} from '@/theme/femsq-theme';

/**
 * Pinia-store глобальной темы приложения (0050).
 */
export const useThemeStore = defineStore('theme', () => {
  const themeId = ref<FemsqThemeId>(readStoredFemsqTheme());
  let quasar: QVueGlobals | null = null;

  const isDark = computed(() => themeId.value === 'kimbie-dark');

  /**
   * Привязывает экземпляр Quasar для синхронизации {@link QVueGlobals.dark}.
   */
  function bindQuasar(instance: QVueGlobals): void {
    quasar = instance;
    quasar.dark.set(isDark.value);
  }

  /**
   * Применяет тему к DOM, localStorage и Quasar Dark.
   */
  function applyTheme(theme: FemsqThemeId): void {
    themeId.value = theme;
    persistFemsqTheme(theme);
    applyFemsqThemeToDocument(theme);
    quasar?.dark.set(theme === 'kimbie-dark');
  }

  /**
   * Переключает Kimbie Dark ↔ VS Light.
   */
  function toggleTheme(): void {
    applyTheme(toggleFemsqThemeId(themeId.value));
  }

  return {
    themeId,
    isDark,
    bindQuasar,
    applyTheme,
    toggleTheme
  };
});
