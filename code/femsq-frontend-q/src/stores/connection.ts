import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

export type ConnectionState = 'idle' | 'connecting' | 'connected' | 'connectionError' | 'disconnecting';
export type ActiveView = 'home' | 'organizations' | 'investment-chains' | 'reports' | 'audits' | 'test-grid';
export type AuthMode = 'sql' | 'windows' | 'token';

export interface ConnectionFormValues {
  host: string;
  port: string;
  database: string;
  schema: string;
  authMode: AuthMode;
  username: string;
  password: string;
  token: string;
  realm: string;  // Kerberos realm для Windows Authentication на Linux
  timeoutSeconds: string;
  useSsl: boolean;
  applicationName: string;
}

const DEFAULT_FORM_VALUES: ConnectionFormValues = {
  host: 'localhost',
  port: '1433',
  database: 'FishEye',
  schema: 'ags_test',
  authMode: 'sql',
  username: 'sa',
  password: '',
  token: '',
  realm: '',
  timeoutSeconds: '30',
  useSsl: false,
  applicationName: 'FEMSQ UI'
};

export const useConnectionStore = defineStore('connection', () => {
  const status = ref<ConnectionState>('idle');
  const activeView = ref<ActiveView>('home');
  const schema = ref<string>('');
  const user = ref<string>('');
  const lastMessage = ref<string>('Ожидает подключения');
  const lastError = ref<string>('');
  const savedForm = reactive<ConnectionFormValues>({ ...DEFAULT_FORM_VALUES });

  const organizationsEnabled = computed(() => status.value === 'connected');
  const investmentChainsEnabled = computed(() => status.value === 'connected');
  const reportsEnabled = computed(() => true);

  const statusTone = computed(() => {
    switch (status.value) {
      case 'connected':
        return 'positive';
      case 'connecting':
      case 'disconnecting':
        return 'info';
      case 'connectionError':
        return 'negative';
      default:
        return 'neutral';
    }
  });

  function setStatus(next: ConnectionState, payload?: { schema?: string; user?: string; message?: string; error?: string }): void {
    console.info('[connection-store] status change', status.value, '→', next, payload);
    status.value = next;
    if (payload?.schema !== undefined) {
      schema.value = payload.schema;
    }
    if (payload?.user !== undefined) {
      user.value = payload.user;
    }
    if (payload?.message !== undefined) {
      lastMessage.value = payload.message;
    }
    if (payload?.error !== undefined) {
      lastError.value = payload.error;
    }
    if (next !== 'connectionError') {
      lastError.value = '';
    }
    if (next === 'connectionError' || next === 'idle') {
      activeView.value = 'home';
    }
  }

  function navigate(view: ActiveView): void {
    console.info('[connection-store] navigate', view);
    activeView.value = view;
  }

  function resetConnection(): void {
    console.info('[connection-store] reset');
    status.value = 'idle';
    schema.value = '';
    user.value = '';
    lastMessage.value = 'Ожидает подключения';
    lastError.value = '';
    activeView.value = 'home';
  }

  function getSavedForm(): ConnectionFormValues {
    return { ...savedForm };
  }

  function updateSavedForm(values: ConnectionFormValues): void {
    console.info('[connection-store] update saved form');
    Object.assign(savedForm, {
      ...values,
      password: '',
      token: ''
    });
  }

  return {
    status,
    activeView,
    schema,
    user,
    lastMessage,
    lastError,
    organizationsEnabled,
    investmentChainsEnabled,
    reportsEnabled,
    statusTone,
    setStatus,
    navigate,
    resetConnection,
    getSavedForm,
    updateSavedForm
  };
});
