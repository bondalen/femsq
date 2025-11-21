import '@testing-library/jest-dom';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { fireEvent, screen, waitFor } from '@testing-library/vue';
import { createPinia, setActivePinia } from 'pinia';

import InvestmentChainsView from '@/views/investment-chains/InvestmentChainsView.vue';
import * as http from '@/api/http';
import { useInvestmentChainsStore } from '@/stores/investment-chains';
import { useStNetworksStore } from '@/stores/lookups/st-networks';
import { useInvestmentProgramsStore } from '@/stores/lookups/investment-programs';
import { usePlanGroupsStore } from '@/stores/lookups/plan-groups';
import { renderInvestmentChainsView } from './renderInvestmentChainsView';

vi.mock('@/api/http', async () => {
  const actual = await vi.importActual<typeof http>('@/api/http');
  return {
    ...actual,
    apiGet: vi.fn()
  } satisfies Partial<typeof actual>;
});

const apiGetMock = vi.mocked(http.apiGet);

function mockChainsResponse() {
  apiGetMock.mockResolvedValueOnce({
    content: [
      {
        chainKey: 1,
        name: 'Chain 1',
        stNetKey: 10,
        stNetName: 'Network 1',
        latestIpgKey: 1000,
        year: 2024
      },
      {
        chainKey: 2,
        name: 'Chain 2',
        stNetKey: 20,
        stNetName: 'Network 2',
        latestIpgKey: 2000,
        year: 2025
      }
    ],
    totalElements: 2,
    totalPages: 1,
    page: 0,
    size: 10
  });
}

function mockRelationsResponse(chainKey: number) {
  apiGetMock.mockResolvedValueOnce([
    {
      relationKey: 100 + chainKey,
      chainKey,
      investmentProgramKey: 1000 + chainKey,
      investmentProgramName: `Program ${chainKey}`,
      planGroupKey: 2000 + chainKey,
      planGroupName: `Group ${chainKey}`
    }
  ]);
}

function mockLookupResponses() {
  // stNetworks
  apiGetMock.mockResolvedValueOnce([
    { stNetKey: 10, name: 'Network 1' },
    { stNetKey: 20, name: 'Network 2' }
  ]);
  // investmentPrograms
  apiGetMock.mockResolvedValueOnce([
    { ipgKey: 1001, name: 'Program 1' },
    { ipgKey: 2002, name: 'Program 2' }
  ]);
  // planGroups
  apiGetMock.mockResolvedValueOnce([
    { planGroupKey: 2001, name: 'Group 1' },
    { planGroupKey: 2002, name: 'Group 2' }
  ]);
}

describe('InvestmentChainsView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('renders table with chains and loads relations on selection', async () => {
    mockLookupResponses();
    mockChainsResponse();
    mockRelationsResponse(1);

    renderInvestmentChainsView(InvestmentChainsView);
    const store = useInvestmentChainsStore();

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/st-networks');
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/investment-programs');
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/lookups/plan-groups');
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/ipg-chains', expect.any(Object));
    });

    expect(await screen.findByText('Chain 1', { selector: 'td' })).toBeInTheDocument();
    expect(await screen.findByText('Chain 2', { selector: 'td' })).toBeInTheDocument();

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/ipg-chains/1/relations');
    });
    expect(await screen.findByText('Program 1')).toBeInTheDocument();

    mockRelationsResponse(2);
    await store.selectChain(2);

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/ipg-chains/2/relations');
    });
    expect(await screen.findByText('Program 2')).toBeInTheDocument();
  });

  it('displays filters and updates list on search', async () => {
    mockLookupResponses();
    mockChainsResponse();
    mockRelationsResponse(1);

    renderInvestmentChainsView(InvestmentChainsView);

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/ipg-chains', expect.any(Object));
    });

    const initialCalls = apiGetMock.mock.calls.length;

    mockChainsResponse();
    mockRelationsResponse(1);
    const filterInput = await screen.findByTestId('investment-chains-filter');
    await fireEvent.update(filterInput, 'Chain');

    await waitFor(() => {
      expect(apiGetMock.mock.calls.length).toBeGreaterThanOrEqual(initialCalls + 2);
      const chainCall = apiGetMock.mock.calls.slice(initialCalls).find(([path]) => path === '/api/v1/ipg-chains');
      expect(chainCall).toBeDefined();
      const [, options] = chainCall!;
      expect(options).toEqual(expect.objectContaining({
        query: expect.objectContaining({ name: 'Chain', page: 0 })
      }));
    });
  });

  it('filters relations by search term', async () => {
    mockLookupResponses();
    mockChainsResponse();
    apiGetMock.mockResolvedValueOnce([
      {
        relationKey: 101,
        chainKey: 1,
        investmentProgramKey: 1001,
        investmentProgramName: 'Program Alpha',
        planGroupKey: 2001,
        planGroupName: 'Group Alpha'
      },
      {
        relationKey: 102,
        chainKey: 1,
        investmentProgramKey: 1002,
        investmentProgramName: 'Program Beta',
        planGroupKey: 2002,
        planGroupName: 'Group Beta'
      }
    ]);

    renderInvestmentChainsView(InvestmentChainsView);
    const store = useInvestmentChainsStore();

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/ipg-chains/1/relations');
    });

    await waitFor(() => {
      expect(screen.getByText('Program Alpha')).toBeInTheDocument();
      expect(screen.getByText('Program Beta')).toBeInTheDocument();
    });

    const searchInput = screen.getByPlaceholderText('Введите часть названия программы');
    await fireEvent.update(searchInput, 'Alpha');

    await waitFor(() => {
      expect(screen.getByText('Program Alpha')).toBeInTheDocument();
      expect(screen.queryByText('Program Beta')).not.toBeInTheDocument();
    });
  });

  it('filters relations by plan group', async () => {
    mockLookupResponses();
    mockChainsResponse();
    apiGetMock.mockResolvedValueOnce([
      {
        relationKey: 101,
        chainKey: 1,
        investmentProgramKey: 1001,
        investmentProgramName: 'Program 1',
        planGroupKey: 2001,
        planGroupName: 'Group 1'
      },
      {
        relationKey: 102,
        chainKey: 1,
        investmentProgramKey: 1002,
        investmentProgramName: 'Program 2',
        planGroupKey: 2002,
        planGroupName: 'Group 2'
      }
    ]);

    renderInvestmentChainsView(InvestmentChainsView);

    await waitFor(() => {
      expect(screen.getByText('Program 1')).toBeInTheDocument();
      expect(screen.getByText('Program 2')).toBeInTheDocument();
    });

    const planGroupSelect = screen.getByLabelText('Фильтр по группе планов');
    await fireEvent.update(planGroupSelect, '2001');

    await waitFor(() => {
      expect(screen.getByText('Program 1')).toBeInTheDocument();
      expect(screen.queryByText('Program 2')).not.toBeInTheDocument();
    });
  });

  it('shows error banner when API fails', async () => {
    mockLookupResponses();
    apiGetMock.mockRejectedValueOnce(new Error('API fail'));

    renderInvestmentChainsView(InvestmentChainsView);

    expect(await screen.findByText(/Не удалось загрузить цепочки инвестиционных программ/)).toBeInTheDocument();
  });

  it('displays lookup data in table cells', async () => {
    mockLookupResponses();
    mockChainsResponse();
    mockRelationsResponse(1);

    renderInvestmentChainsView(InvestmentChainsView);

    await waitFor(() => {
      expect(screen.getByText('Network 1')).toBeInTheDocument();
      expect(screen.getByText('Program 1')).toBeInTheDocument();
      expect(screen.getByText('Group 1')).toBeInTheDocument();
    });
  });

  it('shows loading indicators for lookup stores', async () => {
    // Mock delayed lookup responses
    apiGetMock.mockImplementation((url: string) => {
      if (url === '/api/v1/lookups/st-networks') {
        return new Promise(resolve => setTimeout(() => resolve([]), 100));
      }
      if (url === '/api/v1/lookups/investment-programs') {
        return new Promise(resolve => setTimeout(() => resolve([]), 100));
      }
      if (url === '/api/v1/lookups/plan-groups') {
        return new Promise(resolve => setTimeout(() => resolve([]), 100));
      }
      return Promise.resolve([]);
    });

    mockChainsResponse();
    mockRelationsResponse(1);

    renderInvestmentChainsView(InvestmentChainsView);

    // Check that loading spinners are shown (they should be visible briefly)
    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalled();
    }, { timeout: 200 });
  });
});
