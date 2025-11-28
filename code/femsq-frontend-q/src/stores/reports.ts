import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  generatePreview,
  generateReport,
  getAvailableReports,
  getCategories,
  getParameterSource,
  getReportMetadata,
  getReportParameters,
  getTags,
  type ApiError
} from '@/api/reports-api';
import type {
  ReportGenerationRequest,
  ReportInfo,
  ReportMetadata,
  ReportParameter
} from '@/types/reports';

export const useReportsStore = defineStore('reports', () => {
  const loading = ref(false);
  const error = ref('');
  const reports = ref<ReportInfo[]>([]);
  const categories = ref<string[]>([]);
  const tags = ref<string[]>([]);
  const lastLoadedAt = ref('');

  const metadataCache = reactive<Record<string, ReportMetadata>>({});
  const parametersCache = reactive<Record<string, ReportParameter[]>>({});

  const filters = reactive({
    category: '',
    tag: '',
    search: ''
  });

  const filteredReports = computed(() => {
    let result = reports.value;

    if (filters.category) {
      result = result.filter((report) => report.category === filters.category);
    }

    if (filters.tag) {
      result = result.filter((report) => report.tags?.includes(filters.tag));
    }

    if (filters.search) {
      const q = filters.search.toLowerCase();
      result = result.filter((report) => {
        const matchesName = report.name.toLowerCase().includes(q);
        const matchesDescription = report.description?.toLowerCase().includes(q);
        return matchesName || Boolean(matchesDescription);
      });
    }

    return result;
  });

  const total = computed(() => reports.value.length);
  const filteredTotal = computed(() => filteredReports.value.length);
  const hasData = computed(() => reports.value.length > 0);

  async function loadReports(): Promise<void> {
    if (loading.value) {
      return;
    }

    loading.value = true;
    error.value = '';

    try {
      const data = await getAvailableReports(
        filters.category || undefined,
        filters.tag || undefined
      );
      reports.value = data;
      lastLoadedAt.value = new Date().toISOString();
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось загрузить список отчётов';
      reports.value = [];
    } finally {
      loading.value = false;
    }
  }

  async function loadMetadata(reportId: string): Promise<ReportMetadata | null> {
    if (metadataCache[reportId]) {
      return metadataCache[reportId];
    }

    try {
      const metadata = await getReportMetadata(reportId);
      metadataCache[reportId] = metadata;
      return metadata;
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || `Не удалось загрузить метаданные отчёта: ${reportId}`;
      return null;
    }
  }

  async function loadParameters(
    reportId: string,
    context?: Record<string, string>
  ): Promise<ReportParameter[]> {
    const cacheKey = `${reportId}:${JSON.stringify(context ?? {})}`;

    if (parametersCache[cacheKey]) {
      return parametersCache[cacheKey];
    }

    try {
      const parameters = await getReportParameters(reportId, context);
      parametersCache[cacheKey] = parameters;
      return parameters;
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || `Не удалось загрузить параметры отчёта: ${reportId}`;
      return [];
    }
  }

  async function loadCategories(): Promise<void> {
    try {
      categories.value = await getCategories();
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось загрузить категории';
      categories.value = [];
    }
  }

  async function loadTags(): Promise<void> {
    try {
      tags.value = await getTags();
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось загрузить теги';
      tags.value = [];
    }
  }

  async function generateReportRequest(request: ReportGenerationRequest): Promise<Blob> {
    try {
      error.value = '';
      return await generateReport(request);
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось сгенерировать отчёт';
      throw err;
    }
  }

  async function generatePreviewRequest(
    reportId: string,
    parameters?: Record<string, unknown>
  ): Promise<Blob> {
    try {
      error.value = '';
      return await generatePreview(reportId, parameters);
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось сгенерировать предпросмотр';
      throw err;
    }
  }

  async function loadParameterSourceOptions(
    reportId: string,
    parameterName: string
  ): Promise<Array<{ value: string | number; label: string }>> {
    try {
      return await getParameterSource(reportId, parameterName);
    } catch (err) {
      const apiError = err as ApiError;
      error.value =
        apiError.message || `Не удалось загрузить опции параметра ${parameterName}`;
      return [];
    }
  }

  function downloadBlob(blob: Blob, fileName: string): void {
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  }

  function clearMetadataCache(): void {
    Object.keys(metadataCache).forEach((key) => {
      delete metadataCache[key];
    });
  }

  function clearParametersCache(): void {
    Object.keys(parametersCache).forEach((key) => {
      delete parametersCache[key];
    });
  }

  function reset(): void {
    loading.value = false;
    error.value = '';
    reports.value = [];
    categories.value = [];
    tags.value = [];
    filters.category = '';
    filters.tag = '';
    filters.search = '';
    lastLoadedAt.value = '';
    clearMetadataCache();
    clearParametersCache();
  }

  return {
    loading,
    error,
    reports,
    categories,
    tags,
    filters,
    lastLoadedAt,
    filteredReports,
    total,
    filteredTotal,
    hasData,
    loadReports,
    loadMetadata,
    loadParameters,
    loadCategories,
    loadTags,
    generateReportRequest,
    generatePreviewRequest,
    loadParameterSourceOptions,
    downloadBlob,
    clearMetadataCache,
    clearParametersCache,
    reset
  };
});






