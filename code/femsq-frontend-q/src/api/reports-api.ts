/**
 * API клиент для работы с отчётами (Quasar версия).
 */

import { apiGet, RequestError } from './http';
import type {
  ReportGenerationRequest,
  ReportInfo,
  ReportMetadata,
  ReportParameter
} from '@/types/reports';

const REPORTS_API_BASE = '/api/v1/reports';

export type ApiError = RequestError;

/**
 * Получает список всех доступных отчётов.
 */
export async function getAvailableReports(category?: string, tag?: string): Promise<ReportInfo[]> {
  return apiGet<ReportInfo[]>(`${REPORTS_API_BASE}/available`, {
    query: {
      category,
      tag
    }
  });
}

/**
 * Получает метаданные конкретного отчёта.
 */
export async function getReportMetadata(reportId: string): Promise<ReportMetadata> {
  return apiGet<ReportMetadata>(`${REPORTS_API_BASE}/${reportId}/metadata`);
}

/**
 * Получает параметры отчёта с учётом контекста.
 */
export async function getReportParameters(
  reportId: string,
  context?: Record<string, string>
): Promise<ReportParameter[]> {
  return apiGet<ReportParameter[]>(`${REPORTS_API_BASE}/${reportId}/parameters`, {
    query: context
  });
}

/**
 * Получает список категорий отчётов.
 */
export function getCategories(): Promise<string[]> {
  return apiGet<string[]>(`${REPORTS_API_BASE}/categories`);
}

/**
 * Получает список тегов отчётов.
 */
export function getTags(): Promise<string[]> {
  return apiGet<string[]>(`${REPORTS_API_BASE}/tags`);
}

/**
 * Загружает опции параметра из внешнего источника.
 */
export function getParameterSource(
  reportId: string,
  parameterName: string
): Promise<Array<{ value: string | number; label: string }>> {
  return apiGet<Array<{ value: string | number; label: string }>>(
    `${REPORTS_API_BASE}/parameters/source/${reportId}/${parameterName}`
  );
}

/**
 * Генерирует отчёт в указанном формате.
 */
export async function generateReport(request: ReportGenerationRequest): Promise<Blob> {
  const url = resolveUrl(`${REPORTS_API_BASE}/${request.reportId}/generate`);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage = errorText;

      try {
        const json = JSON.parse(errorText);
        errorMessage = json.message || json.error || errorText;
      } catch {
        // ignore JSON parse errors
      }

      throw new RequestError(errorMessage, {
        status: response.status,
        statusText: response.statusText,
        url: response.url,
        body: errorText
      });
    }

    return await response.blob();
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw new RequestError(
      error instanceof Error ? error.message : 'Неизвестная ошибка при генерации отчёта',
      {
        status: 0,
        statusText: 'NetworkError',
        url
      }
    );
  }
}

/**
 * Генерирует предпросмотр (первая страница PDF).
 */
export async function generatePreview(
  reportId: string,
  parameters?: Record<string, unknown>
): Promise<Blob> {
  const url = resolveUrl(`${REPORTS_API_BASE}/${reportId}/preview`);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(parameters ?? {})
    });

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage = errorText;

      try {
        const json = JSON.parse(errorText);
        errorMessage = json.message || json.error || errorText;
      } catch {
        // ignore JSON parse errors
      }

      throw new RequestError(errorMessage, {
        status: response.status,
        statusText: response.statusText,
        url: response.url,
        body: errorText
      });
    }

    return await response.blob();
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw new RequestError(
      error instanceof Error ? error.message : 'Неизвестная ошибка при генерации preview',
      {
        status: 0,
        statusText: 'NetworkError',
        url
      }
    );
  }
}

function resolveUrl(path: string): string {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  const normalized = path.startsWith('/') ? path : `/${path}`;

  if (typeof window !== 'undefined' && window.location) {
    try {
      return new URL(normalized, window.location.origin).toString();
    } catch (error) {
      console.error('[reports-api] Ошибка построения URL', normalized, error);
    }
  }

  return `http://localhost:8080${normalized}`;
}

