/**
 * Pinia store для управления состоянием отчётов.
 */

import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';
import type {
  ReportInfo,
  ReportMetadata,
  ReportParameter,
  ReportGenerationRequest
} from '../types/reports';
import {
  getAvailableReports,
  getReportMetadata,
  getReportParameters,
  generateReport,
  generatePreview,
  getCategories,
  getTags,
  type ApiError
} from '../api/reports-api';

/**
 * Управляет состоянием отчётов: загрузка, фильтрация, генерация.
 */
export const useReportsStore = defineStore('reports', () => {
  // State
  const loading = ref(false);
  const error = ref<string>('');
  const reports = ref<ReportInfo[]>([]);
  const categories = ref<string[]>([]);
  const tags = ref<string[]>([]);
  
  // Кэш метаданных отчётов
  const metadataCache = reactive<Record<string, ReportMetadata>>({});
  
  // Кэш параметров отчётов
  const parametersCache = reactive<Record<string, ReportParameter[]>>({});
  
  // Фильтры
  const filters = reactive({
    category: '',
    tag: '',
    search: ''
  });
  
  const lastLoadedAt = ref<string>('');

  // Getters
  const filteredReports = computed(() => {
    let result = reports.value;
    
    // Фильтр по категории
    if (filters.category) {
      result = result.filter(r => r.category === filters.category);
    }
    
    // Фильтр по тегу
    if (filters.tag) {
      result = result.filter(r => r.tags?.includes(filters.tag));
    }
    
    // Поиск по имени и описанию
    if (filters.search) {
      const searchLower = filters.search.toLowerCase();
      result = result.filter(r => 
        r.name.toLowerCase().includes(searchLower) ||
        r.description?.toLowerCase().includes(searchLower)
      );
    }
    
    return result;
  });

  const total = computed(() => reports.value.length);
  const filteredTotal = computed(() => filteredReports.value.length);
  const hasData = computed(() => reports.value.length > 0);

  // Actions

  /**
   * Загружает список доступных отчётов.
   */
  async function loadReports(): Promise<void> {
    if (loading.value) {
      return;
    }
    
    loading.value = true;
    error.value = '';
    
    try {
      const category = filters.category || undefined;
      const tag = filters.tag || undefined;
      
      const data = await getAvailableReports(category, tag);
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

  /**
   * Загружает метаданные отчёта (с кэшированием).
   */
  async function loadMetadata(reportId: string): Promise<ReportMetadata | null> {
    // Проверяем кэш
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

  /**
   * Загружает параметры отчёта с разрешёнными значениями по умолчанию.
   */
  async function loadParameters(
    reportId: string,
    context?: Record<string, string>
  ): Promise<ReportParameter[]> {
    const cacheKey = `${reportId}:${JSON.stringify(context || {})}`;
    
    // Проверяем кэш
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

  /**
   * Генерирует отчёт.
   */
  async function generateReportRequest(
    request: ReportGenerationRequest
  ): Promise<Blob> {
    try {
      error.value = '';
      const blob = await generateReport(request);
      return blob;
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось сгенерировать отчёт';
      throw err;
    }
  }

  /**
   * Генерирует предпросмотр отчёта.
   */
  async function generatePreviewRequest(
    reportId: string,
    parameters?: Record<string, unknown>
  ): Promise<Blob> {
    try {
      error.value = '';
      const blob = await generatePreview(reportId, parameters);
      return blob;
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось сгенерировать предпросмотр';
      throw err;
    }
  }

  /**
   * Загружает список категорий.
   */
  async function loadCategories(): Promise<void> {
    try {
      categories.value = await getCategories();
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось загрузить категории';
      categories.value = [];
    }
  }

  /**
   * Загружает список тегов.
   */
  async function loadTags(): Promise<void> {
    try {
      tags.value = await getTags();
    } catch (err) {
      const apiError = err as ApiError;
      error.value = apiError.message || 'Не удалось загрузить теги';
      tags.value = [];
    }
  }

  /**
   * Скачивает blob как файл.
   */
  function downloadBlob(blob: Blob, fileName: string): void {
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  /**
   * Очищает кэш метаданных.
   */
  function clearMetadataCache(): void {
    Object.keys(metadataCache).forEach(key => {
      delete metadataCache[key];
    });
  }

  /**
   * Очищает кэш параметров.
   */
  function clearParametersCache(): void {
    Object.keys(parametersCache).forEach(key => {
      delete parametersCache[key];
    });
  }

  /**
   * Сбрасывает состояние store.
   */
  function reset(): void {
    loading.value = false;
    error.value = '';
    reports.value = [];
    categories.value = [];
    tags.value = [];
    clearMetadataCache();
    clearParametersCache();
    filters.category = '';
    filters.tag = '';
    filters.search = '';
    lastLoadedAt.value = '';
  }

  return {
    // State
    loading,
    error,
    reports,
    categories,
    tags,
    filters,
    lastLoadedAt,
    
    // Getters
    filteredReports,
    total,
    filteredTotal,
    hasData,
    
    // Actions
    loadReports,
    loadMetadata,
    loadParameters,
    generateReportRequest,
    generatePreviewRequest,
    loadCategories,
    loadTags,
    downloadBlob,
    clearMetadataCache,
    clearParametersCache,
    reset
  };
});
