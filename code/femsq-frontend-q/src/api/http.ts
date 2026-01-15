const DEFAULT_TIMEOUT = 15_000;

/**
 * Определяет базовый URL для API-запросов.
 * 
 * <p>Логика определения:
 * <ul>
 *   <li>Если задан VITE_API_BASE_URL - используется он</li>
 *   <li>В development режиме (import.meta.env.DEV) - используется http://localhost:8080</li>
 *   <li>В production режиме (import.meta.env.PROD) - используется относительный путь /api/v1</li>
 * </ul>
 * 
 * <p>В production режиме (когда frontend встроен в JAR) все запросы идут
 * на относительные пути, что позволяет избежать проблем с CORS и упрощает развертывание.
 */
/**
 * В development режиме используем относительные пути для работы с Vite proxy.
 * В production режиме используем относительные пути, так как frontend встроен в JAR.
 * Если задан VITE_API_BASE_URL - используется он (для кастомных конфигураций).
 * 
 * Базовый URL установлен в '/api', так как контроллеры используют пути вида:
 * - /api/v1/... (старые контроллеры)
 * - /api/ra/... (новые контроллеры ревизий)
 */
const RAW_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined)
  ?? '/api';

function toAbsoluteBaseUrl(raw: string): string {
  const ensureTrailingSlash = (u: string) => (u.endsWith('/') ? u : `${u}/`);
  const toAbsolute = (base: string, path: string): string => {
    const absolute = new URL(path, base).toString();
    return ensureTrailingSlash(absolute);
  };

  // already absolute
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return ensureTrailingSlash(raw);
  }

  // handle relative like "/api/v1" or "api/v1"
  const normalized = raw.startsWith('/') ? raw : `/${raw}`;

  if (typeof window === 'undefined' || !window.location) {
    const fallbackOrigin = 'http://localhost:8080';
    console.warn('[API] window.location недоступен, используется fallback:', fallbackOrigin);
    return toAbsolute(fallbackOrigin, normalized);
  }

  const origin = window.location.origin;
  const isOriginValid = origin && origin !== 'null' && origin !== 'undefined';

  if (isOriginValid) {
    try {
      return toAbsolute(origin, normalized);
    } catch (error) {
      console.error('[API] Ошибка создания URL из', normalized, 'и', origin, error);
    }
  } else {
    console.warn('[API] window.location.origin некорректен:', origin);
  }

  // Fallback на текущий протокол/хост или localhost
  const protocol = window.location.protocol || 'http:';
  const host = window.location.host || 'localhost:8080';
  const fallbackOrigin = `${protocol}//${host}`;

  try {
    return toAbsolute(fallbackOrigin, normalized);
  } catch (error) {
    console.error('[API] Ошибка создания fallback URL из', fallbackOrigin, 'и', normalized, error);
    return toAbsolute('http://localhost:8080', normalized);
  }
}

const API_BASE_URL = toAbsoluteBaseUrl(RAW_BASE_URL);

export interface RequestErrorOptions {
  readonly status: number;
  readonly statusText: string;
  readonly url: string;
  readonly body?: unknown;
}

export class RequestError extends Error {
  readonly status: number;
  readonly statusText: string;
  readonly url: string;
  readonly body?: unknown;

  constructor(message: string, options: RequestErrorOptions) {
    super(message);
    this.name = 'RequestError';
    this.status = options.status;
    this.statusText = options.statusText;
    this.url = options.url;
    this.body = options.body;
  }
}

interface RequestOptions extends RequestInit {
  timeoutMs?: number;
  query?: Record<string, unknown>;
}

function buildUrl(path: string, query?: Record<string, unknown>): string {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    const abs = new URL(path);
    if (query) {
      Object.entries(query)
        .filter(([, value]) => value !== undefined && value !== null && value !== '')
        .forEach(([key, value]) => abs.searchParams.set(key, String(value)));
    }
    return abs.toString();
  }

  const applyQuery = (url: URL): string => {
    if (query) {
      Object.entries(query)
        .filter(([, value]) => value !== undefined && value !== null && value !== '')
        .forEach(([key, value]) => url.searchParams.set(key, String(value)));
    }
    return url.toString();
  };

  // Normalize relative path and avoid duplicating base segment
  // Обрабатываем пути вида /api/ra/... или /api/v1/...
  let relative = path.replace(/^\//, ''); // Убираем ведущий слеш
  
  // Определяем базовый URL для создания полного URL
  let baseUrl: string;
  
  // Если путь уже начинается с 'api/', используем корневой URL сервера
  // Это позволяет работать с обоими паттернами: /api/v1/... и /api/ra/...
  if (relative.startsWith('api/')) {
    // Путь уже содержит полный путь от корня, используем origin сервера
    if (typeof window !== 'undefined' && window.location) {
      baseUrl = window.location.origin + '/';
    } else {
      baseUrl = 'http://localhost:8080/';
    }
  } else {
    // Путь не содержит 'api/', используем API_BASE_URL напрямую
    // API_BASE_URL уже содержит полный URL типа http://localhost:8080/api/
    baseUrl = API_BASE_URL;
  }

  const fallbackBase = 'http://localhost:8080/';

  try {
    const url = new URL(relative, baseUrl);
    return applyQuery(url);
  } catch (error) {
    console.error('[API] Ошибка создания URL в buildUrl:', error, 'fallback на', fallbackBase);
    const url = new URL(relative, fallbackBase);
    return applyQuery(url);
  }
}

export async function apiRequest<T = unknown>(path: string, options: RequestOptions = {}): Promise<T> {
  const controller = new AbortController();
  const timeout = options.timeoutMs ?? DEFAULT_TIMEOUT;
  const timeoutId = window.setTimeout(() => controller.abort(), timeout);

  const url = buildUrl(path, options.query);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
      headers: {
        Accept: 'application/json',
        ...(options.headers ?? {})
      }
    });

    const contentType = response.headers.get('content-type');
    const isJson = contentType?.includes('application/json');
    const body = isJson ? await response.json().catch(() => undefined) : await response.text().catch(() => undefined);

    if (!response.ok) {
      const message = typeof body === 'object' && body && 'message' in body
        ? String((body as { message?: unknown }).message)
        : `Запрос завершился с ошибкой ${response.status}`;
      throw new RequestError(message, {
        status: response.status,
        statusText: response.statusText,
        url: response.url,
        body
      });
    }

    return body as T;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new RequestError('Превышено время ожидания ответа от сервера', {
        status: 0,
        statusText: 'Timeout',
        url
      });
    }
    throw new RequestError('Не удалось выполнить запрос к серверу', {
      status: 0,
      statusText: 'NetworkError',
      url
    });
  } finally {
    window.clearTimeout(timeoutId);
  }
}

export function apiGet<T = unknown>(path: string, options?: Omit<RequestOptions, 'method'>): Promise<T> {
  return apiRequest<T>(path, { ...options, method: 'GET' });
}

export function apiPost<T = unknown>(path: string, data?: unknown, options?: Omit<RequestOptions, 'method' | 'body'>): Promise<T> {
  return apiRequest<T>(path, {
    ...options,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(options?.headers ?? {})
    },
    body: data ? JSON.stringify(data) : undefined
  });
}

export function apiPut<T = unknown>(path: string, data?: unknown, options?: Omit<RequestOptions, 'method' | 'body'>): Promise<T> {
  return apiRequest<T>(path, {
    ...options,
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      ...(options?.headers ?? {})
    },
    body: data ? JSON.stringify(data) : undefined
  });
}

export function apiDelete<T = unknown>(path: string, options?: Omit<RequestOptions, 'method'>): Promise<T> {
  return apiRequest<T>(path, { ...options, method: 'DELETE' });
}
