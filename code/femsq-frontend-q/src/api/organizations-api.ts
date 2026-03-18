/**
 * API клиент для работы с организациями (для lookup в файлах)
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { OrganizationDto, OrganizationLookupDto } from '@/types/files';

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

const GET_ORGANIZATIONS = gql`
  query GetOrganizations {
    organizations {
      ogKey
      ogName
      ogOfficialName
      ogFullName
      ogDescription
      inn
      kpp
      ogrn
      okpo
      oe
      registrationTaxType
    }
  }
`;

const GET_ORGANIZATIONS_LOOKUP = gql`
  query GetOrganizationsLookup {
    organizations {
      ogKey
      ogName
    }
  }
`;

/**
 * Получить все организации
 */
export async function getAllOrganizations(): Promise<OrganizationDto[]> {
  try {
    const result = await apolloClient.query<{ organizations: OrganizationDto[] }>({
      query: GET_ORGANIZATIONS,
      fetchPolicy: 'network-only'
    });
    return result.data.organizations;
  } catch (error) {
    throw wrapApolloError(error, 'GetOrganizations');
  }
}

export interface OrganizationsQuery {
  /**
   * Номер страницы (0‑based, как в backend Page).
   */
  page: number;

  /**
   * Размер страницы (количество элементов на страницу).
   */
  size: number;

  /**
   * Строка сортировки в формате `поле,направление`, например `ogName,asc`.
   */
  sort: string;

  /**
   * Фильтр по краткому названию организации (ogName), подстрочное совпадение.
   */
  ogName?: string;
}

export interface OrganizationsPage {
  content: OrganizationDto[];
  totalElements: number;
  totalPages: number;
  page: number;
  size: number;
}

/**
 * Клиентская пагинация и фильтрация по организациям.
 *
 * Backend GraphQL (`organizations`) возвращает полный список без метаданных пагинации,
 * поэтому пагинация/фильтрация/сортировка реализуются на клиенте для сохранения
 * текущего UX (страницы, сортировка, поиск по ogName).
 */
export async function getOrganizationsPage(query: OrganizationsQuery): Promise<OrganizationsPage> {
  const all = await getAllOrganizations();

  // Фильтрация по ogName (подстрочное, регистронезависимое)
  const filtered = (() => {
    if (!query.ogName || !query.ogName.trim()) {
      return all;
    }
    const needle = query.ogName.trim().toLowerCase();
    return all.filter((org) => org.ogName.toLowerCase().includes(needle));
  })();

  // Сортировка: поддерживаем ogName,asc|desc
  const sorted = (() => {
    const [field, directionRaw] = query.sort.split(',');
    const direction = directionRaw === 'desc' ? -1 : 1;

    if (field === 'ogName') {
      return [...filtered].sort((a, b) => {
        const aName = a.ogName ?? '';
        const bName = b.ogName ?? '';
        return aName.localeCompare(bName) * direction;
      });
    }

    // Если поле неизвестно — возвращаем без сортировки
    return filtered;
  })();

  const size = query.size > 0 ? query.size : sorted.length || 1;
  const totalElements = sorted.length;
  const totalPages = totalElements === 0 ? 0 : Math.ceil(totalElements / size);

  const maxPageIndex = Math.max(totalPages - 1, 0);
  const page = Math.min(Math.max(query.page, 0), maxPageIndex);

  const start = page * size;
  const end = start + size;
  const pageContent = sorted.slice(start, end);

  return {
    content: pageContent,
    totalElements,
    totalPages,
    page,
    size
  };
}

export interface AgentDto {
  ogAgKey: number;
  code: string;
  organizationKey: number;
  legacyOid?: string | null;
}

/**
 * Получить список контактных лиц (агентов) организации.
 */
export async function getAgentsByOrganization(organizationKey: number): Promise<AgentDto[]> {
  const GET_ORGANIZATION_AGENTS = gql`
    query GetOrganizationAgents($organizationId: Int!) {
      organizationAgents(organizationId: $organizationId) {
        ogAgKey
        code
        organizationKey
        legacyOid
      }
    }
  `;

  try {
    const result = await apolloClient.query<{
      organizationAgents: AgentDto[];
    }>({
      query: GET_ORGANIZATION_AGENTS,
      variables: { organizationId: organizationKey },
      fetchPolicy: 'network-only'
    });

    return result.data.organizationAgents ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetOrganizationAgents');
  }
}

/**
 * Получить организацию по ID
 */
export async function getOrganizationById(id: number): Promise<OrganizationDto> {
  // В GraphQL-схеме есть query organization(id), используем её напрямую.
  const GET_ORGANIZATION = gql`
    query GetOrganization($id: Int!) {
      organization(id: $id) {
        ogKey
        ogName
        ogOfficialName
        ogFullName
        ogDescription
        inn
        kpp
        ogrn
        okpo
        oe
        registrationTaxType
      }
    }
  `;

  try {
    const result = await apolloClient.query<{ organization: OrganizationDto | null }>({
      query: GET_ORGANIZATION,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    if (!result.data.organization) {
      throw new RequestError('Организация не найдена', {
        status: 404,
        statusText: 'Not Found',
        url: '/graphql',
        body: { id }
      });
    }
    return result.data.organization;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw wrapApolloError(error, 'GetOrganization');
  }
}

/**
 * Получить организации в формате для lookup (select)
 * Возвращает только ogKey и ogNm для использования в select
 */
export async function getOrganizationsLookup(): Promise<OrganizationLookupDto[]> {
  try {
    const result = await apolloClient.query<{ organizations: Pick<OrganizationDto, 'ogKey' | 'ogName'>[] }>({
      query: GET_ORGANIZATIONS_LOOKUP,
      fetchPolicy: 'network-only'
    });
    return result.data.organizations.map((org) => ({
      ogKey: org.ogKey,
      ogNm: org.ogName
    }));
  } catch (error) {
    throw wrapApolloError(error, 'GetOrganizationsLookup');
  }
}
