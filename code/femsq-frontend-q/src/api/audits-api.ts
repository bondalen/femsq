/**
 * API клиент для работы с ревизиями.
 */

import { apiDelete, apiGet, apiPost, apiPut, RequestError } from './http';
import type { RaACreateRequest, RaADto, RaAUpdateRequest } from '@/types/audits';

const AUDITS_API_BASE = '/api/ra/audits';

export type ApiError = RequestError;

/**
 * Получает список всех ревизий.
 */
export async function getAudits(): Promise<RaADto[]> {
  return apiGet<RaADto[]>(AUDITS_API_BASE);
}

/**
 * Получает ревизию по идентификатору.
 */
export async function getAuditById(id: number): Promise<RaADto> {
  return apiGet<RaADto>(`${AUDITS_API_BASE}/${id}`);
}

/**
 * Создает новую ревизию.
 */
export async function createAudit(request: RaACreateRequest): Promise<RaADto> {
  return apiPost<RaADto>(AUDITS_API_BASE, request);
}

/**
 * Обновляет существующую ревизию.
 */
export async function updateAudit(id: number, request: RaAUpdateRequest): Promise<RaADto> {
  return apiPut<RaADto>(`${AUDITS_API_BASE}/${id}`, request);
}

/**
 * Удаляет ревизию.
 */
export async function deleteAudit(id: number): Promise<void> {
  return apiDelete<void>(`${AUDITS_API_BASE}/${id}`);
}