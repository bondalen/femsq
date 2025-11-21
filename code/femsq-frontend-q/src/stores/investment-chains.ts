import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { apiGet, RequestError } from '@/api/http';

export interface IpgChainDto {
  chainKey: number;
  name: string;
  stNetKey?: number | null;
  stNetName?: string | null;
  latestIpgKey?: number | null;
  year?: number | null;
}

export interface IpgChainRelationDto {
  relationKey: number;
  chainKey: number;
  investmentProgramKey: number;
  investmentProgramName?: string | null;
  planGroupKey?: number | null;
  planGroupName?: string | null;
}

export interface InvestmentChain {
  chainKey: number;
  name: string;
  stNetKey?: number | null;
  stNetName?: string | null;
  latestIpgKey?: number | null;
  year?: number | null;
  relationsCount: number;
}

export interface InvestmentChainRelation {
  relationKey: number;
  chainKey: number;
  investmentProgramKey: number;
  investmentProgramName?: string | null;
  planGroupKey?: number | null;
  planGroupName?: string | null;
}

interface PageResponse<T> {
  content: T[];
  totalElements?: number;
  totalPages?: number;
  page?: number;
  number?: number;
  size?: number;
}

type InvestmentChainsResponse = IpgChainDto[] | PageResponse<IpgChainDto>;
type InvestmentChainRelationsResponse = IpgChainRelationDto[] | PageResponse<IpgChainRelationDto>;

const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 10;
const DEFAULT_SORT = 'ipgcKey,asc';

function mapInvestmentChain(dto: IpgChainDto): InvestmentChain {
  return {
    chainKey: dto.chainKey,
    name: dto.name,
    stNetKey: dto.stNetKey ?? null,
    stNetName: dto.stNetName ?? null,
    latestIpgKey: dto.latestIpgKey ?? null,
    year: dto.year ?? null,
    relationsCount: 0
  };
}

function mapInvestmentChainRelation(dto: IpgChainRelationDto): InvestmentChainRelation {
  return {
    relationKey: dto.relationKey,
    chainKey: dto.chainKey,
    investmentProgramKey: dto.investmentProgramKey,
    investmentProgramName: dto.investmentProgramName ?? null,
    planGroupKey: dto.planGroupKey ?? null,
    planGroupName: dto.planGroupName ?? null
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

export const useInvestmentChainsStore = defineStore('investmentChains', () => {
  const chains = ref<InvestmentChain[]>([]);
  const selectedChainKey = ref<number | null>(null);
  const relations = ref<InvestmentChainRelation[]>([]);

  const loading = ref(false);
  const relationsLoading = ref(false);
  const error = ref<string | null>(null);
  const relationsError = ref<string | null>(null);
  const lastUpdatedAt = ref<string>('');

  const pagination = reactive({
    page: DEFAULT_PAGE,
    size: DEFAULT_PAGE_SIZE,
    totalElements: 0,
    totalPages: 0,
    sort: DEFAULT_SORT
  });

  const filters = reactive({
    name: '',
    year: null as number | null
  });

  const selectedChain = computed<InvestmentChain | null>(() => {
    if (selectedChainKey.value === null) {
      return null;
    }
    return chains.value.find((item) => item.chainKey === selectedChainKey.value) ?? null;
  });

  const hasChains = computed(() => chains.value.length > 0);

  async function fetchChains(options: { keepSelection?: boolean } = {}): Promise<void> {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;

    const previousSelection = options.keepSelection ? selectedChainKey.value : null;

    try {
      const query: Record<string, unknown> = {
        page: Math.max(pagination.page - 1, 0),
        size: pagination.size,
        sort: pagination.sort
      };
      if (filters.name.trim().length > 0) {
        query.name = filters.name.trim();
      }
      if (filters.year !== null) {
        query.year = filters.year;
      }

      // Преобразуем поле сортировки из frontend формата (name) в backend формат (ipgcName)
      if (query.sort && typeof query.sort === 'string') {
        query.sort = query.sort.replace(/^name/, 'ipgcName').replace(/^chainKey/, 'ipgcKey');
      }

      console.info('[investment-chains-store] Fetching chains with query:', query);
      const response = await apiGet<InvestmentChainsResponse>('/api/v1/ipg-chains', { query });
      console.info('[investment-chains-store] Received response type:', Array.isArray(response) ? 'array' : 'object', 'length/keys:', Array.isArray(response) ? response.length : Object.keys(response));
      const normalized = normalizeResponse(response);
      console.info('[investment-chains-store] Normalized response:', { contentLength: normalized.content?.length, totalElements: normalized.totalElements, totalPages: normalized.totalPages, page: normalized.page, size: normalized.size });

      const content = normalized.content ?? [];
      chains.value = content.map(mapInvestmentChain);

      pagination.totalElements = normalized.totalElements ?? chains.value.length;
      pagination.totalPages = normalized.totalPages ?? (chains.value.length > 0 ? 1 : 0);
      if (typeof normalized.page === 'number' || typeof normalized.number === 'number') {
        const pageIndex = (normalized.page ?? normalized.number ?? 0) + 1;
        pagination.page = Math.max(pageIndex, 1);
      } else if (pagination.page > pagination.totalPages && pagination.totalPages > 0) {
        pagination.page = pagination.totalPages;
      }

      lastUpdatedAt.value = new Date().toISOString();

      const nextSelection = (() => {
        if (chains.value.length === 0) {
          return null;
        }
        if (previousSelection !== null && chains.value.some((item) => item.chainKey === previousSelection)) {
          return previousSelection;
        }
        return chains.value[0]?.chainKey ?? null;
      })();

      selectedChainKey.value = nextSelection;

      if (nextSelection !== null) {
        await fetchRelationsFor(nextSelection, { force: true });
      } else {
        relations.value = [];
      }
    } catch (err) {
      console.error('[investment-chains-store] Error in fetchChains:', err);
      const message = err instanceof RequestError 
        ? err.message 
        : err instanceof Error 
          ? err.message 
          : 'Не удалось загрузить цепочки инвестиционных программ';
      error.value = message;
      chains.value = [];
      selectedChainKey.value = null;
      relations.value = [];
      pagination.totalElements = 0;
      pagination.totalPages = 0;
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchRelationsFor(chainKey: number, options: { force?: boolean } = {}): Promise<void> {
    if (!options.force && selectedChainKey.value !== chainKey) {
      return;
    }

    relationsLoading.value = true;
    relationsError.value = null;

    try {
      const response = await apiGet<InvestmentChainRelationsResponse>(`/api/v1/ipg-chains/${chainKey}/relations`);
      const normalized = normalizeResponse(response);
      const mappedRelations = normalized.content.map(mapInvestmentChainRelation);

      if (selectedChainKey.value !== chainKey) {
        return;
      }

      relations.value = mappedRelations;
      const index = chains.value.findIndex((item) => item.chainKey === chainKey);
      if (index >= 0) {
        chains.value[index] = {
          ...chains.value[index],
          relationsCount: mappedRelations.length
        };
      }
    } catch (err) {
      const message = err instanceof RequestError ? err.message : 'Не удалось загрузить связи цепочки';
      relationsError.value = message;
      relations.value = [];
    } finally {
      relationsLoading.value = false;
    }
  }

  async function selectChain(chainKey: number): Promise<void> {
    if (selectedChainKey.value === chainKey && relations.value.length > 0 && !relationsError.value) {
      return;
    }
    selectedChainKey.value = chainKey;
    await fetchRelationsFor(chainKey, { force: true });
  }

  async function setPage(page: number): Promise<void> {
    const nextPage = Math.max(Number(page), 1);
    if (pagination.page === nextPage) {
      return;
    }
    pagination.page = nextPage;
    await fetchChains({ keepSelection: true });
  }

  async function setPageSize(size: number): Promise<void> {
    const numSize = Number(size);
    if (isNaN(numSize) || numSize <= 0) {
      console.error('[investment-chains-store] Invalid page size:', size);
      return;
    }
    if (pagination.size === numSize) {
      return;
    }
    pagination.size = numSize;
    pagination.page = DEFAULT_PAGE;
    await fetchChains({ keepSelection: false });
  }

  async function setSort(sort: string): Promise<void> {
    if (pagination.sort === sort) {
      return;
    }
    pagination.sort = sort;
    pagination.page = DEFAULT_PAGE;
    await fetchChains({ keepSelection: true });
  }

  async function updateNameFilter(value: string): Promise<void> {
    if (filters.name === value) {
      return;
    }
    filters.name = value;
    pagination.page = DEFAULT_PAGE;
    await fetchChains({ keepSelection: false });
  }

  async function updateYearFilter(value: number | null): Promise<void> {
    if (filters.year === value) {
      return;
    }
    filters.year = value;
    pagination.page = DEFAULT_PAGE;
    await fetchChains({ keepSelection: false });
  }

  function reset(): void {
    chains.value = [];
    selectedChainKey.value = null;
    relations.value = [];
    loading.value = false;
    relationsLoading.value = false;
    error.value = null;
    relationsError.value = null;
    lastUpdatedAt.value = '';
    pagination.page = DEFAULT_PAGE;
    pagination.size = DEFAULT_PAGE_SIZE;
    pagination.totalElements = 0;
    pagination.totalPages = 0;
    pagination.sort = DEFAULT_SORT;
    filters.name = '';
    filters.year = null;
  }

  return {
    chains,
    selectedChainKey,
    selectedChain,
    relations,
    loading,
    relationsLoading,
    error,
    relationsError,
    lastUpdatedAt,
    pagination,
    filters,
    hasChains,
    fetchChains,
    fetchRelationsFor,
    selectChain,
    setPage,
    setPageSize,
    setSort,
    updateNameFilter,
    updateYearFilter,
    reset
  };
});
