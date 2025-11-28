import { beforeEach, describe, expect, it, vi } from 'vitest';
import { createPinia, setActivePinia } from 'pinia';

import { useReportsStore } from '@/stores/reports';
import * as reportsApi from '@/api/reports-api';
import type { ReportInfo, ReportMetadata, ReportParameter } from '@/types/reports';

vi.mock('@/api/reports-api');

describe('useReportsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  const createStore = () => useReportsStore();

  describe('loadReports', () => {
    it('загружает отчёты и сохраняет в состоянии', async () => {
      const mockReports: ReportInfo[] = [
        { id: '1', name: 'Report 1', tags: ['a'], source: 'embedded' },
        { id: '2', name: 'Report 2', tags: ['b'], source: 'external' }
      ];
      vi.mocked(reportsApi.getAvailableReports).mockResolvedValue(mockReports);

      const store = createStore();
      await store.loadReports();

      expect(store.reports).toEqual(mockReports);
      expect(store.lastLoadedAt).toBeTruthy();
      expect(store.error).toBe('');
      expect(reportsApi.getAvailableReports).toHaveBeenCalledWith(undefined, undefined);
    });

    it('проставляет ошибки при неудачной загрузке', async () => {
      vi.mocked(reportsApi.getAvailableReports).mockRejectedValue({ message: 'fail' });

      const store = createStore();
      await store.loadReports();

      expect(store.reports).toEqual([]);
      expect(store.error).toBe('fail');
    });

    it('не отправляет запрос, если уже загружается', async () => {
      const store = createStore();
      store.loading = true;
      await store.loadReports();
      expect(reportsApi.getAvailableReports).not.toHaveBeenCalled();
    });
  });

  describe('loadMetadata', () => {
    const metadata: ReportMetadata = {
      id: '1',
      version: '1.0',
      name: 'Report',
      created: '2025-01-01',
      lastModified: '2025-01-02',
      files: { template: 'template.jrxml' }
    };

    it('кэширует метаданные', async () => {
      vi.mocked(reportsApi.getReportMetadata).mockResolvedValue(metadata);
      const store = createStore();

      await store.loadMetadata('1');
      await store.loadMetadata('1');

      expect(reportsApi.getReportMetadata).toHaveBeenCalledTimes(1);
    });

    it('возвращает null при ошибке и пишет сообщение', async () => {
      vi.mocked(reportsApi.getReportMetadata).mockRejectedValue({ message: 'nope' });
      const store = createStore();
      const result = await store.loadMetadata('missing');
      expect(result).toBeNull();
      expect(store.error).toBe('nope');
    });
  });

  describe('loadParameters', () => {
    const parameters: ReportParameter[] = [
      { name: 'param1', label: 'Param 1', type: 'string', required: true }
    ];

    it('кэширует параметры по reportId+context', async () => {
      vi.mocked(reportsApi.getReportParameters).mockResolvedValue(parameters);
      const store = createStore();
      await store.loadParameters('report-1', { contractorId: '123' });
      await store.loadParameters('report-1', { contractorId: '123' });
      expect(reportsApi.getReportParameters).toHaveBeenCalledTimes(1);
    });

    it('возвращает пустой массив при ошибке', async () => {
      vi.mocked(reportsApi.getReportParameters).mockRejectedValue({ message: 'fail' });
      const store = createStore();
      const result = await store.loadParameters('report-1');
      expect(result).toEqual([]);
      expect(store.error).toBe('fail');
    });
  });

  describe('filters', () => {
    it('фильтрует отчёты по категории, тегу и поиску', () => {
      const store = createStore();
      store.reports = [
        { id: '1', name: 'Finance', category: 'finance', tags: ['a'], source: 'embedded' },
        { id: '2', name: 'Analytics', category: 'analytics', tags: ['b'], source: 'embedded' }
      ];
      store.filters.category = 'finance';
      store.filters.tag = 'a';
      store.filters.search = 'fin';
      expect(store.filteredReports).toHaveLength(1);
      expect(store.filteredReports[0].id).toBe('1');
    });
  });

  describe('generation', () => {
    it('generateReportRequest прокидывает ошибки в state', async () => {
      vi.mocked(reportsApi.generateReport).mockRejectedValue({ message: 'fail' });
      const store = createStore();
      await expect(
        store.generateReportRequest({
          reportId: '1',
          parameters: {},
          format: 'pdf'
        })
      ).rejects.toThrow();
      expect(store.error).toBe('fail');
    });

    it('generatePreviewRequest прокидывает ошибки в state', async () => {
      vi.mocked(reportsApi.generatePreview).mockRejectedValue({ message: 'fail' });
      const store = createStore();
      await expect(store.generatePreviewRequest('1')).rejects.toThrow();
      expect(store.error).toBe('fail');
    });
  });

  describe('loadCategories / loadTags', () => {
    it('загружает категории', async () => {
      vi.mocked(reportsApi.getCategories).mockResolvedValue(['a', 'b']);
      const store = createStore();
      await store.loadCategories();
      expect(store.categories).toEqual(['a', 'b']);
    });

    it('загружает теги', async () => {
      vi.mocked(reportsApi.getTags).mockResolvedValue(['tag']);
      const store = createStore();
      await store.loadTags();
      expect(store.tags).toEqual(['tag']);
    });
  });

  describe('reset', () => {
    it('сбрасывает состояние', () => {
      const store = createStore();
      store.reports = [{ id: '1', name: 'A', tags: [], source: 'embedded' }];
      store.filters.category = 'finance';
      store.error = 'fail';
      store.reset();
      expect(store.reports).toEqual([]);
      expect(store.filters.category).toBe('');
      expect(store.error).toBe('');
    });
  });
});






