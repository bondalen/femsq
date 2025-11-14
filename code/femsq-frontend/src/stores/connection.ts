import { computed, reactive, ref } from 'vue';
import { defineStore } from 'pinia';

export type ConnectionState = 'idle' | 'connecting' | 'connected' | 'connectionError' | 'disconnecting';
export type ActiveView = 'home' | 'organizations';
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
  timeoutSeconds: '30',
  useSsl: false,
  applicationName: 'FEMSQ UI'
};

/**
 * Управляет состоянием подключения к БД, основными вью и последними настройками формы подключения.
 * Содержит логи для отслеживания переходов и помогает переиспользовать ранее введённые данные.
 */
export const useConnectionStore = defineStore('connection', () => {
  const status = ref<ConnectionState>('idle');
  const activeView = ref<ActiveView>('home');
  const schema = ref<string>('');
  const user = ref<string>('');
  const lastMessage = ref<string>('Ожидает подключения');
  const lastError = ref<string>('');
  const savedForm = reactive<ConnectionFormValues>({ ...DEFAULT_FORM_VALUES });

  /**
   * Возвращает флаг доступности раздела организаций.
   */
  const organizationsEnabled = computed(() => status.value === 'connected');

  /**
   * Возвращает цвет индикатора строки состояния.
   */
  const statusTone = computed(() => {
    switch (status.value) {
      case 'connected':
        return 'success';
      case 'connecting':
      case 'disconnecting':
        return 'info';
      case 'connectionError':
        return 'danger';
      default:
        return 'neutral';
    }
  });

  /**
   * Устанавливает новое состояние подключения с дополнительными параметрами.
   */
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

  /**
   * Меняет текущий экран приложения.
   */
  function navigate(view: ActiveView): void {
    console.info('[connection-store] navigate', view);
    activeView.value = view;
  }

  /**
   * Сбрасывает информацию о подключении при выходе пользователя.
   */
  function resetConnection(): void {
    console.info('[connection-store] reset');
    status.value = 'idle';
    schema.value = '';
    user.value = '';
    lastMessage.value = 'Ожидает подключения';
    lastError.value = '';
    activeView.value = 'home';
  }

  /**
   * Возвращает копию последней сохранённой конфигурации подключения.
   */
  function getSavedForm(): ConnectionFormValues {
    return { ...savedForm };
  }

  /**
   * Обновляет сохранённую конфигурацию подключения (чувствительные поля очищаются).
   */
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
    statusTone,
    setStatus,
    navigate,
    resetConnection,
    getSavedForm,
    updateSavedForm
  };
});
