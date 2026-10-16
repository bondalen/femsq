/**
 * Сохранение Blob в выбранную пользователем папку (Windows / Linux).
 *
 * Использует File System Access API ({@code showDirectoryPicker}) — Chrome / Edge / Chromium.
 * Выбор папки — только из обработчика клика ({@link pickExportDirectory}).
 * Сохранение без уже выбранной папки не вызывает {@code showDirectoryPicker}:
 * после ожидания ответа сервера браузер отклоняет диалог.
 * Если API недоступен — обычная загрузка браузера.
 */

/** Текст, когда Excel запрошен, а папка ещё не выбрана значком. */
export const EXPORT_FOLDER_MISSING_MESSAGE =
  'Папка выгрузки не выбрана. Нажмите значок папки справа от поля «Папка выгрузки Excel» и повторите «Выполнить».';

/** Текст, когда выбранная папка есть, а права записи нет. */
export const EXPORT_FOLDER_DENIED_MESSAGE =
  'Нет права записи в выбранную папку. Нажмите значок папки и выберите её снова.';

const IDB_NAME = 'femsq-export';
const IDB_STORE = 'handles';
const IDB_KEY_DIR = 'sudzExportDir';

export type SaveBlobResult =
  | { method: 'directory'; folderName: string }
  | { method: 'download' };

/**
 * Поддерживается ли выбор папки в текущем браузере.
 */
export function supportsDirectoryPicker(): boolean {
  return typeof window !== 'undefined' && 'showDirectoryPicker' in window;
}

/**
 * Открывает системный диалог выбора папки и запоминает handle в IndexedDB.
 *
 * @returns имя папки или {@code null}, если отменено / API нет
 */
export async function pickExportDirectory(): Promise<string | null> {
  if (!supportsDirectoryPicker()) {
    return null;
  }
  try {
    const dirHandle = await window.showDirectoryPicker({ mode: 'readwrite' });
    await persistDirectoryHandle(dirHandle);
    return dirHandle.name;
  } catch (error) {
    if (isAbortError(error)) {
      return null;
    }
    throw error;
  }
}

/**
 * Имя ранее выбранной папки (без проверки прав).
 */
export async function getRememberedDirectoryName(): Promise<string | null> {
  const handle = await loadDirectoryHandle();
  return handle?.name ?? null;
}

/**
 * Сохраняет blob в ранее выбранную папку. Без папки — ошибка с просьбой нажать значок.
 * Если выбор папки в браузере недоступен — обычная загрузка.
 *
 * @param blob содержимое файла
 * @param fileName имя файла (без пути)
 */
export async function saveBlobToExportFolder(
  blob: Blob,
  fileName: string
): Promise<SaveBlobResult> {
  if (supportsDirectoryPicker()) {
    const dirHandle = await loadDirectoryHandle();
    if (!dirHandle) {
      throw new Error(EXPORT_FOLDER_MISSING_MESSAGE);
    }
    const ok = await ensureWritePermission(dirHandle);
    if (!ok) {
      throw new Error(EXPORT_FOLDER_DENIED_MESSAGE);
    }
    const fileHandle = await dirHandle.getFileHandle(fileName, { create: true });
    // keepExistingData: false — полная перезапись; иначе Chrome FSA падает при повторной записи
    const writable = await fileHandle.createWritable({ keepExistingData: false });
    try {
      await writable.write(blob);
      await writable.close();
    } catch (error) {
      try {
        await writable.abort();
      } catch {
        // ignore abort errors
      }
      throw error;
    }
    return { method: 'directory', folderName: dirHandle.name };
  }

  triggerBrowserDownload(blob, fileName);
  return { method: 'download' };
}

/**
 * Обычная браузерная загрузка (Downloads / Save As).
 */
export function triggerBrowserDownload(blob: Blob, fileName: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  a.click();
  URL.revokeObjectURL(url);
}

function isAbortError(error: unknown): boolean {
  return error instanceof DOMException && error.name === 'AbortError';
}

async function ensureWritePermission(dirHandle: FileSystemDirectoryHandle): Promise<boolean> {
  const opts = { mode: 'readwrite' as const };
  // queryPermission / requestPermission есть у FileSystemHandle
  const withPerm = dirHandle as FileSystemDirectoryHandle & {
    queryPermission?: (o: { mode: 'readwrite' }) => Promise<PermissionState>;
    requestPermission?: (o: { mode: 'readwrite' }) => Promise<PermissionState>;
  };
  if (withPerm.queryPermission) {
    let state = await withPerm.queryPermission(opts);
    if (state === 'granted') {
      return true;
    }
    if (withPerm.requestPermission) {
      state = await withPerm.requestPermission(opts);
      return state === 'granted';
    }
    return false;
  }
  return true;
}

function openIdb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(IDB_NAME, 1);
    req.onerror = () => reject(req.error ?? new Error('IndexedDB open failed'));
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(IDB_STORE)) {
        db.createObjectStore(IDB_STORE);
      }
    };
    req.onsuccess = () => resolve(req.result);
  });
}

async function persistDirectoryHandle(handle: FileSystemDirectoryHandle): Promise<void> {
  const db = await openIdb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(IDB_STORE, 'readwrite');
    tx.objectStore(IDB_STORE).put(handle, IDB_KEY_DIR);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error ?? new Error('IndexedDB put failed'));
  });
  db.close();
}

async function loadDirectoryHandle(): Promise<FileSystemDirectoryHandle | null> {
  try {
    const db = await openIdb();
    const handle = await new Promise<FileSystemDirectoryHandle | null>((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, 'readonly');
      const req = tx.objectStore(IDB_STORE).get(IDB_KEY_DIR);
      req.onsuccess = () => resolve((req.result as FileSystemDirectoryHandle) ?? null);
      req.onerror = () => reject(req.error ?? new Error('IndexedDB get failed'));
    });
    db.close();
    return handle;
  } catch {
    return null;
  }
}

export async function clearRememberedDirectory(): Promise<void> {
  try {
    const db = await openIdb();
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, 'readwrite');
      tx.objectStore(IDB_STORE).delete(IDB_KEY_DIR);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error ?? new Error('IndexedDB delete failed'));
    });
    db.close();
  } catch {
    // ignore
  }
}
