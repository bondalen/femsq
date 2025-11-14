import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

export interface AgentSummary {
  id: string;
  agentKey: string;
  agentName: string;
  role: string;
  phone?: string;
  email?: string;
}

export interface OrganizationSummary {
  id: string;
  ogKey: string;
  ogName: string;
  ogType: string;
  region: string;
  contractsCount: number;
  updatedAt: string;
  fullName: string;
  inn?: string;
  ogrn?: string;
  address?: string;
  contactPerson?: string;
  description?: string;
  agents: AgentSummary[];
}

interface LoadOptions {
  latencyMs?: number;
  shouldFail?: boolean;
}

const MOCK_ORGANIZATIONS: OrganizationSummary[] = [
  {
    id: 'og-001',
    ogKey: 'OG-001',
    ogName: 'АО "ФишАй Девелопмент"',
    fullName: 'Акционерное общество «ФишАй Девелопмент»',
    ogType: 'Девелопер',
    region: 'Москва',
    contractsCount: 12,
    updatedAt: '2025-11-07T18:40:00+03:00',
    inn: '7701234567',
    ogrn: '1027700132195',
    address: 'Москва, наб. Тараса Шевченко, 23',
    contactPerson: 'Ирина Петрова',
    description: 'Основной заказчик капитального строительства по проекту FishEye.',
    agents: [
      {
        id: 'og-001-ag-01',
        agentKey: 'AG-101',
        agentName: 'ООО "СтройПроект"',
        role: 'Генподрядчик',
        phone: '+7 (495) 123-45-67',
        email: 'info@stroyproekt.ru'
      },
      {
        id: 'og-001-ag-02',
        agentKey: 'AG-126',
        agentName: 'ООО "ИнжТех"',
        role: 'Инжиниринг',
        phone: '+7 (495) 987-65-43'
      }
    ]
  },
  {
    id: 'og-002',
    ogKey: 'OG-002',
    ogName: 'ООО "КапСтройСервис"',
    fullName: 'Общество с ограниченной ответственностью «КапСтройСервис»',
    ogType: 'Подрядчик',
    region: 'Санкт-Петербург',
    contractsCount: 5,
    updatedAt: '2025-11-05T14:15:00+03:00',
    inn: '7805123456',
    ogrn: '1117847251234',
    address: 'Санкт-Петербург, ул. Савушкина, 45',
    contactPerson: 'Павел Иванов',
    agents: [
      {
        id: 'og-002-ag-01',
        agentKey: 'AG-210',
        agentName: 'ООО "ТехМонтаж"',
        role: 'Монтаж',
        phone: '+7 (812) 345-67-89'
      }
    ]
  },
  {
    id: 'og-003',
    ogKey: 'OG-003',
    ogName: 'АО "СеверИнвест"',
    fullName: 'Акционерное общество «СеверИнвест»',
    ogType: 'Инвестор',
    region: 'Казань',
    contractsCount: 0,
    updatedAt: '2025-10-28T09:05:00+03:00',
    description: 'Инвестиционная компания, находится на этапе анализа площадок.',
    agents: []
  }
];

/**
 * Управляет локальным каталогом организаций для демонстрации UX сценариев.
 * Использует mock-данные до интеграции с REST/GraphQL API.
 */
export const useOrganizationsStore = defineStore('organizations', () => {
  const loading = ref(false);
  const error = ref('');
  const organizations = ref<OrganizationSummary[]>([]);
  const selectedId = ref<string | null>(null);
  const lastLoadedAt = ref<string>('');

  const filters = reactive({
    ogKey: '',
    ogName: '',
    status: 'all'
  });

  const total = computed(() => organizations.value.length);
  const selectedOrganization = computed(() => organizations.value.find((item) => item.id === selectedId.value) ?? null);
  const agents = computed(() => selectedOrganization.value?.agents ?? []);
  const hasData = computed(() => organizations.value.length > 0);

  /**
   * Загружает mock-данные, имитируя сетевой запрос.
   */
  function loadOrganizations(options: LoadOptions = {}): Promise<void> {
    if (loading.value) {
      return Promise.resolve();
    }
    loading.value = true;
    error.value = '';

    return new Promise((resolve) => {
      const latency = options.latencyMs ?? 800;
      window.setTimeout(() => {
        if (options.shouldFail) {
          error.value = 'Не удалось загрузить организации (демо).';
          organizations.value = [];
          selectedId.value = null;
          loading.value = false;
          resolve();
          return;
        }

        organizations.value = [...MOCK_ORGANIZATIONS];
        selectedId.value = organizations.value[0]?.id ?? null;
        lastLoadedAt.value = new Date().toISOString();
        loading.value = false;
        resolve();
      }, latency);
    });
  }

  function selectOrganization(id: string): void {
    if (selectedId.value === id) {
      return;
    }
    selectedId.value = id;
  }

  function reset(): void {
    loading.value = false;
    error.value = '';
    organizations.value = [];
    selectedId.value = null;
    lastLoadedAt.value = '';
    filters.ogKey = '';
    filters.ogName = '';
    filters.status = 'all';
  }

  return {
    loading,
    error,
    organizations,
    selectedId,
    total,
    selectedOrganization,
    agents,
    filters,
    hasData,
    lastLoadedAt,
    loadOrganizations,
    selectOrganization,
    reset
  };
});
