/**
 * Контекст входа на экран КСДСФ: источник (свод / платежи) и якорь строки очереди.
 */

import { ref } from 'vue';
import { defineStore } from 'pinia';

export type SudzSfDoubleSource = 'dbt' | 'pmt';

export const useSudzSfDoubleSessionStore = defineStore('sudz-sf-double-session', () => {
  const source = ref<SudzSfDoubleSource>('dbt');
  const anchorCiusKey = ref<number | null>(null);

  /**
   * Открыть КСДСФ из экрана загрузки свода.
   *
   * @param ciusKey опциональный якорь строки очереди
   */
  function openFromDbt(ciusKey?: number | null): void {
    source.value = 'dbt';
    anchorCiusKey.value = ciusKey ?? null;
  }

  /**
   * Открыть КСДСФ из экрана загрузки платежей.
   *
   * @param ciusKey опциональный якорь строки очереди
   */
  function openFromPmt(ciusKey?: number | null): void {
    source.value = 'pmt';
    anchorCiusKey.value = ciusKey ?? null;
  }

  /**
   * Сбрасывает якорь после применения в UI.
   */
  function clearAnchor(): void {
    anchorCiusKey.value = null;
  }

  return {
    source,
    anchorCiusKey,
    openFromDbt,
    openFromPmt,
    clearAnchor
  };
});
