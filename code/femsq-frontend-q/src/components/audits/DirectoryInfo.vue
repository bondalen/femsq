<template>
  <v-card variant="outlined" class="mb-4">
    <v-card-title class="bg-grey-lighten-4">
      <v-icon icon="mdi-folder-outline" class="mr-2" />
      Директория
    </v-card-title>
    
    <v-card-text v-if="directory">
      <v-row>
        <v-col cols="12" md="6">
          <div class="text-caption text-grey">Название директории</div>
          <div class="text-body-1 font-weight-medium">{{ directory.dirName }}</div>
        </v-col>
        
        <v-col cols="12" md="6">
          <div class="text-caption text-grey">Путь</div>
          <div class="text-body-1 font-mono">{{ directory.dir }}</div>
        </v-col>
      </v-row>
      
      <v-row v-if="directory.created || directory.updated" class="mt-2">
        <v-col cols="12" md="6">
          <div class="text-caption text-grey">Создано</div>
          <div class="text-body-2">{{ formatDate(directory.created) }}</div>
        </v-col>
        
        <v-col cols="12" md="6">
          <div class="text-caption text-grey">Обновлено</div>
          <div class="text-body-2">{{ formatDate(directory.updated) }}</div>
        </v-col>
      </v-row>
    </v-card-text>
    
    <v-card-text v-else-if="loading">
      <v-progress-linear indeterminate color="primary" />
    </v-card-text>
    
    <v-card-text v-else>
      <v-alert type="info" variant="tonal">
        Директория не загружена
      </v-alert>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import type { DirectoryDto } from '@/types/files'

interface Props {
  directory: DirectoryDto | null
  loading?: boolean
}

defineProps<Props>()

function formatDate(date: string | null): string {
  if (!date) return 'Не указано'
  try {
    return new Date(date).toLocaleString('ru-RU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch {
    return date
  }
}
</script>

<style scoped>
.font-mono {
  font-family: 'Courier New', monospace;
}
</style>
