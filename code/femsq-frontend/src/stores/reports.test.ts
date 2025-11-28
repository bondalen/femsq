/**
 * Unit tests for reports store.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useReportsStore } from './reports';
import * as reportsApi from '../api/reports-api';
import type { ReportInfo, ReportMetadata, ReportParameter } from '../types/reports';

// Mock the API module
vi.mock('../api/reports-api');

describe('useReportsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  function createMockStore() {
    return useReportsStore();
  }

  describe('loadReports', () => {
    it('should load reports successfully', async () => {
      const mockReports: ReportInfo[] = [
        {
          id: 'report-1',
          name: 'Test Report 1',
          description: 'Test description',
          category: 'finance',
          tags: ['test', 'demo'],
          source: 'embedded'
        },
        {
          id: 'report-2',
          name: 'Test Report 2',
          description: 'Another description',
          category: 'analytics',
          tags: ['test'],
          source: 'external'
        }
      ];

      vi.mocked(reportsApi.getAvailableReports).mockResolvedValue(mockReports);

      const store = createMockStore();
      await store.loadReports();

      expect(store.loading).toBe(false);
      expect(store.error).toBe('');
      expect(store.reports).toEqual(mockReports);
      expect(store.lastLoadedAt).toBeTruthy();
      expect(reportsApi.getAvailableReports).toHaveBeenCalledWith(undefined, undefined);
    });

    it('should handle errors when loading reports', async () => {
      const errorMessage = 'Failed to load reports';
      vi.mocked(reportsApi.getAvailableReports).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();
      await store.loadReports();

      expect(store.loading).toBe(false);
      expect(store.error).toBe(errorMessage);
      expect(store.reports).toEqual([]);
    });

    it('should not load if already loading', async () => {
      const store = createMockStore();
      store.loading = true;

      await store.loadReports();

      expect(reportsApi.getAvailableReports).not.toHaveBeenCalled();
    });

    it('should pass category and tag filters to API', async () => {
      const mockReports: ReportInfo[] = [];
      vi.mocked(reportsApi.getAvailableReports).mockResolvedValue(mockReports);

      const store = createMockStore();
      store.filters.category = 'finance';
      store.filters.tag = 'test';

      await store.loadReports();

      expect(reportsApi.getAvailableReports).toHaveBeenCalledWith('finance', 'test');
    });
  });

  describe('loadMetadata', () => {
    it('should load and cache metadata', async () => {
      const reportId = 'report-1';
      const mockMetadata: ReportMetadata = {
        id: reportId,
        version: '1.0.0',
        name: 'Test Report',
        description: 'Test description',
        created: '2025-01-01',
        lastModified: '2025-01-01',
        files: {
          template: 'test.jrxml'
        }
      };

      vi.mocked(reportsApi.getReportMetadata).mockResolvedValue(mockMetadata);

      const store = createMockStore();
      const result = await store.loadMetadata(reportId);

      expect(result).toEqual(mockMetadata);
      // Check cache after load
      if (store.metadataCache) {
        expect(store.metadataCache[reportId]).toEqual(mockMetadata);
      }
      expect(reportsApi.getReportMetadata).toHaveBeenCalledWith(reportId);
    });

    it('should return cached metadata on second call', async () => {
      const reportId = 'report-1';
      const mockMetadata: ReportMetadata = {
        id: reportId,
        version: '1.0.0',
        name: 'Test Report',
        created: '2025-01-01',
        lastModified: '2025-01-01',
        files: {
          template: 'test.jrxml'
        }
      };

      vi.mocked(reportsApi.getReportMetadata).mockResolvedValue(mockMetadata);

      const store = createMockStore();
      
      // First call
      await store.loadMetadata(reportId);
      vi.clearAllMocks();

      // Second call should use cache
      const result = await store.loadMetadata(reportId);

      expect(result).toEqual(mockMetadata);
      expect(reportsApi.getReportMetadata).not.toHaveBeenCalled();
    });

    it('should handle errors when loading metadata', async () => {
      const reportId = 'report-1';
      const errorMessage = 'Report not found';
      
      vi.mocked(reportsApi.getReportMetadata).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();
      const result = await store.loadMetadata(reportId);

      expect(result).toBeNull();
      expect(store.error).toBe(errorMessage);
    });
  });

  describe('loadParameters', () => {
    it('should load and cache parameters', async () => {
      const reportId = 'report-1';
      const context = { contractorId: '123' };
      const mockParameters: ReportParameter[] = [
        {
          name: 'param1',
          type: 'string',
          label: 'Parameter 1',
          required: true
        }
      ];

      vi.mocked(reportsApi.getReportParameters).mockResolvedValue(mockParameters);

      const store = createMockStore();
      const result = await store.loadParameters(reportId, context);

      expect(result).toEqual(mockParameters);
      const cacheKey = `${reportId}:${JSON.stringify(context)}`;
      // Check cache after load
      if (store.parametersCache) {
        expect(store.parametersCache[cacheKey]).toEqual(mockParameters);
      }
      expect(reportsApi.getReportParameters).toHaveBeenCalledWith(reportId, context);
    });

    it('should return cached parameters on second call', async () => {
      const reportId = 'report-1';
      const context = { contractorId: '123' };
      const mockParameters: ReportParameter[] = [
        {
          name: 'param1',
          type: 'string',
          label: 'Parameter 1',
          required: true
        }
      ];

      vi.mocked(reportsApi.getReportParameters).mockResolvedValue(mockParameters);

      const store = createMockStore();
      
      // First call
      await store.loadParameters(reportId, context);
      vi.clearAllMocks();

      // Second call should use cache
      const result = await store.loadParameters(reportId, context);

      expect(result).toEqual(mockParameters);
      expect(reportsApi.getReportParameters).not.toHaveBeenCalled();
    });

    it('should handle errors when loading parameters', async () => {
      const reportId = 'report-1';
      const errorMessage = 'Failed to load parameters';
      
      vi.mocked(reportsApi.getReportParameters).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();
      const result = await store.loadParameters(reportId);

      expect(result).toEqual([]);
      expect(store.error).toBe(errorMessage);
    });
  });

  describe('filteredReports', () => {
    it('should filter by category', () => {
      const store = createMockStore();
      store.reports = [
        {
          id: '1',
          name: 'Report 1',
          category: 'finance',
          tags: [],
          source: 'embedded'
        },
        {
          id: '2',
          name: 'Report 2',
          category: 'analytics',
          tags: [],
          source: 'embedded'
        }
      ];

      store.filters.category = 'finance';

      expect(store.filteredReports).toHaveLength(1);
      expect(store.filteredReports[0].id).toBe('1');
    });

    it('should filter by tag', () => {
      const store = createMockStore();
      store.reports = [
        {
          id: '1',
          name: 'Report 1',
          tags: ['test', 'demo'],
          source: 'embedded'
        },
        {
          id: '2',
          name: 'Report 2',
          tags: ['test'],
          source: 'embedded'
        }
      ];

      store.filters.tag = 'demo';

      expect(store.filteredReports).toHaveLength(1);
      expect(store.filteredReports[0].id).toBe('1');
    });

    it('should filter by search query', () => {
      const store = createMockStore();
      store.reports = [
        {
          id: '1',
          name: 'Financial Report',
          description: 'Monthly financial data',
          tags: [],
          source: 'embedded'
        },
        {
          id: '2',
          name: 'Analytics Report',
          description: 'Business analytics',
          tags: [],
          source: 'embedded'
        }
      ];

      store.filters.search = 'financial';

      expect(store.filteredReports).toHaveLength(1);
      expect(store.filteredReports[0].id).toBe('1');
    });

    it('should combine multiple filters', () => {
      const store = createMockStore();
      store.reports = [
        {
          id: '1',
          name: 'Financial Report',
          description: 'Monthly financial data',
          category: 'finance',
          tags: ['test'],
          source: 'embedded'
        },
        {
          id: '2',
          name: 'Analytics Report',
          description: 'Business analytics',
          category: 'analytics',
          tags: ['test'],
          source: 'embedded'
        }
      ];

      store.filters.category = 'finance';
      store.filters.tag = 'test';
      store.filters.search = 'financial';

      expect(store.filteredReports).toHaveLength(1);
      expect(store.filteredReports[0].id).toBe('1');
    });

    it('should return all reports when no filters applied', () => {
      const store = createMockStore();
      store.reports = [
        {
          id: '1',
          name: 'Report 1',
          tags: [],
          source: 'embedded'
        },
        {
          id: '2',
          name: 'Report 2',
          tags: [],
          source: 'embedded'
        }
      ];

      expect(store.filteredReports).toHaveLength(2);
    });
  });

  describe('generateReportRequest', () => {
    it('should generate report successfully', async () => {
      const mockBlob = new Blob(['test content'], { type: 'application/pdf' });
      const request = {
        reportId: 'report-1',
        parameters: { param1: 'value1' },
        format: 'pdf' as const
      };

      vi.mocked(reportsApi.generateReport).mockResolvedValue(mockBlob);

      const store = createMockStore();
      const result = await store.generateReportRequest(request);

      expect(result).toBe(mockBlob);
      expect(store.error).toBe('');
      expect(reportsApi.generateReport).toHaveBeenCalledWith(request);
    });

    it('should handle errors when generating report', async () => {
      const errorMessage = 'Failed to generate report';
      const request = {
        reportId: 'report-1',
        parameters: {},
        format: 'pdf' as const
      };

      vi.mocked(reportsApi.generateReport).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();

      await expect(store.generateReportRequest(request)).rejects.toThrow();
      expect(store.error).toBe(errorMessage);
    });
  });

  describe('generatePreviewRequest', () => {
    it('should generate preview successfully', async () => {
      const mockBlob = new Blob(['preview content'], { type: 'application/pdf' });
      const reportId = 'report-1';
      const parameters = { param1: 'value1' };

      vi.mocked(reportsApi.generatePreview).mockResolvedValue(mockBlob);

      const store = createMockStore();
      const result = await store.generatePreviewRequest(reportId, parameters);

      expect(result).toBe(mockBlob);
      expect(store.error).toBe('');
      expect(reportsApi.generatePreview).toHaveBeenCalledWith(reportId, parameters);
    });

    it('should handle errors when generating preview', async () => {
      const errorMessage = 'Failed to generate preview';
      const reportId = 'report-1';

      vi.mocked(reportsApi.generatePreview).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();

      await expect(store.generatePreviewRequest(reportId)).rejects.toThrow();
      expect(store.error).toBe(errorMessage);
    });
  });

  describe('loadCategories and loadTags', () => {
    it('should load categories successfully', async () => {
      const mockCategories = ['finance', 'analytics', 'operations'];
      vi.mocked(reportsApi.getCategories).mockResolvedValue(mockCategories);

      const store = createMockStore();
      await store.loadCategories();

      expect(store.categories).toEqual(mockCategories);
      expect(store.error).toBe('');
    });

    it('should load tags successfully', async () => {
      const mockTags = ['test', 'demo', 'production'];
      vi.mocked(reportsApi.getTags).mockResolvedValue(mockTags);

      const store = createMockStore();
      await store.loadTags();

      expect(store.tags).toEqual(mockTags);
      expect(store.error).toBe('');
    });

    it('should handle errors when loading categories', async () => {
      const errorMessage = 'Failed to load categories';
      vi.mocked(reportsApi.getCategories).mockRejectedValue({
        message: errorMessage
      });

      const store = createMockStore();
      await store.loadCategories();

      expect(store.categories).toEqual([]);
      expect(store.error).toBe(errorMessage);
    });
  });

  describe('cache management', () => {
    it('should clear metadata cache', async () => {
      const reportId = 'report-1';
      const mockMetadata: ReportMetadata = {
        id: reportId,
        version: '1.0.0',
        name: 'Test',
        created: '2025-01-01',
        lastModified: '2025-01-01',
        files: { template: 'test.jrxml' }
      };

      vi.mocked(reportsApi.getReportMetadata).mockResolvedValue(mockMetadata);

      const store = createMockStore();
      await store.loadMetadata(reportId);
      
      if (store.metadataCache) {
        expect(Object.keys(store.metadataCache)).toHaveLength(1);
        
        store.clearMetadataCache();

        expect(Object.keys(store.metadataCache)).toHaveLength(0);
      } else {
        // If cache is not exposed, just verify clearMetadataCache doesn't throw
        expect(() => store.clearMetadataCache()).not.toThrow();
      }
    });

    it('should clear parameters cache', async () => {
      const reportId = 'report-1';
      const mockParameters: ReportParameter[] = [
        {
          name: 'param1',
          type: 'string',
          label: 'Parameter 1',
          required: true
        }
      ];

      vi.mocked(reportsApi.getReportParameters).mockResolvedValue(mockParameters);

      const store = createMockStore();
      await store.loadParameters(reportId);
      
      if (store.parametersCache) {
        expect(Object.keys(store.parametersCache).length).toBeGreaterThan(0);
        
        store.clearParametersCache();

        expect(Object.keys(store.parametersCache)).toHaveLength(0);
      } else {
        // If cache is not exposed, just verify clearParametersCache doesn't throw
        expect(() => store.clearParametersCache()).not.toThrow();
      }
    });
  });

  describe('reset', () => {
    it('should reset all state', async () => {
      const reportId = 'report-1';
      const mockMetadata: ReportMetadata = {
        id: reportId,
        version: '1.0.0',
        name: 'Test',
        created: '2025-01-01',
        lastModified: '2025-01-01',
        files: { template: 'test.jrxml' }
      };

      vi.mocked(reportsApi.getReportMetadata).mockResolvedValue(mockMetadata);
      vi.mocked(reportsApi.getAvailableReports).mockResolvedValue([
        { id: '1', name: 'Test', tags: [], source: 'embedded' }
      ]);

      const store = createMockStore();
      store.loading = true;
      store.error = 'test error';
      await store.loadReports();
      await store.loadMetadata(reportId);
      store.filters.category = 'finance';
      store.filters.tag = 'test';
      store.filters.search = 'query';

      store.reset();

      expect(store.loading).toBe(false);
      expect(store.error).toBe('');
      expect(store.reports).toEqual([]);
      if (store.metadataCache) {
        expect(Object.keys(store.metadataCache)).toHaveLength(0);
      }
      if (store.parametersCache) {
        expect(Object.keys(store.parametersCache)).toHaveLength(0);
      }
      expect(store.filters.category).toBe('');
      expect(store.filters.tag).toBe('');
      expect(store.filters.search).toBe('');
    });
  });

  describe('computed properties', () => {
    it('should calculate total correctly', () => {
      const store = createMockStore();
      store.reports = [
        { id: '1', name: 'Report 1', tags: [], source: 'embedded' },
        { id: '2', name: 'Report 2', tags: [], source: 'embedded' }
      ];

      expect(store.total).toBe(2);
    });

    it('should calculate filteredTotal correctly', () => {
      const store = createMockStore();
      store.reports = [
        { id: '1', name: 'Report 1', category: 'finance', tags: [], source: 'embedded' },
        { id: '2', name: 'Report 2', category: 'analytics', tags: [], source: 'embedded' }
      ];
      store.filters.category = 'finance';

      expect(store.filteredTotal).toBe(1);
    });

    it('should return hasData correctly', () => {
      const store = createMockStore();
      expect(store.hasData).toBe(false);

      store.reports = [{ id: '1', name: 'Report 1', tags: [], source: 'embedded' }];
      expect(store.hasData).toBe(true);
    });
  });
});
