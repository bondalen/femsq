<template>
  <div class="audit-files-tab">
    <!-- Информация о директории -->
    <DirectoryInfo 
      :directory="currentDirectory" 
      :loading="loadingDirectory" 
    />

    <!-- Список файлов -->
    <FilesList 
      :dir-id="currentDirectory?.key ?? null" 
    />

    <!-- Сообщение об ошибке -->
    <q-banner v-if="error" class="bg-negative text-white q-mt-md">
      <template v-slot:avatar>
        <q-icon name="error" color="white" />
      </template>
      {{ error }}
    </q-banner>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import * as directoriesApi from '@/api/directories-api';
import type { RaDirDto } from '@/types/audits';
import DirectoryInfo from './DirectoryInfo.vue';
import FilesList from './FilesList.vue';

interface Props {
  auditId: number;
}

const props = defineProps<Props>();

const $q = useQuasar();

// State
const currentDirectory = ref<RaDirDto | null>(null);
const loadingDirectory = ref(false);
const error = ref<string | null>(null);

// Lifecycle
onMounted(async () => {
  await loadDirectory();
});

// Methods
async function loadDirectory() {
  loadingDirectory.value = true;
  error.value = null;

  try {
    const directory = await directoriesApi.getDirectoryByAuditId(props.auditId);
    currentDirectory.value = directory;
  } catch (err) {
    error.value = `Ошибка загрузки директории: ${err instanceof Error ? err.message : 'Неизвестная ошибка'}`;
    $q.notify({
      type: 'negative',
      message: error.value,
      position: 'top-right'
    });
    currentDirectory.value = null;
  } finally {
    loadingDirectory.value = false;
  }
}
</script>

<style scoped>
.audit-files-tab {
  max-width: 1400px;
  margin: 0 auto;
}
</style>
