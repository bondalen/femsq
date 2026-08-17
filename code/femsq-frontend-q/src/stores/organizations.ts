import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { RequestError } from '@/api/http';
import type { OrganizationDto as ApiOrganizationDto } from '@/types/files';
import {
  attachOrganizationIds,
  createOrganizationNameVariant,
  createOrganizationWithIds,
  deleteOrganizationNameVariant,
  getAgentsByOrganization,
  getOrganizationIds,
  getOrganizationNameVariants,
  getOrganizationsPage,
  updateOrganizationId,
  type AttachOrganizationIdsInput,
  type CreateOgNmFInput,
  type CreateOrganizationWithIdsInput,
  type OrganizationIdDto,
  type OrganizationNameVariantDto,
  type UpdateOrganizationIdInput
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
  const orgIds = ref<OrganizationIdDto[]>([]);
  const orgIdsLoading = ref(false);
  const orgIdsError = ref<string | null>(null);
  const nameVariants = ref<OrganizationNameVariantDto[]>([]);
  const nameVariantsLoading = ref(false);
  const nameVariantsError = ref<string | null>(null);
  const saving = ref(false);

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

  /** Поколение запроса списка — отбрасываем устаревшие ответы при быстром вводе в поиск. */
  let organizationsFetchSeq = 0;

  async function fetchOrganizations(options: { keepSelection?: boolean } = {}): Promise<void> {
    const seq = ++organizationsFetchSeq;
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
      if (seq !== organizationsFetchSeq) {
        return;
      }
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
        await Promise.all([
          fetchAgentsFor(nextSelection, { force: true }),
          fetchOrgIdsFor(nextSelection),
          fetchNameVariantsFor(nextSelection)
        ]);
      } else {
        agents.value = [];
        orgIds.value = [];
        nameVariants.value = [];
      }
    } catch (err) {
      if (seq !== organizationsFetchSeq) {
        return;
      }
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
      orgIds.value = [];
      nameVariants.value = [];
      pagination.totalElements = 0;
      pagination.totalPages = 0;
      throw err; // Пробрасываем ошибку для логирования в компонентах
    } finally {
      if (seq === organizationsFetchSeq) {
        loading.value = false;
      }
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

  async function fetchOrgIdsFor(ogKey: number): Promise<void> {
    orgIdsLoading.value = true;
    orgIdsError.value = null;
    try {
      const rows = await getOrganizationIds(ogKey);
      if (selectedOrganizationKey.value !== ogKey) {
        return;
      }
      orgIds.value = rows;
    } catch (err) {
      orgIdsError.value =
        err instanceof RequestError ? err.message : 'Не удалось загрузить идентификаторы org_id';
      orgIds.value = [];
    } finally {
      orgIdsLoading.value = false;
    }
  }

  async function fetchNameVariantsFor(ogKey: number): Promise<void> {
    nameVariantsLoading.value = true;
    nameVariantsError.value = null;
    try {
      const rows = await getOrganizationNameVariants(ogKey);
      if (selectedOrganizationKey.value !== ogKey) {
        return;
      }
      nameVariants.value = rows;
    } catch (err) {
      nameVariantsError.value =
        err instanceof RequestError ? err.message : 'Не удалось загрузить варианты имён (ogNmF)';
      nameVariants.value = [];
    } finally {
      nameVariantsLoading.value = false;
    }
  }

  async function selectOrganization(ogKey: number): Promise<void> {
    selectedOrganizationKey.value = ogKey;
    await Promise.all([
      fetchAgentsFor(ogKey, { force: true }),
      fetchOrgIdsFor(ogKey),
      fetchNameVariantsFor(ogKey)
    ]);
  }

  /**
   * Создаёт организацию (+ опционально БУиРГ/ИНН в org_id) и выбирает её в списке.
   */
  async function createWithIds(input: CreateOrganizationWithIdsInput): Promise<Organization | null> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createOrganizationWithIds(input);
      filters.ogName = created.ogName ?? input.ogName;
      pagination.page = DEFAULT_PAGE;
      await fetchOrganizations({ keepSelection: false });
      if (created.ogKey != null) {
        await selectOrganization(created.ogKey);
        const mapped = organizations.value.find((item) => item.ogKey === created.ogKey);
        return mapped ?? mapOrganization(created);
      }
      return mapOrganization(created);
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Не удалось создать организацию';
      return null;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Привязывает БУиРГ/ИНН к выбранной организации.
   */
  async function attachIds(input: Omit<AttachOrganizationIdsInput, 'ogKey'> & { ogKey?: number }): Promise<boolean> {
    const ogKey = input.ogKey ?? selectedOrganizationKey.value;
    if (ogKey == null) {
      orgIdsError.value = 'Выберите организацию';
      return false;
    }
    saving.value = true;
    orgIdsError.value = null;
    try {
      await attachOrganizationIds({
        ogKey,
        buirg: input.buirg ?? null,
        itn: input.itn ?? null,
        itnExt: input.itnExt ?? null
      });
      await fetchOrgIdsFor(ogKey);
      return true;
    } catch (err) {
      orgIdsError.value =
        err instanceof RequestError ? err.message : 'Не удалось привязать идентификаторы';
      return false;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Обновляет строку org_id (например дописывает КПП в org_id_value_t_ext).
   */
  async function updateId(input: UpdateOrganizationIdInput): Promise<boolean> {
    saving.value = true;
    orgIdsError.value = null;
    try {
      await updateOrganizationId(input);
      await fetchOrgIdsFor(input.org);
      return true;
    } catch (err) {
      orgIdsError.value =
        err instanceof RequestError ? err.message : 'Не удалось обновить идентификатор';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function addNameVariant(input: Omit<CreateOgNmFInput, 'onfOg'> & { onfOg?: number }): Promise<boolean> {
    const ogKey = input.onfOg ?? selectedOrganizationKey.value;
    if (ogKey == null) {
      nameVariantsError.value = 'Выберите организацию';
      return false;
    }
    saving.value = true;
    nameVariantsError.value = null;
    try {
      await createOrganizationNameVariant({
        onfOg: ogKey,
        onfName: input.onfName,
        onfNameExt: input.onfNameExt ?? null,
        onfStart: input.onfStart ?? null,
        onfEnd: input.onfEnd ?? null
      });
      await fetchNameVariantsFor(ogKey);
      return true;
    } catch (err) {
      nameVariantsError.value =
        err instanceof RequestError ? err.message : 'Не удалось добавить вариант имени';
      return false;
    } finally {
      saving.value = false;
    }
  }

  async function removeNameVariant(onfKey: number): Promise<boolean> {
    const ogKey = selectedOrganizationKey.value;
    saving.value = true;
    nameVariantsError.value = null;
    try {
      await deleteOrganizationNameVariant(onfKey);
      if (ogKey != null) {
        await fetchNameVariantsFor(ogKey);
      }
      return true;
    } catch (err) {
      nameVariantsError.value =
        err instanceof RequestError ? err.message : 'Не удалось удалить вариант имени';
      return false;
    } finally {
      saving.value = false;
    }
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
    orgIds.value = [];
    nameVariants.value = [];
    loading.value = false;
    agentsLoading.value = false;
    orgIdsLoading.value = false;
    nameVariantsLoading.value = false;
    saving.value = false;
    error.value = null;
    agentsError.value = null;
    orgIdsError.value = null;
    nameVariantsError.value = null;
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
    orgIds,
    nameVariants,
    loading,
    agentsLoading,
    orgIdsLoading,
    nameVariantsLoading,
    saving,
    error,
    agentsError,
    orgIdsError,
    nameVariantsError,
    lastUpdatedAt,
    pagination,
    filters,
    hasOrganizations,
    fetchOrganizations,
    selectOrganization,
    createWithIds,
    attachIds,
    updateId,
    addNameVariant,
    removeNameVariant,
    fetchOrgIdsFor,
    fetchNameVariantsFor,
    fetchAgentsFor,
    setPage,
    setPageSize,
    setSort,
    updateNameFilter,
    reset
  };
});
