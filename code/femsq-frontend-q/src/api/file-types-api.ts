/**
 * API клиент для работы со справочником типов файлов (ra_ft)
 */

import type { RaFtDto } from '@/types/files'
import { apiGet } from './http'

/**
 * Получить все типы файлов
 */
export async function getAllFileTypes(): Promise<RaFtDto[]> {
  return apiGet<RaFtDto[]>('/api/ra/file-types')
}

/**
 * Получить тип файла по ID
 */
export async function getFileTypeById(id: number): Promise<RaFtDto> {
  return apiGet<RaFtDto>(`/api/ra/file-types/${id}`)
}
