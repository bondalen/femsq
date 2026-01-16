/**
 * API клиент для работы с директориями (ra_dir)
 */

import type { DirectoryDto } from '@/types/files'
import { http } from './http'

/**
 * Получить все директории
 */
export async function getAllDirectories(): Promise<DirectoryDto[]> {
  const response = await http.get<DirectoryDto[]>('/api/ra/directories')
  return response.data
}

/**
 * Получить директорию по ID
 */
export async function getDirectoryById(id: number): Promise<DirectoryDto> {
  const response = await http.get<DirectoryDto>(`/api/ra/directories/${id}`)
  return response.data
}

/**
 * Получить директорию по ID ревизии (связь 1:1)
 * В форме ревизии всегда одна директория
 */
export async function getDirectoryByAuditId(auditId: number): Promise<DirectoryDto> {
  const response = await http.get<DirectoryDto>(`/api/ra/audits/${auditId}/directory`)
  return response.data
}
