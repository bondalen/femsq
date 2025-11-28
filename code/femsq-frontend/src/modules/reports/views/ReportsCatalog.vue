<template>
  <section class="reports-catalog">
    <header class="reports-catalog__header">
      <div>
        <h1>Каталог отчётов</h1>
        <p class="reports-catalog__subtitle">
          {{ headerMessage }}
        </p>
      </div>
      <div class="reports-catalog__meta">
        <span class="reports-catalog__counter">Найдено: {{ filteredTotal }}</span>
        <button
          type="button"
          class="reports-catalog__refresh"
          @click="handleRefresh"
          :disabled="loading"
        >
          {{ loading ? 'Загрузка…' : 'Обновить список' }}
        </button>
      </div>
    </header>

    <div v-if="error" class="reports-catalog__alert reports-catalog__alert--error">
      <span>{{ error }}</span>
      <button type="button" @click="handleRefresh">Повторить</button>
    </div>

    <div v-else-if="loading" class="reports-catalog__alert reports-catalog__alert--info">
      <span>Загрузка отчётов…</span>
    </div>

    <div v-else class="reports-catalog__content">
      <!-- Фильтры -->
      <div class="reports-catalog__filters">
        <div class="reports-catalog__filter-group">
          <label for="category-filter">Категория:</label>
          <select
            id="category-filter"
            v-model="filters.category"
            @change="handleFilterChange"
          >
            <option value="">Все категории</option>
            <option v-for="cat in categories" :key="cat" :value="cat">
              {{ cat }}
            </option>
          </select>
        </div>

        <div class="reports-catalog__filter-group">
          <label for="tag-filter">Тег:</label>
          <select
            id="tag-filter"
            v-model="filters.tag"
            @change="handleFilterChange"
          >
            <option value="">Все теги</option>
            <option v-for="tag in tags" :key="tag" :value="tag">
              {{ tag }}
            </option>
          </select>
        </div>

        <div class="reports-catalog__filter-group">
          <label for="search-filter">Поиск:</label>
          <input
            id="search-filter"
            type="text"
            v-model="filters.search"
            @input="handleFilterChange"
            placeholder="Название или описание..."
          />
        </div>
      </div>

      <!-- Grid отчётов -->
      <div v-if="filteredReports.length > 0" class="reports-catalog__grid">
        <div
          v-for="report in filteredReports"
          :key="report.id"
          class="reports-catalog__card"
          @click="handleReportClick(report)"
        >
          <div class="reports-catalog__card-header">
            <div class="reports-catalog__card-thumbnail">
              <img
                v-if="report.thumbnail"
                :src="report.thumbnail"
                :alt="report.name"
              />
              <span v-else class="reports-catalog__card-icon">📄</span>
            </div>
            <div class="reports-catalog__card-badges">
              <span
                class="reports-catalog__badge"
                :class="{
                  'reports-catalog__badge--embedded': report.source === 'embedded',
                  'reports-catalog__badge--external': report.source === 'external'
                }"
              >
                {{ report.source === 'embedded' ? 'Встроенный' : 'Внешний' }}
              </span>
            </div>
          </div>

          <div class="reports-catalog__card-body">
            <h3 class="reports-catalog__card-title">{{ report.name }}</h3>
            <p v-if="report.description" class="reports-catalog__card-description">
              {{ report.description }}
            </p>
            <div v-if="report.category" class="reports-catalog__card-category">
              {{ report.category }}
            </div>
          </div>

          <div v-if="report.tags && report.tags.length > 0" class="reports-catalog__card-footer">
            <div class="reports-catalog__tags">
              <span
                v-for="tag in report.tags"
                :key="tag"
                class="reports-catalog__tag"
              >
                {{ tag }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="reports-catalog__empty">
        <p>Отчёты не найдены. Измените фильтры или повторите загрузку.</p>
        <button type="button" @click="handleRefresh">Обновить</button>
      </div>
    </div>
  </section>

  <!-- Диалог параметров -->
  <ReportParametersDialog
    v-if="selectedReport"
    :report-id="selectedReport.id"
    :open="dialogOpen"
    @close="handleDialogClose"
    @generate="handleGenerate"
    @preview="handlePreview"
  />
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useReportsStore } from '@/stores/reports';
import type { ReportInfo } from '@/types/reports';
import ReportParametersDialog from '../components/ReportParametersDialog.vue';

const reportsStore = useReportsStore();

const loading = computed(() => reportsStore.loading);
const error = computed(() => reportsStore.error);
const reports = computed(() => reportsStore.reports);
const filteredReports = computed(() => reportsStore.filteredReports);
const categories = computed(() => reportsStore.categories);
const tags = computed(() => reportsStore.tags);
const filters = computed(() => reportsStore.filters);
const filteredTotal = computed(() => reportsStore.filteredTotal);
const hasData = computed(() => reportsStore.hasData);

const selectedReport = ref<ReportInfo | null>(null);
const dialogOpen = ref(false);

const headerMessage = computed(() => {
  if (loading.value) {
    return 'Загрузка каталога отчётов…';
  }
  if (error.value) {
    return 'Произошла ошибка при загрузке.';
  }
  if (!hasData.value) {
    return 'Отчёты отсутствуют. Попробуйте обновить список.';
  }
  return 'Выберите отчёт для генерации.';
});

function handleRefresh(): void {
  reportsStore.loadReports();
  reportsStore.loadCategories();
  reportsStore.loadTags();
}

function handleFilterChange(): void {
  // Фильтрация происходит автоматически через computed filteredReports
}

function handleReportClick(report: ReportInfo): void {
  selectedReport.value = report;
  dialogOpen.value = true;
}

function handleDialogClose(): void {
  dialogOpen.value = false;
  selectedReport.value = null;
}

async function handleGenerate(format: 'pdf' | 'excel' | 'html', parameters: Record<string, unknown>): Promise<void> {
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
    console.error('Failed to generate report:', err);
    // Ошибка уже в store.error
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
    // Освобождаем URL после небольшой задержки
    setTimeout(() => URL.revokeObjectURL(url), 100);
  } catch (err) {
    console.error('Failed to generate preview:', err);
    // Ошибка уже в store.error
  }
}

onMounted(() => {
  handleRefresh();
});
</script>

<style scoped>
.reports-catalog {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.reports-catalog__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.reports-catalog__subtitle {
  margin: 4px 0 0;
  color: rgba(28, 35, 51, 0.68);
}

.reports-catalog__meta {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-end;
  font-size: 14px;
  color: rgba(28, 35, 51, 0.64);
}

.reports-catalog__counter {
  font-weight: 600;
}

.reports-catalog__refresh {
  border-radius: 8px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  background: white;
  padding: 8px 16px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.15s ease;
}

.reports-catalog__refresh:hover:not(:disabled) {
  background: rgba(47, 122, 206, 0.08);
  border-color: rgba(47, 122, 206, 0.2);
}

.reports-catalog__refresh:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.reports-catalog__alert {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  border-radius: 14px;
  font-size: 14px;
}

.reports-catalog__alert--info {
  background: rgba(14, 165, 233, 0.1);
  border: 1px solid rgba(14, 165, 233, 0.2);
  color: #0369a1;
}

.reports-catalog__alert--error {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
  color: #b91c1c;
}

.reports-catalog__alert button {
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-weight: 600;
}

.reports-catalog__filters {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  padding: 16px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(28, 35, 51, 0.06);
}

.reports-catalog__filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 150px;
}

.reports-catalog__filter-group label {
  font-size: 12px;
  font-weight: 600;
  color: rgba(28, 35, 51, 0.64);
  text-transform: uppercase;
}

.reports-catalog__filter-group select,
.reports-catalog__filter-group input {
  padding: 8px 12px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  border-radius: 8px;
  font-size: 14px;
  background: white;
}

.reports-catalog__filter-group input {
  flex: 1;
  min-width: 200px;
}

.reports-catalog__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.reports-catalog__card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(28, 35, 51, 0.08);
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
}

.reports-catalog__card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(28, 35, 51, 0.12);
}

.reports-catalog__card-header {
  position: relative;
  height: 120px;
  background: linear-gradient(135deg, rgba(47, 122, 206, 0.1) 0%, rgba(47, 122, 206, 0.05) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.reports-catalog__card-thumbnail {
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.reports-catalog__card-thumbnail img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.reports-catalog__card-icon {
  font-size: 48px;
}

.reports-catalog__card-badges {
  position: absolute;
  top: 8px;
  right: 8px;
}

.reports-catalog__badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.reports-catalog__badge--embedded {
  background: rgba(34, 197, 94, 0.15);
  color: #16a34a;
}

.reports-catalog__badge--external {
  background: rgba(59, 130, 246, 0.15);
  color: #2563eb;
}

.reports-catalog__card-body {
  padding: 16px;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.reports-catalog__card-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1c2333;
}

.reports-catalog__card-description {
  margin: 0;
  font-size: 13px;
  color: rgba(28, 35, 51, 0.68);
  line-height: 1.5;
  flex: 1;
}

.reports-catalog__card-category {
  font-size: 12px;
  color: rgba(28, 35, 51, 0.56);
  font-weight: 500;
}

.reports-catalog__card-footer {
  padding: 12px 16px;
  border-top: 1px solid rgba(28, 35, 51, 0.08);
}

.reports-catalog__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.reports-catalog__tag {
  padding: 4px 8px;
  background: rgba(28, 35, 51, 0.06);
  border-radius: 6px;
  font-size: 11px;
  color: rgba(28, 35, 51, 0.72);
}

.reports-catalog__empty {
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: center;
  justify-content: center;
  padding: 48px;
  color: rgba(28, 35, 51, 0.6);
  text-align: center;
  background: white;
  border-radius: 16px;
}

.reports-catalog__empty button {
  border-radius: 8px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  background: white;
  padding: 10px 18px;
  cursor: pointer;
}

@media (max-width: 768px) {
  .reports-catalog__header {
    flex-direction: column;
    align-items: flex-start;
  }

  .reports-catalog__meta {
    align-items: flex-start;
  }

  .reports-catalog__grid {
    grid-template-columns: 1fr;
  }

  .reports-catalog__filters {
    flex-direction: column;
  }

  .reports-catalog__filter-group {
    min-width: 100%;
  }
}
</style>
