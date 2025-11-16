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
const RAW_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined)
  ?? (import.meta.env.PROD ? '/api/v1' : 'http://localhost:8080/api/v1');

function toAbsoluteBaseUrl(raw: string): string {
  const ensureTrailingSlash = (u: string) => (u.endsWith('/') ? u : `${u}/`);
  // already absolute
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return ensureTrailingSlash(raw);
  }
  // handle relative like "/api/v1" or "api/v1"
  const normalized = raw.startsWith('/') ? raw : `/${raw}`;
  const absolute = new URL(normalized, window.location.origin).toString();
  return ensureTrailingSlash(absolute);
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

  // Normalize relative path and avoid duplicating base segment (e.g., /api/v1 + api/v1/...)
  let relative = path.replace(/^\//, '');
  try {
    const basePath = new URL(API_BASE_URL).pathname.replace(/^\/+|\/+$/g, ''); // e.g., 'api/v1'
    if (basePath && (relative === basePath || relative.startsWith(basePath + '/'))) {
      relative = relative.slice(basePath.length).replace(/^\//, '');
    }
  } catch {
    // ignore URL parsing errors; fall back to original relative
  }

  const url = new URL(relative, API_BASE_URL);

  if (query) {
    Object.entries(query)
      .filter(([, value]) => value !== undefined && value !== null && value !== '')
      .forEach(([key, value]) => url.searchParams.set(key, String(value)));
  }

  return url.toString();
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
