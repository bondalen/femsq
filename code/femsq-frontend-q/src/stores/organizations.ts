import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { RequestError } from '@/api/http';
import type { OrganizationDto as ApiOrganizationDto } from '@/types/files';
import {
  getAgentsByOrganization,
  getOrganizationsPage
} from '@/api/organizations-api';

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

const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 10;
const DEFAULT_SORT = 'ogName,asc';

function formatNullableNumber(value?: number | null): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  return Number.isInteger(value) ? String(value) : value.toString();
}

function mapOrganization(dto: ApiOrganizationDto): Organization {
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
      const ogNameFilter = filters.ogName.trim();
      const zeroBasedPage = Math.max(pagination.page - 1, 0);

      const query = {
        page: zeroBasedPage,
        size: pagination.size,
        sort: pagination.sort,
        ogName: ogNameFilter.length > 0 ? ogNameFilter : undefined
      };

      console.info('[organizations-store] Fetching organizations (GraphQL) with query:', query);
      const page = await getOrganizationsPage(query);
      console.info('[organizations-store] Page meta:', {
        totalElements: page.totalElements,
        totalPages: page.totalPages,
        page: page.page,
        size: page.size
      });

      const content = page.content ?? [];
      organizations.value = content.map(mapOrganization);

      pagination.totalElements = page.totalElements;
      pagination.totalPages = page.totalPages;
      if (page.totalPages > 0) {
        pagination.page = Math.max(Math.min(page.page + 1, page.totalPages), 1);
      } else {
        pagination.page = DEFAULT_PAGE;
      }

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
      const response = await getAgentsByOrganization(ogKey);
      const mappedAgents = response.map(mapAgent);

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
