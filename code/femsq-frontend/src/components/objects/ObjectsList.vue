<template>
  <div class="objects-list">
    <div class="objects-list__header">
      <h3>Объекты</h3>
      <div class="objects-list__actions">
        <button
          v-if="selectedObjects.length > 0 && availableReports.length > 0"
          class="objects-list__reports-button"
          @click="toggleReportsMenu"
        >
          Отчёты для выбранных ({{ selectedObjects.length }})
          <span v-if="reportsMenuOpen">▼</span>
          <span v-else>▶</span>
        </button>
      </div>
    </div>

    <div v-if="reportsMenuOpen && availableReports.length > 0" class="objects-list__reports-menu">
      <button
        v-for="report in availableReports"
        :key="report.id"
        class="objects-list__report-item"
        @click="handleReportClick(report)"
      >
        {{ report.name }}
      </button>
    </div>

    <div class="objects-list__body">
      <div class="objects-list__table">
        <table>
          <thead>
            <tr>
              <th>
                <input
                  type="checkbox"
                  :checked="allSelected"
                  @change="toggleSelectAll"
                />
              </th>
              <th>ID</th>
              <th>Название</th>
              <th>Адрес</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="object in objects"
              :key="object.id"
              :class="{ 'objects-list__row--selected': isSelected(object.id) }"
            >
              <td>
                <input
                  type="checkbox"
                  :checked="isSelected(object.id)"
                  @change="toggleSelect(object.id)"
                />
              </td>
              <td>{{ object.id }}</td>
              <td>{{ object.name }}</td>
              <td>{{ object.address || '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Диалог параметров отчёта -->
    <ReportParametersDialog
      v-if="selectedReport"
      :report-id="selectedReport.id"
      :open="dialogOpen"
      :context="objectsContext"
      @close="handleDialogClose"
      @generate="handleGenerate"
      @preview="handlePreview"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useReportsStore } from '@/stores/reports';
import { filterReportsByComponent, resolveContextParameters } from '@/modules/reports/utils/context-resolver';
import ReportParametersDialog from '@/modules/reports/components/ReportParametersDialog.vue';

interface Object {
  id: string;
  name: string;
  address?: string;
  [key: string]: unknown;
}

interface Props {
  objects: Object[];
}

const props = defineProps<Props>();

const reportsStore = useReportsStore();

const selectedObjects = ref<string[]>([]);
const reportsMenuOpen = ref(false);
const availableReports = ref<Array<{ id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } }>>([]);
const selectedReport = ref<{ id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } } | null>(null);
const dialogOpen = ref(false);

const allSelected = computed(() => {
  return props.objects.length > 0 && selectedObjects.value.length === props.objects.length;
});

const objectsContext = computed(() => {
  // Передаём массив ID объектов в контекст
  return {
    objectIds: selectedObjects.value.join(','),
    objectCount: selectedObjects.value.length
  };
});

async function loadAvailableReports(): Promise<void> {
  await reportsStore.loadReports();
  const allReports = reportsStore.reports;
  const filtered = filterReportsByComponent(allReports, 'ObjectsList');
  availableReports.value = filtered;
}

function toggleReportsMenu(): void {
  reportsMenuOpen.value = !reportsMenuOpen.value;
  if (reportsMenuOpen.value && availableReports.value.length === 0) {
    loadAvailableReports();
  }
}

function isSelected(id: string): boolean {
  return selectedObjects.value.includes(id);
}

function toggleSelect(id: string): void {
  const index = selectedObjects.value.indexOf(id);
  if (index === -1) {
    selectedObjects.value.push(id);
  } else {
    selectedObjects.value.splice(index, 1);
  }
}

function toggleSelectAll(): void {
  if (allSelected.value) {
    selectedObjects.value = [];
  } else {
    selectedObjects.value = props.objects.map(obj => obj.id);
  }
}

async function handleReportClick(report: { id: string; name: string; contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> } }): Promise<void> {
  if (selectedObjects.value.length === 0) {
    return;
  }

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
    // Объединяем контекстные параметры с параметрами из диалога
    const contextParams = resolveContextParameters(selectedReport.value.contextMenu, objectsContext.value);
    const allParameters = { ...contextParams, ...parameters };

    // Добавляем массив ID объектов
    allParameters.objectIds = selectedObjects.value;

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
    const contextParams = resolveContextParameters(selectedReport.value.contextMenu, objectsContext.value);
    const allParameters = { ...contextParams, ...parameters };
    allParameters.objectIds = selectedObjects.value;

    const blob = await reportsStore.generatePreviewRequest(selectedReport.value.id, allParameters);
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
    setTimeout(() => URL.revokeObjectURL(url), 100);
  } catch (err) {
    console.error('Failed to generate preview:', err);
  }
}

onMounted(() => {
  loadAvailableReports();
});
</script>

<style scoped>
.objects-list {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(28, 35, 51, 0.08);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.objects-list__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.objects-list__header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.objects-list__actions {
  display: flex;
  gap: 8px;
}

.objects-list__reports-button {
  padding: 8px 16px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  border-radius: 8px;
  background: white;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.15s ease;
}

.objects-list__reports-button:hover {
  background: rgba(47, 122, 206, 0.08);
  border-color: rgba(47, 122, 206, 0.2);
}

.objects-list__reports-menu {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px;
  background: rgba(28, 35, 51, 0.04);
  border-radius: 8px;
}

.objects-list__report-item {
  padding: 8px 12px;
  border: none;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  font-size: 14px;
  transition: all 0.15s ease;
}

.objects-list__report-item:hover {
  background: rgba(47, 122, 206, 0.08);
}

.objects-list__body {
  display: flex;
  flex-direction: column;
}

.objects-list__table {
  overflow-x: auto;
}

.objects-list__table table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

.objects-list__table thead {
  background: rgba(28, 35, 51, 0.05);
}

.objects-list__table th,
.objects-list__table td {
  padding: 12px 16px;
  border-bottom: 1px solid rgba(28, 35, 51, 0.08);
  text-align: left;
}

.objects-list__table tbody tr {
  transition: background 0.15s ease;
}

.objects-list__table tbody tr:hover {
  background: rgba(47, 122, 206, 0.04);
}

.objects-list__row--selected {
  background: rgba(47, 122, 206, 0.08);
}

.objects-list__table input[type="checkbox"] {
  cursor: pointer;
}
</style>
