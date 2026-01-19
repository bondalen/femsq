/**
 * API клиент для работы с директориями ревизий
 */

import type { RaDirDto } from '@/types/audits'
import type { DirectoryDto } from '@/types/files'
import { apiGet } from './http'

/**
 * Получить все директории (возвращает RaDirDto - соответствует backend API)
 */
export async function getDirectories(): Promise<RaDirDto[]> {
  return apiGet<RaDirDto[]>('/api/ra/directories')
}

/**
 * Получить все директории (алиас для совместимости)
 * @deprecated Используйте getDirectories() который возвращает RaDirDto
 */
export async function getAllDirectories(): Promise<DirectoryDto[]> {
  const raDirs = await getDirectories()
  // Адаптер: преобразуем RaDirDto в DirectoryDto для совместимости
  return raDirs.map(dir => ({
    key: dir.key,
    dirName: dir.dirName,
    dir: dir.dir,
    created: dir.dirCreated || null,
    updated: dir.dirUpdated || null
  }))
}

/**
 * Получить директорию по ID
 */
export async function getDirectoryById(id: number): Promise<RaDirDto> {
  return apiGet<RaDirDto>(`/api/ra/directories/${id}`)
}

/**
 * Получить директорию для ревизии (связь 1:1)
 */
export async function getDirectoryByAuditId(auditId: number): Promise<RaDirDto> {
  return apiGet<RaDirDto>(`/api/ra/audits/${auditId}/directory`)
}
