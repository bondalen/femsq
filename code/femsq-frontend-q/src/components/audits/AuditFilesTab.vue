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
    
    <!-- Ошибка загрузки -->
    <v-alert
      v-if="error"
      type="error"
      variant="tonal"
      class="mt-4"
      closable
      @click:close="error = null"
    >
      {{ error }}
    </v-alert>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useDirectoriesStore } from '@/stores/directories'
import DirectoryInfo from './DirectoryInfo.vue'
import FilesList from './FilesList.vue'

interface Props {
  auditId: number
}

const props = defineProps<Props>()

const directoriesStore = useDirectoriesStore()

// State
const loadingDirectory = ref(false)
const error = ref<string | null>(null)

// Computed
const currentDirectory = computed(() => directoriesStore.currentDirectory)

// Lifecycle
onMounted(async () => {
  await loadDirectory()
})

// Methods
async function loadDirectory() {
  loadingDirectory.value = true
  error.value = null
  
  try {
    await directoriesStore.loadByAuditId(props.auditId)
  } catch (err) {
    error.value = err instanceof Error 
      ? err.message 
      : 'Ошибка загрузки директории ревизии'
    console.error('Failed to load directory:', err)
  } finally {
    loadingDirectory.value = false
  }
}
</script>

<style scoped>
.audit-files-tab {
  padding: 16px 0;
}
</style>
