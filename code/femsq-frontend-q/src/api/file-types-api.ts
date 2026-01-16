/**
 * API клиент для работы со справочником типов файлов (ra_ft)
 * Используется для lookup в UI (выпадающие списки)
 */

import type { RaFtDto } from '@/types/files'
import { http } from './http'

/**
 * Получить все типы файлов для использования в lookup
 */
export async function getAllFileTypes(): Promise<RaFtDto[]> {
  const response = await http.get<RaFtDto[]>('/api/ra/file-types')
  return response.data
}

/**
 * Получить тип файла по ID
 */
export async function getFileTypeById(id: number): Promise<RaFtDto> {
  const response = await http.get<RaFtDto>(`/api/ra/file-types/${id}`)
  return response.data
}
