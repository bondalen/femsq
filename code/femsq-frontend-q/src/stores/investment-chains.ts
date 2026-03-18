import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

import { RequestError } from '@/api/http';
import type {
  IpgChainDto,
  IpgChainRelationDto,
  InvestmentChainsQuery
} from '@/api/investment-chains-api';
import {
  getInvestmentChainRelations,
  getInvestmentChainsPage
} from '@/api/investment-chains-api';

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
      const zeroBasedPage = Math.max(pagination.page - 1, 0);
      const query: InvestmentChainsQuery = {
        page: zeroBasedPage,
        size: pagination.size,
        sort: pagination.sort,
        name: filters.name.trim() || undefined,
        year: filters.year
      };

      console.info('[investment-chains-store] Fetching chains (GraphQL) with query:', query);
      const page = await getInvestmentChainsPage(query);
      console.info('[investment-chains-store] Page meta:', {
        totalElements: page.totalElements,
        totalPages: page.totalPages,
        page: page.page,
        size: page.size
      });

      const content = page.content ?? [];
      chains.value = content.map(mapInvestmentChain);

      pagination.totalElements = page.totalElements;
      pagination.totalPages = page.totalPages;
      if (page.totalPages > 0) {
        pagination.page = Math.max(Math.min(page.page + 1, page.totalPages), 1);
      } else {
        pagination.page = DEFAULT_PAGE;
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
      const response = await getInvestmentChainRelations(chainKey);
      const mappedRelations = response.map(mapInvestmentChainRelation);

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
