<template>
  <div class="contractor-card">
    <div class="contractor-card__header">
      <h3>{{ contractor.name }}</h3>
      <div class="contractor-card__actions">
        <button
          v-if="availableReports.length > 0"
          class="contractor-card__reports-button"
          @click="toggleReportsMenu"
        >
          Отчёты
          <span v-if="reportsMenuOpen">▼</span>
          <span v-else>▶</span>
        </button>
      </div>
    </div>

    <div v-if="reportsMenuOpen && availableReports.length > 0" class="contractor-card__reports-menu">
      <button
        v-for="report in availableReports"
        :key="report.id"
        class="contractor-card__report-item"
        @click="handleReportClick(report)"
      >
        {{ report.name }}
      </button>
    </div>

    <div class="contractor-card__body">
      <dl class="contractor-card__details">
        <div v-if="contractor.id">
          <dt>ID</dt>
          <dd>{{ contractor.id }}</dd>
        </div>
        <div v-if="contractor.inn">
          <dt>ИНН</dt>
          <dd>{{ contractor.inn }}</dd>
        </div>
        <div v-if="contractor.address">
          <dt>Адрес</dt>
          <dd>{{ contractor.address }}</dd>
        </div>
      </dl>
    </div>

    <!-- Диалог параметров отчёта -->
    <ReportParametersDialog
      v-if="selectedReport"
      :report-id="selectedReport.id"
      :open="dialogOpen"
      :context="contractorContext"
      @close="handleDialogClose"
      @generate="handleGenerate"
      @preview="handlePreview"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useReportsStore } from '@/stores/reports';
import { filterReportsByComponent, resolveContextParameters, areAllRequiredParametersFilled } from '@/modules/reports/utils/context-resolver';
import ReportParametersDialog from '@/modules/reports/components/ReportParametersDialog.vue';

interface Contractor {
  id: string;
  name: string;
  inn?: string;
  address?: string;
  [key: string]: unknown;
}

interface Props {
  contractor: Contractor;
}

const props = defineProps<Props>();

const reportsStore = useReportsStore();

const reportsMenuOpen = ref(false);
const availableReports = ref<Array<{ id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } }>>([]);
const selectedReport = ref<{ id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } } | null>(null);
const dialogOpen = ref(false);

const contractorContext = computed(() => ({
  contractorId: props.contractor.id,
  contractorName: props.contractor.name,
  contractorInn: props.contractor.inn || '',
  contractorAddress: props.contractor.address || ''
}));

async function loadAvailableReports(): Promise<void> {
  await reportsStore.loadReports();
  const allReports = reportsStore.reports;
  const filtered = filterReportsByComponent(allReports, 'ContractorCard');
  availableReports.value = filtered;
}

function toggleReportsMenu(): void {
  reportsMenuOpen.value = !reportsMenuOpen.value;
  if (reportsMenuOpen.value && availableReports.value.length === 0) {
    loadAvailableReports();
  }
}

async function handleReportClick(report: { id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } }): Promise<void> {
  selectedReport.value = report;

  // Загружаем метаданные отчёта
  const metadata = await reportsStore.loadMetadata(report.id);
  if (!metadata) {
    console.error('Failed to load report metadata');
    return;
  }

  // Разрешаем параметры из контекста
  const contextParameters = resolveContextParameters(report.contextMenu, contractorContext.value);

  // Проверяем, все ли обязательные параметры заполнены
  const allFilled = areAllRequiredParametersFilled(metadata, contextParameters);

  if (allFilled) {
    // Автоматически генерируем отчёт
    await handleGenerate('pdf', contextParameters);
  } else {
    // Показываем диалог для ввода дополнительных параметров
    dialogOpen.value = true;
  }
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
    // Объединяем контекстные параметры с параметрами из диалога
    const contextParams = resolveContextParameters(selectedReport.value.contextMenu, contractorContext.value);
    const allParameters = { ...contextParams, ...parameters };

    const blob = await reportsStore.generateReportRequest({
      reportId: selectedReport.value.id,
      parameters: allParameters,
      format
    });

    const fileName = `${selectedReport.value.id}_${new Date().toISOString().slice(0, 10)}.${format}`;
    reportsStore.downloadBlob(blob, fileName);
    handleDialogClose();
  } catch (err) {
    console.error('Failed to generate report:', err);
  }
}

async function handlePreview(parameters: Record<string, unknown>): Promise<void> {
  if (!selectedReport.value) {
    return;
  }

  try {
    const contextParams = resolveContextParameters(selectedReport.value.contextMenu, contractorContext.value);
    const allParameters = { ...contextParams, ...parameters };

    const blob = await reportsStore.generatePreviewRequest(selectedReport.value.id, allParameters);
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
    setTimeout(() => URL.revokeObjectURL(url), 100);
  } catch (err) {
    console.error('Failed to generate preview:', err);
  }
}

onMounted(() => {
  // Предзагружаем отчёты при монтировании компонента
  loadAvailableReports();
});
</script>

<style scoped>
.contractor-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(28, 35, 51, 0.08);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.contractor-card__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.contractor-card__header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.contractor-card__actions {
  display: flex;
  gap: 8px;
}

.contractor-card__reports-button {
  padding: 8px 16px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  border-radius: 8px;
  background: white;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.15s ease;
}

.contractor-card__reports-button:hover {
  background: rgba(47, 122, 206, 0.08);
  border-color: rgba(47, 122, 206, 0.2);
}

.contractor-card__reports-menu {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px;
  background: rgba(28, 35, 51, 0.04);
  border-radius: 8px;
}

.contractor-card__report-item {
  padding: 8px 12px;
  border: none;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  font-size: 14px;
  transition: all 0.15s ease;
}

.contractor-card__report-item:hover {
  background: rgba(47, 122, 206, 0.08);
}

.contractor-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.contractor-card__details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
}

.contractor-card__details dt {
  font-size: 12px;
  text-transform: uppercase;
  color: rgba(28, 35, 51, 0.48);
  font-weight: 600;
}

.contractor-card__details dd {
  margin: 0;
  font-size: 14px;
  color: rgba(28, 35, 51, 0.8);
}
</style>
