import { ref } from 'vue';
import { defineStore } from 'pinia';

import * as directoriesApi from '@/api/directories-api';
import type { RaDirDto } from '@/types/audits';

export const useDirectoriesStore = defineStore('directories', () => {
  const directories = ref<RaDirDto[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function fetchDirectories(): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      directories.value = await directoriesApi.getDirectories();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Не удалось загрузить директории';
      error.value = message;
      console.error('[directories-store] Error fetching directories:', err);
      directories.value = [];
    } finally {
      loading.value = false;
    }
  }

  return {
    directories,
    loading,
    error,
    fetchDirectories
  };
});