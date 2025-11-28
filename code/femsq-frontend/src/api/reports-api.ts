/**
 * API клиент для работы с отчётами.
 */

import { apiGet, apiPost, type ApiError } from './http-client';
import type {
  ReportInfo,
  ReportMetadata,
  ReportParameter,
  ReportGenerationRequest
} from '../types/reports';

const REPORTS_API_BASE = '/api/v1/reports';

/**
 * Получает список всех доступных отчётов.
 *
 * @param category опциональный фильтр по категории
 * @param tag опциональный фильтр по тегу
 * @returns Promise со списком отчётов
 * @throws {ApiError} при ошибке запроса
 */
export async function getAvailableReports(
  category?: string,
  tag?: string
): Promise<ReportInfo[]> {
  const params = new URLSearchParams();
  if (category) params.append('category', category);
  if (tag) params.append('tag', tag);
  
  const queryString = params.toString();
  const endpoint = `${REPORTS_API_BASE}/available${queryString ? `?${queryString}` : ''}`;
  
  return apiGet<ReportInfo[]>(endpoint);
}

/**
 * Получает метаданные конкретного отчёта.
 *
 * @param reportId идентификатор отчёта
 * @returns Promise с метаданными отчёта
 * @throws {ApiError} при ошибке запроса или если отчёт не найден
 */
export async function getReportMetadata(reportId: string): Promise<ReportMetadata> {
  return apiGet<ReportMetadata>(`${REPORTS_API_BASE}/${reportId}/metadata`);
}

/**
 * Получает параметры отчёта с разрешёнными значениями по умолчанию.
 *
 * @param reportId идентификатор отчёта
 * @param context опциональный контекст для разрешения динамических значений
 * @returns Promise со списком параметров
 * @throws {ApiError} при ошибке запроса
 */
export async function getReportParameters(
  reportId: string,
  context?: Record<string, string>
): Promise<ReportParameter[]> {
  const params = new URLSearchParams();
  if (context) {
    Object.entries(context).forEach(([key, value]) => {
      params.append(key, value);
    });
  }
  
  const queryString = params.toString();
  const endpoint = `${REPORTS_API_BASE}/${reportId}/parameters${queryString ? `?${queryString}` : ''}`;
  
  return apiGet<ReportParameter[]>(endpoint);
}

/**
 * Генерирует отчёт в указанном формате.
 *
 * @param request запрос на генерацию отчёта
 * @returns Promise с Blob содержимым отчёта
 * @throws {ApiError} при ошибке запроса
 */
export async function generateReport(
  request: ReportGenerationRequest
): Promise<Blob> {
  const url = `${REPORTS_API_BASE}/${request.reportId}/generate`;
  
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
        const errorJson = JSON.parse(errorText);
        errorMessage = errorJson.message || errorJson.error || errorText;
      } catch {
        // Если не JSON, используем текст как есть
      }

      throw {
        message: errorMessage,
        status: response.status,
        statusText: response.statusText
      } as ApiError;
    }

    // Получаем имя файла из заголовка Content-Disposition
    const contentDisposition = response.headers.get('content-disposition');
    let fileName = `${request.reportId}.${request.format}`;
    if (contentDisposition) {
      const fileNameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
      if (fileNameMatch && fileNameMatch[1]) {
        fileName = fileNameMatch[1].replace(/['"]/g, '');
      }
    }

    const blob = await response.blob();
    
    return blob;
  } catch (error) {
    if (error && typeof error === 'object' && 'message' in error) {
      throw error as ApiError;
    }
    throw {
      message: error instanceof Error ? error.message : 'Неизвестная ошибка при генерации отчёта',
      status: 0,
      statusText: 'Network Error'
    } as ApiError;
  }
}

/**
 * Генерирует предпросмотр отчёта (первая страница в PDF).
 *
 * @param reportId идентификатор отчёта
 * @param parameters параметры отчёта
 * @returns Promise с Blob содержимым preview
 * @throws {ApiError} при ошибке запроса
 */
export async function generatePreview(
  reportId: string,
  parameters?: Record<string, unknown>
): Promise<Blob> {
  const url = `${REPORTS_API_BASE}/${reportId}/preview`;
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(parameters || {})
    });

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage = errorText;
      
      try {
        const errorJson = JSON.parse(errorText);
        errorMessage = errorJson.message || errorJson.error || errorText;
      } catch {
        // Если не JSON, используем текст как есть
      }

      throw {
        message: errorMessage,
        status: response.status,
        statusText: response.statusText
      } as ApiError;
    }

    const blob = await response.blob();
    return blob;
  } catch (error) {
    if (error && typeof error === 'object' && 'message' in error) {
      throw error as ApiError;
    }
    throw {
      message: error instanceof Error ? error.message : 'Неизвестная ошибка при генерации preview',
      status: 0,
      statusText: 'Network Error'
    } as ApiError;
  }
}

/**
 * Получает список всех категорий отчётов.
 *
 * @returns Promise со списком категорий
 * @throws {ApiError} при ошибке запроса
 */
export async function getCategories(): Promise<string[]> {
  return apiGet<string[]>(`${REPORTS_API_BASE}/categories`);
}

/**
 * Получает список всех тегов отчётов.
 *
 * @returns Promise со списком тегов
 * @throws {ApiError} при ошибке запроса
 */
export async function getTags(): Promise<string[]> {
  return apiGet<string[]>(`${REPORTS_API_BASE}/tags`);
}

/**
 * Загружает опции для параметра из внешнего API.
 *
 * @param reportId идентификатор отчёта
 * @param parameterName имя параметра
 * @returns Promise со списком опций в формате {value, label}
 * @throws {ApiError} при ошибке запроса
 */
export async function getParameterSource(
  reportId: string,
  parameterName: string
): Promise<Array<{ value: string | number; label: string }>> {
  return apiGet<Array<{ value: string | number; label: string }>>(
    `${REPORTS_API_BASE}/parameters/source/${reportId}/${parameterName}`
  );
}

export type { ApiError };
