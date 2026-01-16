/**
 * API клиент для работы с организациями (og)
 * Используется для lookup отправителя в файлах
 */

import type { OrganizationDto, OrganizationLookupDto } from '@/types/files'
import { http } from './http'

/**
 * Получить все организации
 */
export async function getAllOrganizations(): Promise<OrganizationDto[]> {
  const response = await http.get<OrganizationDto[]>('/api/og')
  return response.data
}

/**
 * Получить организацию по ID
 */
export async function getOrganizationById(id: number): Promise<OrganizationDto> {
  const response = await http.get<OrganizationDto>(`/api/og/${id}`)
  return response.data
}

/**
 * Получить организации для lookup (упрощенная версия)
 * Возвращает только ogKey и ogNm для использования в select
 */
export async function getOrganizationsLookup(): Promise<OrganizationLookupDto[]> {
  const response = await http.get<OrganizationDto[]>('/api/og')
  // Преобразуем в упрощенный формат для lookup
  return response.data.map(org => ({
    ogKey: org.ogKey,
    ogNm: org.ogNm
  }))
}
