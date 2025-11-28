/**
 * Component tests for ReportsCatalog.vue
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { setActivePinia, createPinia } from 'pinia';
import ReportsCatalog from './ReportsCatalog.vue';
import { useReportsStore } from '@/stores/reports';
import type { ReportInfo } from '@/types/reports';

// Mock the store
vi.mock('@/stores/reports', () => ({
  useReportsStore: vi.fn()
}));

// Mock ReportParametersDialog
vi.mock('../components/ReportParametersDialog.vue', () => ({
  default: {
    name: 'ReportParametersDialog',
    template: '<div class="mock-dialog"></div>',
    props: ['reportId', 'open'],
    emits: ['close', 'generate', 'preview']
  }
}));

describe('ReportsCatalog.vue', () => {
  let store: ReturnType<typeof useReportsStore>;

  beforeEach(() => {
    setActivePinia(createPinia());
    
    // Create mock store
    store = {
      loading: false,
      error: '',
      reports: [],
      categories: [],
      tags: [],
      filters: {
        category: '',
        tag: '',
        search: ''
      },
      filteredReports: [],
      filteredTotal: 0,
      total: 0,
      hasData: false,
      loadReports: vi.fn().mockResolvedValue(undefined),
      loadCategories: vi.fn().mockResolvedValue(undefined),
      loadTags: vi.fn().mockResolvedValue(undefined),
      generateReportRequest: vi.fn().mockResolvedValue(new Blob()),
      generatePreviewRequest: vi.fn().mockResolvedValue(new Blob()),
      downloadBlob: vi.fn()
    } as unknown as ReturnType<typeof useReportsStore>;

    vi.mocked(useReportsStore).mockReturnValue(store);
  });

  it('should render catalog header', () => {
    const wrapper = mount(ReportsCatalog);
    
    expect(wrapper.find('h1').text()).toBe('Каталог отчётов');
    expect(wrapper.find('.reports-catalog__counter').text()).toContain('Найдено:');
  });

  it('should show loading state', () => {
    store.loading = true;
    const wrapper = mount(ReportsCatalog);
    
    expect(wrapper.find('.reports-catalog__alert--info').exists()).toBe(true);
    expect(wrapper.find('.reports-catalog__alert--info').text()).toContain('Загрузка отчётов');
  });

  it('should show error state', () => {
    store.error = 'Test error message';
    const wrapper = mount(ReportsCatalog);
    
    expect(wrapper.find('.reports-catalog__alert--error').exists()).toBe(true);
    expect(wrapper.find('.reports-catalog__alert--error').text()).toContain('Test error message');
  });

  it('should display reports in grid', () => {
    const mockReports: ReportInfo[] = [
      {
        id: 'report-1',
        name: 'Test Report 1',
        description: 'Test description 1',
        category: 'finance',
        tags: ['test', 'demo'],
        source: 'embedded'
      },
      {
        id: 'report-2',
        name: 'Test Report 2',
        description: 'Test description 2',
        category: 'analytics',
        tags: ['test'],
        source: 'external'
      }
    ];

    store.reports = mockReports;
    store.filteredReports = mockReports;
    store.filteredTotal = 2;
    store.hasData = true;

    const wrapper = mount(ReportsCatalog);
    
    const cards = wrapper.findAll('.reports-catalog__card');
    expect(cards).toHaveLength(2);
    expect(cards[0].find('.reports-catalog__card-title').text()).toBe('Test Report 1');
    expect(cards[1].find('.reports-catalog__card-title').text()).toBe('Test Report 2');
  });

  it('should display report badges correctly', () => {
    const mockReports: ReportInfo[] = [
      {
        id: 'report-1',
        name: 'Embedded Report',
        tags: [],
        source: 'embedded'
      },
      {
        id: 'report-2',
        name: 'External Report',
        tags: [],
        source: 'external'
      }
    ];

    store.reports = mockReports;
    store.filteredReports = mockReports;
    store.filteredTotal = 2;
    store.hasData = true;

    const wrapper = mount(ReportsCatalog);
    
    const badges = wrapper.findAll('.reports-catalog__badge');
    expect(badges[0].text()).toBe('Встроенный');
    expect(badges[1].text()).toBe('Внешний');
    expect(badges[0].classes()).toContain('reports-catalog__badge--embedded');
    expect(badges[1].classes()).toContain('reports-catalog__badge--external');
  });

  it('should display report tags', () => {
    const mockReports: ReportInfo[] = [
      {
        id: 'report-1',
        name: 'Test Report',
        tags: ['test', 'demo', 'production'],
        source: 'embedded'
      }
    ];

    store.reports = mockReports;
    store.filteredReports = mockReports;
    store.filteredTotal = 1;
    store.hasData = true;

    const wrapper = mount(ReportsCatalog);
    
    const tags = wrapper.findAll('.reports-catalog__tag');
    expect(tags).toHaveLength(3);
    expect(tags[0].text()).toBe('test');
    expect(tags[1].text()).toBe('demo');
    expect(tags[2].text()).toBe('production');
  });

  it('should show empty state when no reports', () => {
    store.reports = [];
    store.filteredReports = [];
    store.filteredTotal = 0;
    store.hasData = false;

    const wrapper = mount(ReportsCatalog);
    
    expect(wrapper.find('.reports-catalog__empty').exists()).toBe(true);
    expect(wrapper.find('.reports-catalog__empty').text()).toContain('Отчёты не найдены');
  });

  it('should call loadReports on refresh button click', async () => {
    const wrapper = mount(ReportsCatalog);
    
    const refreshButton = wrapper.find('.reports-catalog__refresh');
    await refreshButton.trigger('click');
    
    expect(store.loadReports).toHaveBeenCalled();
    expect(store.loadCategories).toHaveBeenCalled();
    expect(store.loadTags).toHaveBeenCalled();
  });

  it('should disable refresh button when loading', () => {
    store.loading = true;
    const wrapper = mount(ReportsCatalog);
    
    const refreshButton = wrapper.find('.reports-catalog__refresh');
    expect(refreshButton.attributes('disabled')).toBeDefined();
    expect(refreshButton.text()).toContain('Загрузка…');
  });

  it('should display filters', () => {
    store.categories = ['finance', 'analytics'];
    store.tags = ['test', 'demo'];
    store.reports = [];
    store.filteredReports = [];
    store.hasData = false;

    const wrapper = mount(ReportsCatalog);
    
    const categorySelect = wrapper.find('#category-filter');
    expect(categorySelect.exists()).toBe(true);
    
    const tagSelect = wrapper.find('#tag-filter');
    expect(tagSelect.exists()).toBe(true);
    
    const searchInput = wrapper.find('#search-filter');
    expect(searchInput.exists()).toBe(true);
  });

  it('should open dialog when report card is clicked', async () => {
    const mockReports: ReportInfo[] = [
      {
        id: 'report-1',
        name: 'Test Report',
        tags: [],
        source: 'embedded'
      }
    ];

    store.reports = mockReports;
    store.filteredReports = mockReports;
    store.filteredTotal = 1;
    store.hasData = true;
    store.loadMetadata = vi.fn().mockResolvedValue({
      id: 'report-1',
      version: '1.0.0',
      name: 'Test Report',
      created: '2025-01-01',
      lastModified: '2025-01-01',
      files: { template: 'test.jrxml' },
      parameters: []
    });

    const wrapper = mount(ReportsCatalog);
    
    const card = wrapper.find('.reports-catalog__card');
    await card.trigger('click');
    
    await wrapper.vm.$nextTick();
    
    const dialog = wrapper.findComponent({ name: 'ReportParametersDialog' });
    expect(dialog.exists()).toBe(true);
    expect(dialog.props('reportId')).toBe('report-1');
  });

  it('should call loadReports on mount', () => {
    mount(ReportsCatalog);
    
    expect(store.loadReports).toHaveBeenCalled();
    expect(store.loadCategories).toHaveBeenCalled();
    expect(store.loadTags).toHaveBeenCalled();
  });
});
