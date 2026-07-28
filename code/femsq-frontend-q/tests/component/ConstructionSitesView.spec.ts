import '@testing-library/jest-dom';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { fireEvent, screen, waitFor } from '@testing-library/vue';
import { createPinia, setActivePinia } from 'pinia';

import ConstructionSitesView from '@/views/construction-sites/ConstructionSitesView.vue';
import * as constructionSitesApi from '@/api/construction-sites-api';
import * as organizationsApi from '@/api/organizations-api';
import { useConstructionSitesStore } from '@/stores/construction-sites';
import { renderConstructionSitesView } from './renderConstructionSitesView';

vi.mock('@/api/construction-sites-api', async () => {
  const actual = await vi.importActual<typeof constructionSitesApi>('@/api/construction-sites-api');
  return {
    ...actual,
    getConstructionSites: vi.fn(),
    getOgAgCsLookups: vi.fn(),
    getCstAgents: vi.fn(),
    getCstRaList: vi.fn(),
    getCstAgPnLookupsForSite: vi.fn(),
    getRaPeriodLookups: vi.fn(),
    getCstRalpRaList: vi.fn(),
    getRalpRaAuStatusLookups: vi.fn()
  } satisfies Partial<typeof actual>;
});

vi.mock('@/api/organizations-api', async () => {
  const actual = await vi.importActual<typeof organizationsApi>('@/api/organizations-api');
  return {
    ...actual,
    getOrganizationsLookup: vi.fn()
  } satisfies Partial<typeof actual>;
});

vi.mock('@/views/construction-sites/CstReportsTab.vue', () => ({
  default: { name: 'CstReportsTabStub', template: '<div data-test="stub-reports" />' }
}));

vi.mock('@/views/construction-sites/CstRentReportsTab.vue', () => ({
  default: { name: 'CstRentReportsTabStub', template: '<div data-test="stub-rent" />' }
}));

const getConstructionSitesMock = vi.mocked(constructionSitesApi.getConstructionSites);
const getOgAgCsLookupsMock = vi.mocked(constructionSitesApi.getOgAgCsLookups);
const getCstAgentsMock = vi.mocked(constructionSitesApi.getCstAgents);
const getOrganizationsLookupMock = vi.mocked(organizationsApi.getOrganizationsLookup);
const getCstRaListMock = vi.mocked(constructionSitesApi.getCstRaList);
const getCstAgPnLookupsForSiteMock = vi.mocked(constructionSitesApi.getCstAgPnLookupsForSite);
const getRaPeriodLookupsMock = vi.mocked(constructionSitesApi.getRaPeriodLookups);
const getCstRalpRaListMock = vi.mocked(constructionSitesApi.getCstRalpRaList);
const getRalpRaAuStatusLookupsMock = vi.mocked(constructionSitesApi.getRalpRaAuStatusLookups);

function mockSitesAndLookups() {
  getConstructionSitesMock.mockResolvedValue([
    { cstKey: 1001, cstName: 'Site Alpha' },
    { cstKey: 1002, cstName: 'Site Beta' }
  ]);
  getOgAgCsLookupsMock.mockResolvedValue([{ ogaKey: 10, ogaNm: 'Agent Ten' }]);
  getOrganizationsLookupMock.mockResolvedValue([{ ogKey: 1, ogNm: 'Org 1' }]);
}

/** Quasar-атрибут `data-test` (не `data-testid` Testing Library). */
function byDataTest(id: string): HTMLElement {
  const el = document.querySelector(`[data-test="${id}"]`);
  if (!(el instanceof HTMLElement)) {
    throw new Error(`Element [data-test="${id}"] not found`);
  }
  return el;
}

function mockAgentsForSite(cstKey: number, label: string) {
  getCstAgentsMock.mockResolvedValueOnce([
    {
      cstaKey: 2000 + cstKey,
      cstaAg: 10,
      cstaCst: cstKey,
      agentLabel: label
    }
  ]);
}

function stubReportApis() {
  getCstRaListMock.mockResolvedValue([]);
  getCstAgPnLookupsForSiteMock.mockResolvedValue([]);
  getRaPeriodLookupsMock.mockResolvedValue([]);
  getCstRalpRaListMock.mockResolvedValue([]);
  getRalpRaAuStatusLookupsMock.mockResolvedValue([]);
}

describe('ConstructionSitesView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
    stubReportApis();
  });

  it('renders sites list and loads agents for the first site', async () => {
    mockSitesAndLookups();
    mockAgentsForSite(1001, 'Agent Alpha');

    renderConstructionSitesView(ConstructionSitesView);
    const store = useConstructionSitesStore();

    await waitFor(() => {
      expect(getConstructionSitesMock).toHaveBeenCalled();
    });

    expect(await screen.findByText('Site Alpha', { selector: 'td' })).toBeInTheDocument();
    expect(await screen.findByText('Site Beta', { selector: 'td' })).toBeInTheDocument();
    expect(byDataTest('construction-sites-view')).toBeInTheDocument();

    await waitFor(() => {
      expect(getCstAgentsMock).toHaveBeenCalledWith(1001);
    });
    expect(await screen.findByText('Agent Alpha')).toBeInTheDocument();
    expect(store.selectedCstKey).toBe(1001);
    expect(byDataTest('cst-agents-tree')).toBeInTheDocument();
  });

  it('reloads agents when another site is selected', async () => {
    mockSitesAndLookups();
    mockAgentsForSite(1001, 'Agent Alpha');

    renderConstructionSitesView(ConstructionSitesView);
    const store = useConstructionSitesStore();

    await waitFor(() => {
      expect(getCstAgentsMock).toHaveBeenCalledWith(1001);
    });
    expect(await screen.findByText('Agent Alpha')).toBeInTheDocument();

    mockAgentsForSite(1002, 'Agent Beta');
    await store.selectSite(1002);

    await waitFor(() => {
      expect(getCstAgentsMock).toHaveBeenCalledWith(1002);
    });
    expect(await screen.findByText('Agent Beta')).toBeInTheDocument();
    expect(store.selectedCstKey).toBe(1002);
  });

  it('selects a site on master row click', async () => {
    mockSitesAndLookups();
    mockAgentsForSite(1001, 'Agent Alpha');

    renderConstructionSitesView(ConstructionSitesView);

    await waitFor(() => {
      expect(getCstAgentsMock).toHaveBeenCalledWith(1001);
    });

    mockAgentsForSite(1002, 'Agent Beta');
    const betaCell = await screen.findByText('Site Beta', { selector: 'td' });
    await fireEvent.click(betaCell);

    await waitFor(() => {
      expect(getCstAgentsMock).toHaveBeenCalledWith(1002);
    });
    expect(await screen.findByText('Agent Beta')).toBeInTheDocument();
  });

  it('shows error banner when sites API fails', async () => {
    getConstructionSitesMock.mockRejectedValueOnce(new Error('GraphQL fail'));
    getOgAgCsLookupsMock.mockResolvedValue([]);
    getOrganizationsLookupMock.mockResolvedValue([]);

    renderConstructionSitesView(ConstructionSitesView);

    // store кладёт message из Error, fallback — «Не удалось загрузить стройки»
    expect(await screen.findByText('GraphQL fail')).toBeInTheDocument();
  });
});
