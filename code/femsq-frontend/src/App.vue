<template>
  <AppLayout
    :status="connection.status"
    :status-tone="connection.statusTone"
    :message="connection.lastMessage"
    :schema="connection.schema"
    :user="connection.user"
    :error="connection.lastError"
    :active-view="connection.activeView"
    :organizations-enabled="connection.organizationsEnabled"
    @open-connection="handleOpenConnection"
    @navigate="handleNavigate"
    @disconnect="handleDisconnect"
  >
    <section v-if="connection.activeView === 'home'" class="content-card">
      <h1>Добро пожаловать в FEMSQ UI</h1>
      <p>
        Этот экран содержит подсказки по подключению к базе данных и навигации.
        Нажмите «Подключение к БД», чтобы установить соединение, либо воспользуйтесь кнопкой «Организации»
        после успешного подключения.
      </p>
      <ul>
        <li>Строка состояния внизу отображает текущий статус соединения и выбранную схему.</li>
        <li>Верхняя панель доступна из любой части приложения и содержит основные действия.</li>
        <li>Интерфейс адаптирован для мобильных устройств: кнопки сворачиваются в меню.</li>
      </ul>
    </section>

    <OrganizationsView v-else />
  </AppLayout>

  <ConnectionModal
    :open="modalState.open"
    :status="modalState.status"
    :message="modalState.message"
    :error="modalState.error"
    :initial-values="modalState.form"
    @close="handleModalClose"
    @submit="handleModalSubmit"
    @reset-defaults="resetModalForm"
  />
</template>

<script setup lang="ts">
import { nextTick, onMounted, reactive } from 'vue';

import AppLayout from '@/components/layout/AppLayout.vue';
import ConnectionModal from '@/components/setup/connection-modal/ConnectionModal.vue';
import OrganizationsView from '@/views/organizations/OrganizationsView.vue';
import type { ActiveView, ConnectionFormValues } from '@/stores/connection';
import { useConnectionStore } from '@/stores/connection';
import { useOrganizationsStore } from '@/stores/organizations';
import {
  applyConnection,
  getConnectionConfig,
  getConnectionStatus,
  testConnection,
  type ApiError
} from '@/api/connection-api';

const connection = useConnectionStore();
const organizations = useOrganizationsStore();

const modalState = reactive({
  open: false,
  status: 'idle' as 'idle' | 'validating' | 'connecting' | 'success' | 'error' | 'closing',
  message: 'Введите параметры подключения',
  error: '',
  form: connection.getSavedForm()
});

/**
 * Загружает текущий статус подключения и обновляет состояние.
 */
async function loadConnectionStatus(): Promise<void> {
  try {
    const status = await getConnectionStatus();
    if (status.connected) {
      connection.setStatus('connected', {
        schema: status.schema || '',
        database: status.database || '',
        message: status.message || 'Подключено'
      });
    } else {
      connection.setStatus('idle', {
        message: status.message || 'Ожидает подключения',
        error: status.error || ''
      });
    }
  } catch (error) {
    console.error('[App] Failed to load connection status:', error);
    // Не показываем ошибку, просто оставляем статус как есть
    connection.setStatus('idle', { message: 'Ожидает подключения' });
  }
}

/**
 * Загружает текущую конфигурацию подключения для заполнения формы.
 */
async function loadConnectionConfig(): Promise<void> {
  try {
    const config = await getConnectionConfig();
    if (config.host) {
      // Преобразуем authMode из API формата в формат формы
      let authMode: 'sql' | 'windows' | 'token' = 'sql';
      if (config.authMode === 'windows-integrated') {
        authMode = 'windows';
      } else if (config.authMode === 'kerberos') {
        authMode = 'token';
      }

      modalState.form = {
        host: config.host || '',
        port: config.port?.toString() || '1433',
        database: config.database || '',
        schema: config.schema || '',
        authMode,
        username: config.username || '',
        password: '',
        token: '',
        timeoutSeconds: '30',
        useSsl: false,
        applicationName: 'FEMSQ UI'
      };
    }
  } catch (error) {
    console.error('[App] Failed to load connection config:', error);
    // Используем сохраненные значения формы
    modalState.form = {
      ...connection.getSavedForm(),
      password: '',
      token: ''
    };
  }
}

/**
 * Открывает модальное окно подключения и подготавливает форму.
 */
async function handleOpenConnection(): Promise<void> {
  if (modalState.open) {
    return;
  }
  
  // Загружаем текущую конфигурацию для заполнения формы
  await loadConnectionConfig();
  
  modalState.status = 'idle';
  modalState.message = 'Введите параметры подключения';
  modalState.error = '';
  modalState.open = true;
}

/**
 * Обрабатывает попытку перехода на другой экран приложения.
 */
function handleNavigate(view: ActiveView): void {
  if (view === 'organizations' && !connection.organizationsEnabled) {
    return;
  }
  if (view === 'organizations' && !organizations.hasData && !organizations.loading) {
    organizations.loadOrganizations({ latencyMs: 500 });
  }
  connection.navigate(view);
}

/**
 * Инициирует отключение, сбрасывая глобальное состояние.
 */
function handleDisconnect(): void {
  if (connection.status !== 'connected') {
    return;
  }
  connection.setStatus('disconnecting', { message: 'Отключение…' });
  window.setTimeout(() => {
    connection.resetConnection();
    organizations.reset();
    nextTick(() => {
      connection.setStatus('idle', { message: 'Ожидает подключения' });
    });
  }, 800);
}

/**
 * Преобразует значения формы в формат API запроса.
 */
function formValuesToApiRequest(values: ConnectionFormValues) {
  // Преобразуем authMode из формата формы в формат API
  let authMode: 'credentials' | 'windows-integrated' | 'kerberos' = 'credentials';
  if (values.authMode === 'windows') {
    authMode = 'windows-integrated';
  } else if (values.authMode === 'token') {
    authMode = 'kerberos';
  }

  return {
    host: values.host,
    port: parseInt(values.port, 10),
    database: values.database,
    schema: values.schema || undefined,
    username: values.authMode === 'sql' ? values.username : undefined,
    password: values.authMode === 'sql' ? values.password : undefined,
    authMode
  };
}

/**
 * Обрабатывает ошибку API и возвращает понятное сообщение для пользователя.
 */
function handleApiError(error: unknown): string {
  if (error && typeof error === 'object' && 'message' in error) {
    const apiError = error as ApiError;
    return apiError.message || 'Неизвестная ошибка подключения';
  }
  return 'Неизвестная ошибка подключения';
}

/**
 * Вызывается при отправке формы модального окна подключения.
 */
async function handleModalSubmit(values: ConnectionFormValues): Promise<void> {
  if (modalState.status === 'connecting' || modalState.status === 'validating') {
    return;
  }

  // Шаг 1: Валидация и тестирование подключения
  modalState.status = 'validating';
  modalState.message = 'Проверяем данные…';
  modalState.error = '';

  try {
    const testRequest = formValuesToApiRequest(values);
    const testResult = await testConnection(testRequest);

    if (!testResult.connected) {
      modalState.status = 'error';
      modalState.error = testResult.error || 'Не удалось установить подключение';
      modalState.message = 'Проверка подключения не прошла';
      connection.setStatus('connectionError', {
        error: testResult.error || 'Не удалось установить подключение',
        message: 'Проверка подключения не прошла'
      });
      return;
    }

    // Шаг 2: Применение конфигурации и переподключение
    modalState.status = 'connecting';
    modalState.message = 'Применяем конфигурацию и переподключаемся…';
    modalState.error = '';
    connection.setStatus('connecting', { message: 'Подключение…' });

    const applyRequest = formValuesToApiRequest(values);
    const applyResult = await applyConnection(applyRequest);

    if (!applyResult.connected) {
      modalState.status = 'error';
      modalState.error = applyResult.error || 'Не удалось применить конфигурацию';
      modalState.message = 'Ошибка применения конфигурации';
      connection.setStatus('connectionError', {
        error: applyResult.error || 'Не удалось применить конфигурацию',
        message: 'Ошибка применения конфигурации'
      });
      organizations.reset();
      return;
    }

    // Успешное подключение
    connection.setStatus('connected', {
      schema: applyResult.schema || values.schema || '',
      database: applyResult.database || values.database || '',
      user: values.authMode === 'windows' ? 'Windows Auth' : values.username || '',
      message: applyResult.message || `Подключено к ${applyResult.schema || applyResult.database || values.database}`
    });
    connection.updateSavedForm(values);
    organizations.loadOrganizations({ latencyMs: 600 });
    connection.navigate('organizations');

    modalState.status = 'success';
    modalState.message = applyResult.message || 'Подключено';

    // Закрываем модальное окно через небольшую задержку
    window.setTimeout(() => {
      closeModal();
    }, 500);
  } catch (error) {
    console.error('[App] Connection error:', error);
    const errorMessage = handleApiError(error);
    modalState.status = 'error';
    modalState.error = errorMessage;
    modalState.message = 'Ошибка подключения';
    connection.setStatus('connectionError', {
      error: errorMessage,
      message: 'Ошибка подключения'
    });
    organizations.reset();
  }
}

/**
 * Закрывает модальное окно при клике на «Отмена» или после успешного подключения.
 */
function handleModalClose(): void {
  if (modalState.status === 'connecting') {
    return;
  }
  closeModal();
}

/**
 * Сбрасывает значения формы к сохранённым по умолчанию.
 */
function resetModalForm(): void {
  modalState.form = {
    ...connection.getSavedForm(),
    password: '',
    token: ''
  };
  modalState.message = 'Данные восстановлены';
  modalState.error = '';
}

function closeModal(): void {
  modalState.open = false;
  modalState.status = 'idle';
  modalState.message = 'Введите параметры подключения';
  modalState.error = '';
}

// Загружаем статус подключения при монтировании компонента
onMounted(async () => {
  await loadConnectionStatus();
});
</script>

<style scoped>
.content-card {
  background: white;
  border-radius: 24px;
  padding: 32px;
  box-shadow: 0 24px 48px rgba(28, 35, 51, 0.08);
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.content-card__placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px dashed rgba(28, 35, 51, 0.16);
  border-radius: 16px;
  padding: 24px;
  color: rgba(28, 35, 51, 0.64);
  font-size: 14px;
}

@media (max-width: 768px) {
  .content-card {
    padding: 20px;
    border-radius: 20px;
  }
}
</style>
