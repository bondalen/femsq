<template>
  <div class="audit-files-tab">
    <!-- Информация о директории -->
    <!-- ВРЕМЕННО СКРЫТО ДЛЯ ДИАГНОСТИКИ: проблема с позиционированием -->
    <DirectoryInfo 
      v-if="showDirectoryInfo" 
      :directory="currentDirectory" 
      :loading="loadingDirectory" 
    />

    <!-- Список файлов -->
    <!-- ВРЕМЕННО СКРЫТО ДЛЯ ДИАГНОСТИКИ: проблема с позиционированием -->
    <FilesList 
      v-if="showFilesList" 
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
import { ref, onMounted, computed } from 'vue';
import { useQuasar } from 'quasar';
import { useDirectoriesStore } from '@/stores/directories';
import DirectoryInfo from './DirectoryInfo.vue';
import FilesList from './FilesList.vue';

interface Props {
  auditId: number;
}

const props = defineProps<Props>();

const $q = useQuasar();
const directoriesStore = useDirectoriesStore();

// State
const loadingDirectory = ref(false);
const error = ref<string | null>(null);
// ВРЕМЕННО: флаги для скрытия компонентов при диагностике проблемы с позиционированием
const showDirectoryInfo = ref(false);
const showFilesList = ref(false);

// Computed
const currentDirectory = computed(() => directoriesStore.currentDirectory);

// Lifecycle
onMounted(async () => {
  await loadDirectory();
});

// Methods
async function loadDirectory() {
  loadingDirectory.value = true;
  error.value = null;

  try {
    await directoriesStore.loadByAuditId(props.auditId);
  } catch (err) {
    error.value = `Ошибка загрузки директории: ${err instanceof Error ? err.message : 'Неизвестная ошибка'}`;
    $q.notify({
      type: 'negative',
      message: error.value,
      position: 'top-right'
    });
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
