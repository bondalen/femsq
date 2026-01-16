/**
 * API клиент для работы с файлами ревизий
 */

import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files'
import { apiGet, apiPost, apiPut, apiDelete } from './http'

/**
 * Получить все файлы
 */
export async function getAllFiles(): Promise<RaFDto[]> {
  return apiGet<RaFDto[]>('/api/ra/files')
}

/**
 * Получить файл по ID
 */
export async function getFileById(id: number): Promise<RaFDto> {
  return apiGet<RaFDto>(`/api/ra/files/${id}`)
}

/**
 * Получить файлы по директории
 */
export async function getFilesByDirId(dirId: number): Promise<RaFDto[]> {
  return apiGet<RaFDto[]>(`/api/ra/directories/${dirId}/files`)
}

/**
 * Создать файл
 */
export async function createFile(data: RaFCreateRequest): Promise<RaFDto> {
  return apiPost<RaFDto>('/api/ra/files', data)
}

/**
 * Обновить файл
 */
export async function updateFile(id: number, data: RaFUpdateRequest): Promise<RaFDto> {
  return apiPut<RaFDto>(`/api/ra/files/${id}`, data)
}

/**
 * Удалить файл
 */
export async function deleteFile(id: number): Promise<void> {
  await apiDelete(`/api/ra/files/${id}`)
}
