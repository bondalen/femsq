/**
 * HTTP клиент для работы с REST API backend.
 */

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1';

export interface ApiError {
  message: string;
  status?: number;
  statusText?: string;
}

/**
 * Выполняет GET запрос к API.
 *
 * @param endpoint путь к endpoint (без базового URL)
 * @returns Promise с данными ответа
 * @throws {ApiError} при ошибке запроса
 */
export async function apiGet<T = unknown>(endpoint: string): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
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

    // Если ответ пустой, возвращаем null
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      return null as T;
    }

    const data = await response.json();
    return data as T;
  } catch (error) {
    if (error && typeof error === 'object' && 'message' in error) {
      throw error as ApiError;
    }
    throw {
      message: error instanceof Error ? error.message : 'Неизвестная ошибка при выполнении запроса',
      status: 0,
      statusText: 'Network Error'
    } as ApiError;
  }
}

/**
 * Выполняет POST запрос к API.
 *
 * @param endpoint путь к endpoint (без базового URL)
 * @param body тело запроса (будет сериализовано в JSON)
 * @returns Promise с данными ответа
 * @throws {ApiError} при ошибке запроса
 */
export async function apiPost<T = unknown>(endpoint: string, body?: unknown): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: body ? JSON.stringify(body) : undefined
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

    // Если ответ пустой, возвращаем null
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      return null as T;
    }

    const data = await response.json();
    return data as T;
  } catch (error) {
    if (error && typeof error === 'object' && 'message' in error) {
      throw error as ApiError;
    }
    throw {
      message: error instanceof Error ? error.message : 'Неизвестная ошибка при выполнении запроса',
      status: 0,
      statusText: 'Network Error'
    } as ApiError;
  }
}


