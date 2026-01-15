/**
 * API клиент для работы с директориями ревизий.
 */

import { apiGet, RequestError } from './http';
import type { RaDirDto } from '@/types/audits';

const DIRECTORIES_API_BASE = '/api/ra/directories';

export type ApiError = RequestError;

/**
 * Получает список всех директорий.
 */
export async function getDirectories(): Promise<RaDirDto[]> {
  return apiGet<RaDirDto[]>(DIRECTORIES_API_BASE);
}