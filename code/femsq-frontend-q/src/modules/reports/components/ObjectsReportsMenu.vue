<template>
  <div class="objects-reports-menu">
    <QBtn
      color="primary"
      outline
      dense
      icon="assignment"
      :disable="!canGenerate"
      :label="buttonLabel"
      data-testid="objects-reports-btn"
      @click="reportsMenuOpen = !reportsMenuOpen"
    />
    <QMenu v-model="reportsMenuOpen" anchor="bottom right" self="top right">
      <QList style="min-width: 240px">
        <QItem
          v-for="report in availableReports"
          :key="report.id"
          clickable
          v-close-popup
          data-testid="objects-report-item"
          @click="() => handleReportSelection(report)"
        >
          <QItemSection avatar>
            <QIcon :name="report.contextMenu.icon || 'list'" />
          </QItemSection>
          <QItemSection>
            <div class="text-body2">{{ report.name }}</div>
            <div class="text-caption text-grey-7">{{ report.contextMenu.label }}</div>
          </QItemSection>
        </QItem>
        <QItem v-if="objectsReportsLoading" dense>
          <QItemSection avatar>
            <QSpinner color="primary" size="16px" />
          </QItemSection>
          <QItemSection>Загрузка отчётов…</QItemSection>
        </QItem>
      </QList>
    </QMenu>

    <ReportParametersDialog
      v-if="activeReport"
      :open="dialogOpen"
      :report-id="activeReport.id"
      :context="objectsContext"
      @close="handleDialogClose"
      @generate="handleGenerate"
      @preview="handlePreview"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import {
  QBtn,
  QList,
  QItem,
  QItemSection,
  QIcon,
  QMenu,
  QSpinner
} from 'quasar';

import ReportParametersDialog from '@/modules/reports/components/ReportParametersDialog.vue';
import { useReportsStore } from '@/stores/reports';
import { areAllRequiredParametersFilled, filterReportsByComponent, resolveContextParameters } from '@/modules/reports/utils/context-resolver';

interface ObjectsItem {
  objectId?: string | number | null;
  label?: string | null;
}

interface Props {
  items: ObjectsItem[];
}

const props = defineProps<Props>();

const reportsStore = useReportsStore();
const reportsMenuOpen = ref(false);
const objectsReportsLoading = ref(false);
const dialogOpen = ref(false);
const activeReport = ref<
  | {
      id: string;
      name: string;
      contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> };
    }
  | null
>(null);

const availableReports = computed(() => filterReportsByComponent(reportsStore.reports, 'ObjectsList'));
const selectedObjectIds = computed(() =>
  props.items
    .map((item) => (item.objectId === null || item.objectId === undefined ? null : String(item.objectId)))
    .filter((value): value is string => Boolean(value))
);

const objectsContext = computed(() => ({
  objectIds: selectedObjectIds.value.join(',')
}));

const canGenerate = computed(
  () => selectedObjectIds.value.length > 0 && availableReports.value.length > 0
);

const buttonLabel = computed(() => {
  const count = selectedObjectIds.value.length;
  return count > 0 ? `Отчёты (${count})` : 'Отчёты';
});

async function ensureReportsLoaded(): Promise<void> {
  if (reportsStore.reports.length > 0) {
    return;
  }
  objectsReportsLoading.value = true;
  try {
    await reportsStore.loadReports();
  } finally {
    objectsReportsLoading.value = false;
  }
}

async function handleReportSelection(
  report: {
    id: string;
    name: string;
    contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> };
  }
): Promise<void> {
  if (!canGenerate.value) {
    return;
  }
  activeReport.value = report;
  const metadata = await reportsStore.loadMetadata(report.id);
  if (!metadata) {
    return;
  }

  const contextParameters = resolveContextParameters(report.contextMenu, objectsContext.value);
  const filled = areAllRequiredParametersFilled(metadata, contextParameters);

  if (filled) {
    await handleGenerate('pdf', {});
  } else {
    dialogOpen.value = true;
  }
}

function handleDialogClose(): void {
  dialogOpen.value = false;
  activeReport.value = null;
}

async function handleGenerate(format: 'pdf' | 'excel' | 'html', payload: Record<string, unknown>): Promise<void> {
  if (!activeReport.value) {
    return;
  }
  const contextParams = resolveContextParameters(activeReport.value.contextMenu, objectsContext.value);
  const parameters = { ...contextParams, ...payload };
  const blob = await reportsStore.generateReportRequest({
    reportId: activeReport.value.id,
    parameters,
    format
  });
  const fileName = `${activeReport.value.id}_${new Date().toISOString().slice(0, 10)}.${format}`;
  reportsStore.downloadBlob(blob, fileName);
  handleDialogClose();
}

async function handlePreview(payload: Record<string, unknown>): Promise<void> {
  if (!activeReport.value) {
    return;
  }
  const contextParams = resolveContextParameters(activeReport.value.contextMenu, objectsContext.value);
  const parameters = { ...contextParams, ...payload };
  const blob = await reportsStore.generatePreviewRequest(activeReport.value.id, parameters);
  const url = URL.createObjectURL(blob);
  window.open(url, '_blank');
  window.setTimeout(() => URL.revokeObjectURL(url), 100);
}

watch(
  () => props.items,
  () => {
    if (selectedObjectIds.value.length === 0) {
      reportsMenuOpen.value = false;
      handleDialogClose();
    }
  },
  { deep: true }
);

onMounted(() => {
  void ensureReportsLoaded();
});

defineExpose({
  handleReportSelection
});
</script>

<style scoped>
.objects-reports-menu {
  display: inline-flex;
  align-items: center;
}
</style>

