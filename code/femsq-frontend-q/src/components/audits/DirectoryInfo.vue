<template>
  <q-card flat bordered class="q-mb-md">
    <q-card-section class="bg-grey-3">
      <div class="text-h6">
        <q-icon name="folder_open" class="q-mr-sm" />
        Директория
      </div>
    </q-card-section>

    <q-card-section v-if="directory">
      <div class="row q-col-gutter-md">
        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Ключ</div>
          <div class="text-body1">{{ directory.key }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Путь</div>
          <div class="text-body1">{{ directory.path || '—' }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Дата создания</div>
          <div class="text-body1">{{ formatDate(directory.created) }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Дата обновления</div>
          <div class="text-body1">{{ formatDate(directory.updated) }}</div>
        </div>
      </div>
    </q-card-section>

    <q-card-section v-else-if="loading">
      <q-linear-progress indeterminate color="primary" />
      <div class="text-center q-mt-sm text-grey-7">Загрузка директории...</div>
    </q-card-section>

    <q-card-section v-else>
      <q-banner class="bg-blue-1 text-blue-9">
        <template v-slot:avatar>
          <q-icon name="info" color="blue" />
        </template>
        Директория не загружена
      </q-banner>
    </q-card-section>
  </q-card>
</template>

<script setup lang="ts">
import type { DirectoryDto } from '@/types/files';

interface Props {
  directory: DirectoryDto | null;
  loading?: boolean;
}

defineProps<Props>();

/**
 * Форматирует дату в читаемый формат
 */
function formatDate(date: string | null): string {
  if (!date) return '—';
  try {
    return new Date(date).toLocaleString('ru-RU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch {
    return date;
  }
}
</script>

<style scoped>
.text-caption {
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
</style>
