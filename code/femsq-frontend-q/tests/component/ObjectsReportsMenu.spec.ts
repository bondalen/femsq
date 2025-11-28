import { beforeEach, describe, expect, it, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';

import ObjectsReportsMenu from '@/modules/reports/components/ObjectsReportsMenu.vue';
import { useReportsStore } from '@/stores/reports';
import type { ReportInfo } from '@/types/reports';
import { filterReportsByComponent } from '@/modules/reports/utils/context-resolver';

describe('ObjectsReportsMenu', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  function setupStore(): ReturnType<typeof useReportsStore> {
    const store = useReportsStore();
    const report: ReportInfo = {
      id: 'objects-list',
      name: 'Список объектов',
      tags: [],
      source: 'embedded',
      uiIntegration: {
        showInReportsList: true,
        contextMenus: [
          {
            component: 'ObjectsList',
            label: 'Список выбранных объектов',
            icon: 'list',
            parameterMapping: {
              objectIds: '${objectIds}'
            }
          }
        ]
      }
    };
    store.reports = [report];
    store.loadReports = vi.fn().mockResolvedValue(undefined);
    store.loadMetadata = vi.fn().mockResolvedValue({
      id: 'objects-list',
      version: '1.0',
      name: 'Список объектов',
      created: '',
      lastModified: '',
      files: { template: 'objects-list.jrxml' },
      parameters: [
        {
          name: 'objectIds',
          type: 'string',
          label: 'ID объектов',
          required: true
        }
      ]
    });
    store.generateReportRequest = vi.fn().mockResolvedValue(new Blob(['objects']));
    store.downloadBlob = vi.fn();
    store.generatePreviewRequest = vi.fn().mockResolvedValue(new Blob(['preview']));
    return store;
  }

  it('инициирует генерацию отчёта для выбранных объектов', async () => {
    const store = setupStore();
    const wrapper = mount(ObjectsReportsMenu, {
      props: {
        items: [{ objectId: 'OBJ-1' }, { objectId: 'OBJ-2' }]
      }
    });

    const items = filterReportsByComponent(store.reports, 'ObjectsList');
    await (wrapper.vm as any).handleReportSelection(items[0]);

    expect(store.loadMetadata).toHaveBeenCalledWith('objects-list');
    expect(store.generateReportRequest).toHaveBeenCalledTimes(1);
    const args = vi.mocked(store.generateReportRequest).mock.calls[0][0];
    expect(args.parameters).toMatchObject({ objectIds: 'OBJ-1,OBJ-2' });
  });

  it('отключает кнопку без выбранных объектов', () => {
    setupStore();
    const wrapper = mount(ObjectsReportsMenu, {
      props: { items: [] }
    });
    const button = wrapper.findComponent({ name: 'QBtn' });
    expect(button.props('disable')).toBe(true);
  });
});

