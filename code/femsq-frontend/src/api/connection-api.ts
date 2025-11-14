/**
 * API клиент для работы с подключением к базе данных.
 */

import { apiGet, apiPost, type ApiError } from './http-client';

export interface ConnectionTestRequest {
  host: string;
  port: number;
  database: string;
  schema?: string;
  username?: string;
  password?: string;
  authMode: 'credentials' | 'windows-integrated' | 'kerberos';
}

export interface ConnectionStatusResponse {
  connected: boolean;
  schema?: string;
  database?: string;
  message?: string;
  error?: string;
}

export interface ConnectionConfigResponse {
  host?: string;
  port?: number;
  database?: string;
  schema?: string;
  username?: string;
  authMode?: string;
}

/**
 * Получает текущий статус подключения к базе данных.
 *
 * @returns Promise с информацией о статусе подключения
 * @throws {ApiError} при ошибке запроса
 */
export async function getConnectionStatus(): Promise<ConnectionStatusResponse> {
  return apiGet<ConnectionStatusResponse>('/connection/status');
}

/**
 * Тестирует подключение к базе данных без сохранения конфигурации.
 *
 * @param request параметры подключения для тестирования
 * @returns Promise с результатом тестирования
 * @throws {ApiError} при ошибке запроса или валидации
 */
export async function testConnection(request: ConnectionTestRequest): Promise<ConnectionStatusResponse> {
  return apiPost<ConnectionStatusResponse>('/connection/test', request);
}

/**
 * Применяет новую конфигурацию подключения и переподключается к базе данных.
 *
 * @param request параметры подключения для применения
 * @returns Promise с результатом применения конфигурации
 * @throws {ApiError} при ошибке запроса или валидации
 */
export async function applyConnection(request: ConnectionTestRequest): Promise<ConnectionStatusResponse> {
  return apiPost<ConnectionStatusResponse>('/connection/apply', request);
}

/**
 * Получает текущую конфигурацию подключения (без пароля).
 *
 * @returns Promise с текущей конфигурацией
 * @throws {ApiError} при ошибке запроса или отсутствии конфигурации
 */
export async function getConnectionConfig(): Promise<ConnectionConfigResponse> {
  return apiGet<ConnectionConfigResponse>('/connection/config');
}

export type { ApiError };


