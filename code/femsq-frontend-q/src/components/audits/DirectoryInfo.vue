<template>
  <q-card flat bordered class="directory-card">
    <q-card-section :class="compact ? 'directory-header-compact' : 'bg-grey-3'">
      <div :class="compact ? 'text-subtitle2 row items-center no-wrap' : 'text-h6'">
        <q-icon name="folder_open" class="q-mr-sm" />
        <span v-if="compact">Директория:</span>
        <span v-else>Директория</span>
        <template v-if="compact && directory">
          <span class="q-ml-sm text-weight-regular ellipsis">{{ directory.dir || '—' }}</span>
          <span class="q-ml-sm text-caption">#{{ directory.key }}</span>
        </template>
      </div>
    </q-card-section>

    <q-card-section v-if="directory && !compact">
      <div class="row q-col-gutter-md">
        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Ключ</div>
          <div class="text-body1">{{ directory.key }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Путь</div>
          <div class="text-body1">{{ directory.dir || '—' }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Дата создания</div>
          <div class="text-body1">{{ formatDate(directory.dirCreated) }}</div>
        </div>

        <div class="col-12 col-md-6">
          <div class="text-caption text-grey-7">Дата обновления</div>
          <div class="text-body1">{{ formatDate(directory.dirUpdated) }}</div>
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

    <!-- Список файлов внутри директории -->
    <q-card-section
      v-if="directory && showFiles"
      :class="compact ? 'files-host-compact q-pa-none' : 'q-pt-md'"
    >
      <FilesList :dir-id="directory.key" :compact="compact" />
    </q-card-section>
  </q-card>
</template>

<script setup lang="ts">
import type { RaDirDto } from '@/types/audits';
import FilesList from './FilesList.vue';

interface Props {
  directory: RaDirDto | null;
  loading?: boolean;
  showFiles?: boolean;
  compact?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  showFiles: true,
  compact: false
});

/**
 * Форматирует дату в читаемый формат
 */
function formatDate(date: string | null | undefined): string {
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
.directory-card {
  display: flex;
  flex-direction: column;
  min-height: 0;
  height: 100%;
}

.directory-header-compact {
  padding: 4px 8px !important;
  background: rgba(255, 255, 255, 0.04);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.files-host-compact {
  flex: 1 1 auto;
  min-height: 0;
  overflow: hidden;
}

.text-caption {
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
</style>
