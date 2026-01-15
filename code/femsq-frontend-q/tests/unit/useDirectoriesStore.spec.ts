import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useDirectoriesStore } from '@/stores/lookups/directories';
import * as directoriesApi from '@/api/directories-api';
import type { RaDirDto } from '@/types/audits';

// Мокируем API клиент
vi.mock('@/api/directories-api', () => ({
  getDirectories: vi.fn()
}));

describe('useDirectoriesStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  describe('fetchDirectories', () => {
    it('должен загрузить список директорий', async () => {
      const mockDirectories: RaDirDto[] = [
        {
          key: 1,
          dirName: 'Директория 1',
          dir: '/path/to/dir1'
        },
        {
          key: 2,
          dirName: 'Директория 2',
          dir: '/path/to/dir2'
        }
      ];

      vi.mocked(directoriesApi.getDirectories).mockResolvedValue(mockDirectories);

      const store = useDirectoriesStore();
      expect(store.loading).toBe(false);
      expect(store.directories).toEqual([]);

      await store.fetchDirectories();

      expect(store.loading).toBe(false);
      expect(store.directories).toEqual(mockDirectories);
      expect(store.error).toBeNull();
      expect(directoriesApi.getDirectories).toHaveBeenCalledOnce();
    });

    it('должен обработать ошибку при загрузке', async () => {
      const error = new Error('Network error');
      vi.mocked(directoriesApi.getDirectories).mockRejectedValue(error);

      const store = useDirectoriesStore();
      await store.fetchDirectories();

      expect(store.loading).toBe(false);
      expect(store.error).toBe('Network error');
      expect(store.directories).toEqual([]);
    });

    it('не должен загружать повторно, если уже идет загрузка', async () => {
      vi.mocked(directoriesApi.getDirectories).mockImplementation(() => new Promise(() => {})); // Неразрешенный промис

      const store = useDirectoriesStore();
      void store.fetchDirectories();
      void store.fetchDirectories();

      expect(store.loading).toBe(true);
      expect(directoriesApi.getDirectories).toHaveBeenCalledOnce();
    });
  });
});
