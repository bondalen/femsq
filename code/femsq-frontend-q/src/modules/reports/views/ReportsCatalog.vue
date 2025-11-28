<template>
  <div class="reports-catalog q-gutter-y-lg">
    <QCard flat bordered>
      <QCardSection class="row items-center justify-between q-gutter-md">
        <div>
          <div class="text-h5 text-weight-bold">Каталог отчётов</div>
          <div class="text-body2 text-grey-6">
            {{ headerMessage }}
          </div>
        </div>
        <div class="column items-end q-gutter-xs">
          <div class="text-caption text-grey-7">
            Найдено: {{ filteredTotal }}
          </div>
          <QBtn
            color="primary"
            outline
            :loading="loading"
            label="Обновить список"
            @click="handleRefresh"
          />
        </div>
      </QCardSection>

      <QCardSection>
        <QBanner
          v-if="error"
          class="bg-red-1 text-negative q-mb-md"
          rounded
          dense
          inline-actions
        >
          <div>{{ error }}</div>
          <template #action>
            <QBtn flat color="negative" label="Повторить" @click="handleRefresh" />
          </template>
        </QBanner>

        <QBanner
          v-else-if="loading"
          class="bg-blue-1 text-blue-10 q-mb-md"
          rounded
          dense
        >
          Загрузка отчётов…
        </QBanner>

        <div class="row q-col-gutter-md q-mb-md">
          <div class="col-12 col-md-4">
            <QSelect
              v-model="filters.category"
              :options="categoryOptions"
              label="Категория"
              filled
              dense
              clearable
              emit-value
              map-options
            />
          </div>
          <div class="col-12 col-md-4">
            <QSelect
              v-model="filters.tag"
              :options="tagOptions"
              label="Тег"
              filled
              dense
              clearable
              emit-value
              map-options
            />
          </div>
          <div class="col-12 col-md-4">
            <QInput
              v-model="filters.search"
              label="Поиск по названию"
              filled
              dense
              clearable
              debounce="200"
            >
              <template #append>
                <QIcon name="search" />
              </template>
            </QInput>
          </div>
        </div>

        <div v-if="filteredReports.length > 0" class="row q-col-gutter-lg">
          <div v-for="report in filteredReports" :key="report.id" class="col-12 col-md-6 col-lg-4">
            <QCard class="full-height cursor-pointer" flat bordered @click="handleReportClick(report)">
              <QCardSection class="row items-start justify-between">
                <div class="text-subtitle1 text-weight-medium">
                  {{ report.name }}
                </div>
                <QChip
                  dense
                  square
                  :color="report.source === 'embedded' ? 'positive' : 'info'"
                  text-color="white"
                >
                  {{ report.source === 'embedded' ? 'Встроенный' : 'Внешний' }}
                </QChip>
              </QCardSection>

              <QCardSection class="q-gutter-y-sm">
                <div v-if="report.description" class="text-body2 text-grey-7">
                  {{ report.description }}
                </div>
                <div v-if="report.category" class="text-caption text-grey-6">
                  {{ report.category }}
                </div>
              </QCardSection>

              <QSeparator v-if="report.tags?.length" />
              <QCardSection v-if="report.tags?.length">
                <div class="row q-col-gutter-sm">
                  <div v-for="tag in report.tags" :key="tag" class="col-auto">
                    <QChip dense outline color="primary" text-color="primary">
                      {{ tag }}
                    </QChip>
                  </div>
                </div>
              </QCardSection>
            </QCard>
          </div>
        </div>

        <div v-else class="text-center q-pa-xl text-grey-6">
          <div class="text-subtitle1 q-mb-sm">Отчёты не найдены</div>
          <QBtn flat color="primary" label="Обновить" @click="handleRefresh" />
        </div>
      </QCardSection>
    </QCard>
    <ReportParametersDialog
      v-if="selectedReport"
      :open="dialogOpen"
      :report-id="selectedReport.id"
      @close="handleDialogClose"
      @generate="handleGenerate"
      @preview="handlePreview"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { QBanner, QBtn, QCard, QCardSection, QChip, QIcon, QInput, QSelect, QSeparator } from 'quasar';

import ReportParametersDialog from '@/modules/reports/components/ReportParametersDialog.vue';
import { useReportsStore } from '@/stores/reports';
import type { ReportInfo } from '@/types/reports';

const reportsStore = useReportsStore();

const loading = computed(() => reportsStore.loading);
const error = computed(() => reportsStore.error);
const filteredReports = computed(() => reportsStore.filteredReports);
const filteredTotal = computed(() => reportsStore.filteredTotal);
const categories = computed(() => reportsStore.categories);
const tags = computed(() => reportsStore.tags);
const filters = reportsStore.filters;

const selectedReport = ref<ReportInfo | null>(null);
const dialogOpen = ref(false);

const headerMessage = computed(() => {
  if (loading.value) {
    return 'Загрузка каталога отчётов…';
  }
  if (error.value) {
    return 'Произошла ошибка при загрузке.';
  }
  if (!filteredTotal.value) {
    return 'Отчёты отсутствуют. Попробуйте обновить список.';
  }
  return 'Выберите отчёт для генерации.';
});

const categoryOptions = computed(() => [
  { label: 'Все категории', value: '' },
  ...categories.value.map((cat) => ({ label: cat, value: cat }))
]);

const tagOptions = computed(() => [
  { label: 'Все теги', value: '' },
  ...tags.value.map((tag) => ({ label: tag, value: tag }))
]);

function handleRefresh(): void {
  reportsStore.loadReports();
  reportsStore.loadCategories();
  reportsStore.loadTags();
}

function handleReportClick(report: ReportInfo): void {
  selectedReport.value = report;
  dialogOpen.value = true;
}

function handleDialogClose(): void {
  dialogOpen.value = false;
  selectedReport.value = null;
}

async function handleGenerate(
  format: 'pdf' | 'excel' | 'html',
  parameters: Record<string, unknown>
): Promise<void> {
  if (!selectedReport.value) {
    return;
  }

  try {
    const blob = await reportsStore.generateReportRequest({
      reportId: selectedReport.value.id,
      parameters,
      format
    });
    const fileName = `${selectedReport.value.id}_${new Date().toISOString().slice(0, 10)}.${format}`;
    reportsStore.downloadBlob(blob, fileName);
    handleDialogClose();
  } catch (err) {
    console.error('[ReportsCatalog] Failed to generate report:', err);
  }
}

async function handlePreview(parameters: Record<string, unknown>): Promise<void> {
  if (!selectedReport.value) {
    return;
  }

  try {
    const blob = await reportsStore.generatePreviewRequest(selectedReport.value.id, parameters);
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
    window.setTimeout(() => URL.revokeObjectURL(url), 100);
  } catch (err) {
    console.error('[ReportsCatalog] Failed to generate preview:', err);
  }
}

onMounted(() => {
  handleRefresh();
});
</script>

<style scoped>
.reports-catalog {
  width: 100%;
}

.full-height {
  min-height: 220px;
}
</style>






