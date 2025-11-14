import '@testing-library/jest-dom';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { fireEvent, screen, waitFor } from '@testing-library/vue';
import { createPinia, setActivePinia } from 'pinia';

import OrganizationsView from '@/views/organizations/OrganizationsView.vue';
import * as http from '@/api/http';
import { useOrganizationsStore } from '@/stores/organizations';
import { renderOrganizationsView } from './renderWithLayout';

vi.mock('@/api/http', async () => {
  const actual = await vi.importActual<typeof http>('@/api/http');
  return {
    ...actual,
    apiGet: vi.fn()
  } satisfies Partial<typeof actual>;
});

const apiGetMock = vi.mocked(http.apiGet);

function mockOrganizationsResponse() {
  apiGetMock.mockResolvedValueOnce({
    content: [
      {
        ogKey: 1,
        ogName: 'Org 1',
        ogFullName: 'Org 1 Full',
        ogOfficialName: 'Org 1 Official',
        registrationTaxType: 'REG',
        inn: 123,
        kpp: 456,
        updatedAt: '2025-01-01T10:00:00Z'
      },
      {
        ogKey: 2,
        ogName: 'Org 2',
        ogFullName: 'Org 2 Full',
        ogOfficialName: 'Org 2 Official',
        registrationTaxType: 'REG',
        inn: 789,
        kpp: 101,
        updatedAt: '2025-01-02T12:00:00Z'
      }
    ],
    totalElements: 2,
    totalPages: 1,
    number: 0,
    size: 10
  });
}

function mockAgentsResponse(organizationKey: number, code?: string) {
  apiGetMock.mockResolvedValueOnce([
    { ogAgKey: 100 + organizationKey, code: code ?? `AG-${organizationKey}`, organizationKey }
  ]);
}

describe('OrganizationsView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setActivePinia(createPinia());
  });

  it('renders table with organizations and loads agents on selection', async () => {
    mockOrganizationsResponse();
    mockAgentsResponse(1);

    renderOrganizationsView(OrganizationsView);
    const store = useOrganizationsStore();

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/organizations', expect.any(Object));
    });

    expect(await screen.findByText('Org 1', { selector: 'td' })).toBeInTheDocument();
    expect(await screen.findByText('Org 2', { selector: 'td' })).toBeInTheDocument();

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/organizations/1/agents');
    });
    expect(await screen.findByText('AG-1')).toBeInTheDocument();

    mockAgentsResponse(2, 'AG-2');
    await store.selectOrganization(2);

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/organizations/2/agents');
    });
    expect(await screen.findByText('AG-2')).toBeInTheDocument();
  });

  it('displays filters and updates list on search', async () => {
    mockOrganizationsResponse();
    mockAgentsResponse(1);

    renderOrganizationsView(OrganizationsView);

    await waitFor(() => {
      expect(apiGetMock).toHaveBeenCalledWith('/api/v1/organizations', expect.any(Object));
    });

    const initialCalls = apiGetMock.mock.calls.length;

    mockOrganizationsResponse();
    mockAgentsResponse(1, 'Filtered agent');
    const filterInput = await screen.findByTestId('organizations-filter');
    await fireEvent.update(filterInput, 'Org');

    await waitFor(() => {
      expect(apiGetMock.mock.calls.length).toBeGreaterThanOrEqual(initialCalls + 2);
      const organizationCall = apiGetMock.mock.calls.slice(initialCalls).find(([path]) => path === '/api/v1/organizations');
      expect(organizationCall).toBeDefined();
      const [, options] = organizationCall!;
      expect(options).toEqual(expect.objectContaining({
        query: expect.objectContaining({ ogName: 'Org', page: 0 })
      }));
    });
  });

  it('shows error banner when API fails', async () => {
    apiGetMock.mockRejectedValueOnce(new Error('API fail'));

    renderOrganizationsView(OrganizationsView);

    expect(await screen.findByText(/Не удалось загрузить организации/)).toBeInTheDocument();
  });
});
