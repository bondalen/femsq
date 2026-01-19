/**
 * API клиент для работы с организациями (для lookup в файлах)
 */

import type { OrganizationDto, OrganizationLookupDto } from '@/types/files'
import { apiGet } from './http'

/**
 * Получить все организации
 */
export async function getAllOrganizations(): Promise<OrganizationDto[]> {
  return apiGet<OrganizationDto[]>('/api/og')
}

/**
 * Получить организацию по ID
 */
export async function getOrganizationById(id: number): Promise<OrganizationDto> {
  return apiGet<OrganizationDto>(`/api/og/${id}`)
}

/**
 * Получить организации в формате для lookup (select)
 * Возвращает только ogKey и ogNm для использования в select
 */
export async function getOrganizationsLookup(): Promise<OrganizationLookupDto[]> {
  const orgs = await apiGet<OrganizationDto[]>('/api/og')
  // Преобразуем в упрощенный формат для lookup
  // Backend возвращает ogName, преобразуем в ogNm для совместимости
  return orgs.map((org) => ({
    ogKey: org.ogKey,
    ogNm: org.ogName
  }))
}
