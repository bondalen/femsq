import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useAuditsStore } from '@/stores/audits';
import * as auditsApi from '@/api/audits-api';
import type { RaADto } from '@/types/audits';

// Мокируем API клиент
vi.mock('@/api/audits-api', () => ({
  getAudits: vi.fn(),
  getAuditById: vi.fn(),
  createAudit: vi.fn(),
  updateAudit: vi.fn(),
  deleteAudit: vi.fn()
}));

describe('useAuditsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  describe('fetchAudits', () => {
    it('должен загрузить список ревизий', async () => {
      const mockAudits: RaADto[] = [
        {
          adtKey: 1,
          adtName: 'Ревизия 1',
          adtDate: '2024-01-01T10:00:00',
          adtDir: 1,
          adtType: 1,
          adtAddRA: false
        },
        {
          adtKey: 2,
          adtName: 'Ревизия 2',
          adtDate: '2024-01-02T10:00:00',
          adtDir: 2,
          adtType: 2,
          adtAddRA: true
        }
      ];

      vi.mocked(auditsApi.getAudits).mockResolvedValue(mockAudits);

      const store = useAuditsStore();
      expect(store.loading).toBe(false);
      expect(store.audits).toEqual([]);

      await store.fetchAudits();

      expect(store.loading).toBe(false);
      expect(store.audits).toEqual(mockAudits);
      expect(store.lastUpdatedAt).toBeTruthy();
      expect(auditsApi.getAudits).toHaveBeenCalledOnce();
    });

    it('должен обработать ошибку при загрузке', async () => {
      const error = new Error('Network error');
      vi.mocked(auditsApi.getAudits).mockRejectedValue(error);

      const store = useAuditsStore();
      await store.fetchAudits();

      expect(store.loading).toBe(false);
      expect(store.error).toBe('Network error');
      expect(store.audits).toEqual([]);
    });

    it('не должен загружать повторно, если уже идет загрузка', async () => {
      const mockAudits: RaADto[] = [];
      vi.mocked(auditsApi.getAudits).mockImplementation(() => new Promise(() => {})); // Неразрешенный промис

      const store = useAuditsStore();
      const promise1 = store.fetchAudits();
      const promise2 = store.fetchAudits();

      expect(store.loading).toBe(true);
      expect(auditsApi.getAudits).toHaveBeenCalledOnce();
    });
  });

  describe('fetchAuditById', () => {
    it('должен загрузить ревизию по ID', async () => {
      const mockAudit: RaADto = {
        adtKey: 1,
        adtName: 'Ревизия 1',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      };

      vi.mocked(auditsApi.getAuditById).mockResolvedValue(mockAudit);

      const store = useAuditsStore();
      const result = await store.fetchAuditById(1);

      expect(result).toEqual(mockAudit);
      expect(auditsApi.getAuditById).toHaveBeenCalledWith(1);
    });

    it('должен обработать ошибку при загрузке по ID', async () => {
      const error = new Error('Not found');
      vi.mocked(auditsApi.getAuditById).mockRejectedValue(error);

      const store = useAuditsStore();
      const result = await store.fetchAuditById(999);

      expect(result).toBeNull();
      expect(store.error).toBe('Not found');
    });
  });

  describe('createAudit', () => {
    it('должен создать новую ревизию', async () => {
      const newAudit: RaADto = {
        adtKey: 1,
        adtName: 'Новая ревизия',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      };

      vi.mocked(auditsApi.createAudit).mockResolvedValue(newAudit);

      const store = useAuditsStore();
      const result = await store.createAudit({
        adtName: 'Новая ревизия',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      });

      expect(result).toEqual(newAudit);
      expect(store.audits.length).toBe(1);
      expect(store.audits[0]).toEqual(newAudit);
      expect(store.error).toBeNull();
    });

    it('должен обработать ошибку при создании', async () => {
      const error = new Error('Validation failed');
      vi.mocked(auditsApi.createAudit).mockRejectedValue(error);

      const store = useAuditsStore();
      
      await expect(store.createAudit({
        adtName: '',
        adtDate: null,
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      })).rejects.toThrow('Validation failed');

      expect(store.error).toBe('Validation failed');
    });
  });

  describe('updateAudit', () => {
    it('должен обновить существующую ревизию', async () => {
      const existingAudit: RaADto = {
        adtKey: 1,
        adtName: 'Старое имя',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      };

      const updatedAudit: RaADto = {
        ...existingAudit,
        adtName: 'Новое имя'
      };

      const store = useAuditsStore();
      store.audits.push(existingAudit);
      vi.mocked(auditsApi.updateAudit).mockResolvedValue(updatedAudit);
      const result = await store.updateAudit(1, {
        adtName: 'Новое имя',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      });

      expect(result).toEqual(updatedAudit);
      expect(store.audits[0].adtName).toBe('Новое имя');
      expect(store.error).toBeNull();
    });
  });

  describe('deleteAudit', () => {
    it('должен удалить ревизию', async () => {
      const audit: RaADto = {
        adtKey: 1,
        adtName: 'Ревизия для удаления',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      };

      const store = useAuditsStore();
      store.audits.push(audit);

      vi.mocked(auditsApi.deleteAudit).mockResolvedValue(undefined);

      const result = await store.deleteAudit(1);

      expect(result).toBe(true);
      expect(store.audits).not.toContain(audit);
      expect(store.audits.length).toBe(0);
      expect(store.error).toBeNull();
    });

    it('должен обработать ошибку при удалении', async () => {
      const error = new Error('Delete failed');
      vi.mocked(auditsApi.deleteAudit).mockRejectedValue(error);

      const store = useAuditsStore();
      
      await expect(store.deleteAudit(999)).rejects.toThrow('Delete failed');
      expect(store.error).toBe('Delete failed');
    });
  });

  describe('hasAudits', () => {
    it('должен вернуть true, если есть ревизии', () => {
      const store = useAuditsStore();
      store.audits.push({
        adtKey: 1,
        adtName: 'Ревизия',
        adtDate: '2024-01-01T10:00:00',
        adtDir: 1,
        adtType: 1,
        adtAddRA: false
      });

      expect(store.hasAudits).toBe(true);
    });

    it('должен вернуть false, если ревизий нет', () => {
      const store = useAuditsStore();
      expect(store.hasAudits).toBe(false);
    });
  });

  describe('clearError', () => {
    it('должен очистить ошибку', () => {
      const store = useAuditsStore();
      store.error = 'Some error';
      
      store.clearError();
      
      expect(store.error).toBeNull();
    });
  });
});
