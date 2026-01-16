/**
 * API клиент для работы с файлами ревизий (ra_f)
 */

import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files'
import { http } from './http'

/**
 * Получить все файлы
 */
export async function getAllFiles(): Promise<RaFDto[]> {
  const response = await http.get<RaFDto[]>('/api/ra/files')
  return response.data
}

/**
 * Получить файл по ID
 */
export async function getFileById(id: number): Promise<RaFDto> {
  const response = await http.get<RaFDto>(`/api/ra/files/${id}`)
  return response.data
}

/**
 * Получить файлы по директории
 */
export async function getFilesByDirId(dirId: number): Promise<RaFDto[]> {
  const response = await http.get<RaFDto[]>(`/api/ra/directories/${dirId}/files`)
  return response.data
}

/**
 * Создать новый файл
 */
export async function createFile(request: RaFCreateRequest): Promise<RaFDto> {
  const response = await http.post<RaFDto>('/api/ra/files', request)
  return response.data
}

/**
 * Обновить существующий файл
 */
export async function updateFile(id: number, request: RaFUpdateRequest): Promise<RaFDto> {
  const response = await http.put<RaFDto>(`/api/ra/files/${id}`, request)
  return response.data
}

/**
 * Удалить файл
 */
export async function deleteFile(id: number): Promise<void> {
  await http.delete(`/api/ra/files/${id}`)
}
