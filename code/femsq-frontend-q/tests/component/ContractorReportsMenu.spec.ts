import { beforeEach, describe, expect, it, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';

import ContractorReportsMenu from '@/modules/reports/components/ContractorReportsMenu.vue';
import { filterReportsByComponent } from '@/modules/reports/utils/context-resolver';
import { useReportsStore } from '@/stores/reports';
import type { Organization } from '@/stores/organizations';
import type { ReportInfo } from '@/types/reports';

describe('ContractorReportsMenu', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  function setupStore(): ReturnType<typeof useReportsStore> {
    const store = useReportsStore();
    const report: ReportInfo = {
      id: 'contractor-card',
      name: 'Карточка контрагента',
      tags: [],
      source: 'embedded',
      uiIntegration: {
        showInReportsList: true,
        contextMenus: [
          {
            component: 'ContractorCard',
            label: 'Печатная карточка',
            icon: 'print',
            parameterMapping: {
              contractorId: '${contractorId}'
            }
          }
        ]
      }
    };
    store.reports = [report];
    store.loadReports = vi.fn().mockResolvedValue(undefined);
    store.loadMetadata = vi.fn().mockResolvedValue({
      id: 'contractor-card',
      version: '1.0',
      name: 'Карточка контрагента',
      created: '',
      lastModified: '',
      files: { template: 'contractor-card.jrxml' },
      parameters: [
        {
          name: 'contractorId',
          type: 'string',
          label: 'ID',
          required: true
        }
      ]
    });
    store.generateReportRequest = vi.fn().mockResolvedValue(new Blob(['test']));
    store.generatePreviewRequest = vi.fn().mockResolvedValue(new Blob(['preview']));
    store.downloadBlob = vi.fn();
    return store;
  }

  it('открывает меню и инициирует генерацию отчёта на основе контекста', async () => {
    const store = setupStore();
    const contractor: Organization = {
      ogKey: 42,
      ogName: 'ООО «Тест»',
      ogAgCount: 0
    };

    const wrapper = mount(ContractorReportsMenu, {
      props: { contractor }
    });

    const items = filterReportsByComponent(store.reports, 'ContractorCard');
    await (wrapper.vm as any).handleReportSelection(items[0]);

    expect(store.loadMetadata).toHaveBeenCalledWith('contractor-card');
    expect(store.generateReportRequest).toHaveBeenCalledTimes(1);
    const args = vi.mocked(store.generateReportRequest).mock.calls[0][0];
    expect(args.parameters).toMatchObject({ contractorId: '42' });
  });

  it('не отображает меню, если контрагента нет', () => {
    setupStore();
    const wrapper = mount(ContractorReportsMenu, {
      props: { contractor: null }
    });
    expect(wrapper.html()).toBe('<!---->');
  });
});

