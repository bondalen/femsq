<template>
  <div v-if="contractor" class="contractor-reports-menu">
    <QBtn
      v-if="availableReports.length > 0"
      color="primary"
      outline
      icon="description"
      dense
      :disable="!contractorHasId"
      label="Отчёты"
      data-testid="contractor-reports-btn"
      @click="reportsMenuOpen = !reportsMenuOpen"
    />
    <QBtn
      v-else
      color="grey-5"
      outline
      dense
      disable
      label="Нет отчётов"
    />

    <QMenu v-model="reportsMenuOpen" anchor="bottom right" self="top right">
      <QList style="min-width: 240px">
        <QItem
          v-for="report in availableReports"
          :key="report.id"
          clickable
          v-close-popup
          data-testid="contractor-report-item"
          @click="() => handleReportSelection(report)"
        >
          <QItemSection avatar>
            <QIcon :name="report.contextMenu.icon || 'description'" />
          </QItemSection>
          <QItemSection>
            <div class="text-body2">{{ report.name }}</div>
            <div class="text-caption text-grey-7">{{ report.contextMenu.label }}</div>
          </QItemSection>
        </QItem>
        <QItem v-if="contractorReportsLoading" dense>
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
      :context="contractorContext"
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
import type { Organization } from '@/stores/organizations';
import { areAllRequiredParametersFilled, filterReportsByComponent, resolveContextParameters } from '@/modules/reports/utils/context-resolver';

interface Props {
  contractor: Organization | null;
}

const props = defineProps<Props>();

const reportsStore = useReportsStore();
const reportsMenuOpen = ref(false);
const contractorReportsLoading = ref(false);
const dialogOpen = ref(false);
const activeReport = ref<
  | {
      id: string;
      name: string;
      contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> };
    }
  | null
>(null);

const contractorContext = computed(() => {
  if (!props.contractor) {
    return {};
  }
  return {
    contractorId: String(props.contractor.ogKey),
    contractorName: props.contractor.ogName,
    contractorInn: props.contractor.inn ?? '',
    contractorDescription: props.contractor.ogDescription ?? ''
  };
});

const contractorHasId = computed(() => Boolean(props.contractor?.ogKey));

const availableReports = computed(() => {
  return filterReportsByComponent(reportsStore.reports, 'ContractorCard');
});

async function ensureReportsLoaded(): Promise<void> {
  if (reportsStore.reports.length > 0) {
    return;
  }
  contractorReportsLoading.value = true;
  try {
    await reportsStore.loadReports();
  } finally {
    contractorReportsLoading.value = false;
  }
}

async function handleReportSelection(
  report: {
    id: string;
    name: string;
    contextMenu: { component: string; label: string; icon?: string; parameterMapping: Record<string, string> };
  }
): Promise<void> {
  if (!contractorHasId.value) {
    return;
  }
  activeReport.value = report;

  const metadata = await reportsStore.loadMetadata(report.id);
  if (!metadata) {
    return;
  }

  const contextParameters = resolveContextParameters(report.contextMenu, contractorContext.value);
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
  const contextParams = resolveContextParameters(activeReport.value.contextMenu, contractorContext.value);
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
  const contextParams = resolveContextParameters(activeReport.value.contextMenu, contractorContext.value);
  const parameters = { ...contextParams, ...payload };
  const blob = await reportsStore.generatePreviewRequest(activeReport.value.id, parameters);
  const url = URL.createObjectURL(blob);
  window.open(url, '_blank');
  window.setTimeout(() => URL.revokeObjectURL(url), 100);
}

watch(
  () => props.contractor?.ogKey,
  () => {
    reportsMenuOpen.value = false;
    if (!props.contractor) {
      handleDialogClose();
    }
  }
);

onMounted(() => {
  void ensureReportsLoaded();
});

defineExpose({
  handleReportSelection
});
</script>

<style scoped>
.contractor-reports-menu {
  display: inline-flex;
  align-items: center;
}
</style>

