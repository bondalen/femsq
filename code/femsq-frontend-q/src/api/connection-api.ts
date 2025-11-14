/**
 * API клиент для работы с подключением к базе данных.
 */

import { apiGet, apiPost } from './http';
import type { RequestError } from './http';

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

export type ApiError = RequestError;

/**
 * Получает текущий статус подключения к базе данных.
 */
export async function getConnectionStatus(): Promise<ConnectionStatusResponse> {
  return apiGet<ConnectionStatusResponse>('/api/v1/connection/status');
}

/**
 * Тестирует подключение к базе данных без сохранения конфигурации.
 */
export async function testConnection(request: ConnectionTestRequest): Promise<ConnectionStatusResponse> {
  return apiPost<ConnectionStatusResponse>('/api/v1/connection/test', request);
}

/**
 * Применяет новую конфигурацию подключения и переподключается к базе данных.
 */
export async function applyConnection(request: ConnectionTestRequest): Promise<ConnectionStatusResponse> {
  return apiPost<ConnectionStatusResponse>('/api/v1/connection/apply', request);
}

/**
 * Получает текущую конфигурацию подключения (без пароля).
 */
export async function getConnectionConfig(): Promise<ConnectionConfigResponse> {
  return apiGet<ConnectionConfigResponse>('/api/v1/connection/config');
}


