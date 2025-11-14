import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { apiGet, RequestError } from '@/api/http';

export interface OrganizationDto {
  ogKey: number;
  ogName: string;
  ogOfficialName?: string | null;
  ogFullName?: string | null;
  ogDescription?: string | null;
  inn?: number | null;
  kpp?: number | null;
  ogrn?: number | null;
  okpo?: number | null;
  oe?: number | null;
  registrationTaxType?: string | null;
}

export interface AgentDto {
  ogAgKey: number;
  code: string;
  organizationKey: number;
  legacyOid?: string | null;
}

export interface Organization {
  ogKey: number;
  ogName: string;
  ogFullName?: string | null;
  ogOfficialName?: string | null;
  ogDescription?: string | null;
  inn?: string | null;
  kpp?: string | null;
  ogrn?: string | null;
  okpo?: string | null;
  oe?: number | null;
  registrationTaxType?: string | null;
  ogAgCount: number;
}

export interface Agent {
  ogAgKey: number;
  code: string;
  organizationKey: number;
  legacyOid?: string | null;
}

interface PageResponse<T> {
  content: T[];
  totalElements?: number;
  totalPages?: number;
  page?: number;
  number?: number;
  size?: number;
}

type OrganizationsResponse = OrganizationDto[] | PageResponse<OrganizationDto>;

type AgentsResponse = AgentDto[] | PageResponse<AgentDto>;

const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 10;
const DEFAULT_SORT = 'ogName,asc';

function formatNullableNumber(value?: number | null): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  return Number.isInteger(value) ? String(value) : value.toString();
}

function mapOrganization(dto: OrganizationDto): Organization {
  return {
    ogKey: dto.ogKey,
    ogName: dto.ogName,
    ogFullName: dto.ogFullName ?? null,
    ogOfficialName: dto.ogOfficialName ?? null,
    ogDescription: dto.ogDescription ?? null,
    inn: formatNullableNumber(dto.inn),
    kpp: formatNullableNumber(dto.kpp),
    ogrn: formatNullableNumber(dto.ogrn),
    okpo: formatNullableNumber(dto.okpo),
    oe: dto.oe ?? null,
    registrationTaxType: dto.registrationTaxType ?? null,
    ogAgCount: 0
  };
}

function mapAgent(dto: AgentDto): Agent {
  return {
    ogAgKey: dto.ogAgKey,
    code: dto.code ?? '',
    organizationKey: dto.organizationKey,
    legacyOid: dto.legacyOid ?? null
  };
}

function normalizeResponse<T>(response: T[] | PageResponse<T>): PageResponse<T> {
  if (Array.isArray(response)) {
    return {
      content: response,
      totalElements: response.length,
      totalPages: 1,
      page: 0,
      size: response.length
    };
  }
  return response;
}

export const useOrganizationsStore = defineStore('organizations', () => {
  const organizations = ref<Organization[]>([]);
  const selectedOrganizationKey = ref<number | null>(null);
  const agents = ref<Agent[]>([]);

  const loading = ref(false);
  const agentsLoading = ref(false);
  const error = ref<string | null>(null);
  const agentsError = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const pagination = reactive({
    page: DEFAULT_PAGE,
    size: DEFAULT_PAGE_SIZE,
    totalElements: 0,
    totalPages: 0,
    sort: DEFAULT_SORT
  });

  const filters = reactive({
    ogName: ''
  });

  const selectedOrganization = computed<Organization | null>(() => {
    if (selectedOrganizationKey.value === null) {
      return null;
    }
    return organizations.value.find((item) => item.ogKey === selectedOrganizationKey.value) ?? null;
  });

  const hasOrganizations = computed(() => organizations.value.length > 0);

  async function fetchOrganizations(options: { keepSelection?: boolean } = {}): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    const previousSelection = options.keepSelection ? selectedOrganizationKey.value : null;

    try {
      const query: Record<string, unknown> = {
        page: Math.max(pagination.page - 1, 0),
        size: pagination.size,
        sort: pagination.sort
      };
      if (filters.ogName.trim().length > 0) {
        query.ogName = filters.ogName.trim();
      }

      // Преобразуем поле сортировки из frontend формата (ogName) в backend формат (ogNm)
      if (query.sort && typeof query.sort === 'string') {
        query.sort = query.sort.replace(/^ogName/, 'ogNm');
      }

      console.info('[organizations-store] Fetching organizations with query:', query);
      const response = await apiGet<OrganizationsResponse>('/api/v1/organizations', { query });
      console.info('[organizations-store] Received response type:', Array.isArray(response) ? 'array' : 'object', 'length/keys:', Array.isArray(response) ? response.length : Object.keys(response));
      const normalized = normalizeResponse(response);
      console.info('[organizations-store] Normalized response:', { contentLength: normalized.content?.length, totalElements: normalized.totalElements, totalPages: normalized.totalPages, page: normalized.page, size: normalized.size });

      const content = normalized.content ?? [];
      organizations.value = content.map(mapOrganization);

      pagination.totalElements = normalized.totalElements ?? organizations.value.length;
      pagination.totalPages = normalized.totalPages ?? (organizations.value.length > 0 ? 1 : 0);
      if (typeof normalized.page === 'number' || typeof normalized.number === 'number') {
        const pageIndex = (normalized.page ?? normalized.number ?? 0) + 1;
        pagination.page = Math.max(pageIndex, 1);
      } else if (pagination.page > pagination.totalPages && pagination.totalPages > 0) {
        pagination.page = pagination.totalPages;
      }
      // Не перезаписываем pagination.size из ответа - размер страницы управляется пользователем

      lastUpdatedAt.value = new Date().toISOString();

      const nextSelection = (() => {
        if (organizations.value.length === 0) {
          return null;
        }
        if (previousSelection !== null && organizations.value.some((item) => item.ogKey === previousSelection)) {
          return previousSelection;
        }
        return organizations.value[0]?.ogKey ?? null;
      })();

      selectedOrganizationKey.value = nextSelection;

      if (nextSelection !== null) {
        await fetchAgentsFor(nextSelection, { force: true });
      } else {
        agents.value = [];
      }
    } catch (err) {
      console.error('[organizations-store] Error in fetchOrganizations:', err);
      const message = err instanceof RequestError 
        ? err.message 
        : err instanceof Error 
          ? err.message 
          : 'Не удалось загрузить организации';
      error.value = message;
      organizations.value = [];
      selectedOrganizationKey.value = null;
      agents.value = [];
      pagination.totalElements = 0;
      pagination.totalPages = 0;
      throw err; // Пробрасываем ошибку для логирования в компонентах
    } finally {
      loading.value = false;
    }
  }

  async function fetchAgentsFor(ogKey: number, options: { force?: boolean } = {}): Promise<void> {
    if (!options.force && selectedOrganizationKey.value !== ogKey) {
      return;
    }

    agentsLoading.value = true;
    agentsError.value = null;

    try {
      const response = await apiGet<AgentsResponse>(`/api/v1/organizations/${ogKey}/agents`);
      const normalized = normalizeResponse(response);
      const mappedAgents = normalized.content.map(mapAgent);

      if (selectedOrganizationKey.value !== ogKey) {
        return;
      }

      agents.value = mappedAgents;
      const index = organizations.value.findIndex((item) => item.ogKey === ogKey);
      if (index >= 0) {
        organizations.value[index] = {
          ...organizations.value[index],
          ogAgCount: mappedAgents.length
        };
      }
    } catch (err) {
      const message = err instanceof RequestError ? err.message : 'Не удалось загрузить список агентских организаций';
      agentsError.value = message;
      agents.value = [];
    } finally {
      agentsLoading.value = false;
    }
  }

  async function selectOrganization(ogKey: number): Promise<void> {
    if (selectedOrganizationKey.value === ogKey && agents.value.length > 0 && !agentsError.value) {
      return;
    }
    selectedOrganizationKey.value = ogKey;
    await fetchAgentsFor(ogKey, { force: true });
  }

  async function setPage(page: number): Promise<void> {
    const nextPage = Math.max(Number(page), 1);
    if (pagination.page === nextPage) {
      return;
    }
    pagination.page = nextPage;
    await fetchOrganizations({ keepSelection: true });
  }

  async function setPageSize(size: number): Promise<void> {
    const numSize = Number(size);
    if (isNaN(numSize) || numSize <= 0) {
      console.error('[organizations-store] Invalid page size:', size);
      return;
    }
    if (pagination.size === numSize) {
      return;
    }
    pagination.size = numSize;
    pagination.page = DEFAULT_PAGE;
    await fetchOrganizations({ keepSelection: false });
  }

  async function setSort(sort: string): Promise<void> {
    if (pagination.sort === sort) {
      return;
    }
    pagination.sort = sort;
    pagination.page = DEFAULT_PAGE;
    await fetchOrganizations({ keepSelection: true });
  }

  async function updateNameFilter(value: string): Promise<void> {
    if (filters.ogName === value) {
      return;
    }
    filters.ogName = value;
    pagination.page = DEFAULT_PAGE;
    await fetchOrganizations({ keepSelection: false });
  }

  function reset(): void {
    organizations.value = [];
    selectedOrganizationKey.value = null;
    agents.value = [];
    loading.value = false;
    agentsLoading.value = false;
    error.value = null;
    agentsError.value = null;
    lastUpdatedAt.value = '';
    pagination.page = DEFAULT_PAGE;
    pagination.size = DEFAULT_PAGE_SIZE;
    pagination.totalElements = 0;
    pagination.totalPages = 0;
    pagination.sort = DEFAULT_SORT;
    filters.ogName = '';
  }

  return {
    organizations,
    selectedOrganizationKey,
    selectedOrganization,
    agents,
    loading,
    agentsLoading,
    error,
    agentsError,
    lastUpdatedAt,
    pagination,
    filters,
    hasOrganizations,
    fetchOrganizations,
    fetchAgentsFor,
    selectOrganization,
    setPage,
    setPageSize,
    setSort,
    updateNameFilter,
    reset
  };
});
