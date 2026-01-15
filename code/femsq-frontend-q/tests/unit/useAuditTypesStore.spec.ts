import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useAuditTypesStore } from '@/stores/lookups/audit-types';
import * as auditTypesApi from '@/api/audit-types-api';
import type { RaAtDto } from '@/types/audits';

// Мокируем API клиент
vi.mock('@/api/audit-types-api', () => ({
  getAuditTypes: vi.fn()
}));

describe('useAuditTypesStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  describe('fetchAuditTypes', () => {
    it('должен загрузить список типов ревизий', async () => {
      const mockTypes: RaAtDto[] = [
        {
          atKey: 1,
          atName: 'Тип 1'
        },
        {
          atKey: 2,
          atName: 'Тип 2'
        }
      ];

      vi.mocked(auditTypesApi.getAuditTypes).mockResolvedValue(mockTypes);

      const store = useAuditTypesStore();
      expect(store.loading).toBe(false);
      expect(store.auditTypes).toEqual([]);

      await store.fetchAuditTypes();

      expect(store.loading).toBe(false);
      expect(store.auditTypes).toEqual(mockTypes);
      expect(store.error).toBeNull();
      expect(auditTypesApi.getAuditTypes).toHaveBeenCalledOnce();
    });

    it('должен обработать ошибку при загрузке', async () => {
      const error = new Error('Network error');
      vi.mocked(auditTypesApi.getAuditTypes).mockRejectedValue(error);

      const store = useAuditTypesStore();
      await store.fetchAuditTypes();

      expect(store.loading).toBe(false);
      expect(store.error).toBe('Network error');
      expect(store.auditTypes).toEqual([]);
    });

    it('не должен загружать повторно, если уже идет загрузка', async () => {
      vi.mocked(auditTypesApi.getAuditTypes).mockImplementation(() => new Promise(() => {})); // Неразрешенный промис

      const store = useAuditTypesStore();
      void store.fetchAuditTypes();
      void store.fetchAuditTypes();

      expect(store.loading).toBe(true);
      expect(auditTypesApi.getAuditTypes).toHaveBeenCalledOnce();
    });
  });
});
