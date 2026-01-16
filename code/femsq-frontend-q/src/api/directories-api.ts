/**
 * API клиент для работы с директориями ревизий
 */

import type { DirectoryDto } from '@/types/files'
import { apiGet } from './http'

/**
 * Получить все директории
 */
export async function getAllDirectories(): Promise<DirectoryDto[]> {
  return apiGet<DirectoryDto[]>('/api/ra/directories')
}

/**
 * Получить директорию по ID
 */
export async function getDirectoryById(id: number): Promise<DirectoryDto> {
  return apiGet<DirectoryDto>(`/api/ra/directories/${id}`)
}

/**
 * Получить директорию для ревизии (связь 1:1)
 */
export async function getDirectoryByAuditId(auditId: number): Promise<DirectoryDto> {
  return apiGet<DirectoryDto>(`/api/ra/audits/${auditId}/directory`)
}
