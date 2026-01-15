/**
 * API клиент для работы с типами ревизий.
 */

import { apiGet, RequestError } from './http';
import type { RaAtDto } from '@/types/audits';

const AUDIT_TYPES_API_BASE = '/api/ra/audit-types';

export type ApiError = RequestError;

/**
 * Получает список всех типов ревизий.
 */
export async function getAuditTypes(): Promise<RaAtDto[]> {
  return apiGet<RaAtDto[]>(AUDIT_TYPES_API_BASE);
}