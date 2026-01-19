<template>
  <div id="app-wrapper">
    <AppLayout
    :status="connection.status"
    :status-tone="connection.statusTone"
    :message="connection.lastMessage"
    :schema="connection.schema"
    :user="connection.user"
    :error="connection.lastError"
    :active-view="connection.activeView"
    :organizations-enabled="connection.organizationsEnabled"
    :investment-chains-enabled="connection.investmentChainsEnabled"
    :reports-enabled="connection.reportsEnabled"
    @open-connection="handleOpenConnection"
    @navigate="handleNavigate"
    @disconnect="handleDisconnect"
  >
    <OrganizationsView v-if="connection.activeView === 'organizations'" />
    <InvestmentChainsView v-else-if="connection.activeView === 'investment-chains'" />
    <ReportsCatalog v-else-if="connection.activeView === 'reports'" />
    <AuditsView v-else-if="connection.activeView === 'audits'" />
    <AuditsViewV53 v-else-if="connection.activeView === 'audits-v53'" />
    <TestGridView v-else-if="connection.activeView === 'test-grid'" />

    <QPage v-else class="column q-gutter-lg">
      <div class="q-pa-xl bg-white rounded-borders shadow-2">
        <div class="text-h5 q-mb-md">Добро пожаловать в FEMSQ UI</div>
        <p>
          Этот экран содержит подсказки по подключению к базе данных и навигации.
          Нажмите «Подключение к БД», чтобы установить соединение, либо воспользуйтесь кнопкой «Организации» после успешного подключения.
        </p>
        <QList bordered class="rounded-borders">
          <QItem>
            <QItemSection avatar>
              <QIcon name="info" color="primary" />
            </QItemSection>
            <QItemSection>Строка состояния внизу отображает текущий статус соединения и выбранную схему.</QItemSection>
          </QItem>
          <QItem>
            <QItemSection avatar>
              <QIcon name="apps" color="primary" />
            </QItemSection>
            <QItemSection>Верхняя панель доступна из любой части приложения и содержит основные действия.</QItemSection>
          </QItem>
          <QItem>
            <QItemSection avatar>
              <QIcon name="smartphone" color="primary" />
            </QItemSection>
            <QItemSection>Интерфейс адаптирован для мобильных устройств: кнопки сворачиваются в меню.</QItemSection>
          </QItem>
        </QList>
      </div>
    </QPage>
  </AppLayout>

  <ConnectionModal
    :open="modalOpen"
    :status="modalStatus"
    :message="modalMessage"
    :error="modalError"
    :initial-values="modalForm"
    @close="handleCloseModal"
    @submit="handleSubmit"
    @reset-defaults="handleResetDefaults"
  />
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, onMounted, watch } from 'vue';
import { QPage, QList, QItem, QItemSection, QIcon, QBanner } from 'quasar';

import AppLayout from '@/components/layout/AppLayout.vue';
import ConnectionModal from '@/components/setup/ConnectionModal.vue';
import OrganizationsView from '@/views/organizations/OrganizationsView.vue';
import InvestmentChainsView from '@/views/investment-chains/InvestmentChainsView.vue';
import ReportsCatalog from '@/modules/reports/views/ReportsCatalog.vue';
import AuditsView from '@/views/audits/AuditsView.vue';
import AuditsViewV53 from '@/views/audits/AuditsViewV53.vue';
import TestGridView from '@/views/TestGridView.vue';
import type { ActiveView, ConnectionFormValues } from '@/stores/connection';
import { useConnectionStore } from '@/stores/connection';
import { useOrganizationsStore } from '@/stores/organizations';
import {
  getConnectionStatus,
  getConnectionConfig,
  applyConnection,
  testConnection,
  type ApiError
} from '@/api/connection-api';

const connection = useConnectionStore();
const organizationsStore = useOrganizationsStore();
const modalOpen = ref(false);
const modalStatus = ref<'idle' | 'validating' | 'connecting' | 'success' | 'error'>('idle');
const modalMessage = ref('Введите параметры подключения');
const modalError = ref('');
const modalForm = ref<ConnectionFormValues>(connection.getSavedForm());

/**
 * Загружает текущий статус подключения и обновляет store.
 */
async function loadConnectionStatus(): Promise<void> {
  try {
    const statusResponse = await getConnectionStatus();
    if (statusResponse.connected) {
      const previousSchema = connection.schema;
      connection.setStatus('connected', {
        schema: statusResponse.schema,
        database: statusResponse.database,
        message: statusResponse.message
      });
      // Если схема изменилась и мы на экране организаций, перезагружаем данные
      if (statusResponse.schema && statusResponse.schema !== previousSchema && connection.activeView === 'organizations') {
        console.info('[App] Schema changed on load, reloading organizations:', previousSchema, '→', statusResponse.schema);
        void organizationsStore.fetchOrganizations();
      } else if (connection.activeView === 'organizations' && !organizationsStore.hasOrganizations) {
        // Если мы на экране организаций, но данных нет, загружаем их
        void organizationsStore.fetchOrganizations();
      }
    } else {
      connection.setStatus('idle', {
        message: statusResponse.message,
        error: statusResponse.error
      });
    }
  } catch (error) {
    const apiError = error as ApiError;
    console.error('[App] Failed to load connection status:', apiError);
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

      modalForm.value = {
        host: config.host || '',
        port: config.port?.toString() || '1433',
        database: config.database || '',
        schema: config.schema || '',
        authMode,
        username: config.username || '',
        password: '', // Пароль никогда не возвращается из API
        token: '', // Токен никогда не возвращается из API
        realm: config.realm || '',  // Kerberos realm
        timeoutSeconds: '30',
        useSsl: false,
        applicationName: 'FEMSQ UI'
      };
    }
  } catch (error) {
    const apiError = error as ApiError;
    console.error('[App] Failed to load connection config:', apiError);
    // Если конфигурация не найдена, используем сохраненные значения формы
    modalForm.value = {
      ...connection.getSavedForm(),
      password: '',
      token: '',
      realm: ''
    };
  }
}

async function handleOpenConnection(): Promise<void> {
  // Загружаем текущую конфигурацию для заполнения формы
  await loadConnectionConfig();
  
  modalStatus.value = 'idle';
  modalMessage.value = 'Введите параметры подключения';
  modalError.value = '';
  modalOpen.value = true;
}

function handleNavigate(view: ActiveView): void {
  if (view === 'organizations' && !connection.organizationsEnabled) {
    return;
  }
  if (view === 'organizations' && !organizationsStore.hasOrganizations && !organizationsStore.loading) {
    void organizationsStore.fetchOrganizations();
  }
  connection.navigate(view);
}

function handleDisconnect(): void {
  if (connection.status !== 'connected') {
    return;
  }
  connection.setStatus('disconnecting', { message: 'Отключение…' });
  window.setTimeout(() => {
    connection.resetConnection();
    organizationsStore.reset();
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
    username: values.username || undefined,
    password: values.password || undefined,
    authMode,
    realm: values.realm || undefined
  };
}

/**
 * Вызывается при отправке формы модального окна подключения.
 */
async function handleSubmit(values: ConnectionFormValues): Promise<void> {
  if (modalStatus.value === 'connecting' || modalStatus.value === 'validating') {
    return;
  }

  // Шаг 1: Валидация и тестирование подключения
  modalStatus.value = 'validating';
  modalMessage.value = 'Проверяем данные…';
  modalError.value = '';

  try {
    const testRequest = formValuesToApiRequest(values);
    const testResult = await testConnection(testRequest);

    if (!testResult.connected) {
      modalStatus.value = 'error';
      modalError.value = testResult.error || 'Не удалось установить подключение';
      modalMessage.value = 'Проверка подключения не прошла';
      connection.setStatus('connectionError', {
        error: testResult.error,
        message: testResult.message
      });
      return;
    }

    // Шаг 2: Применение конфигурации
    modalStatus.value = 'connecting';
    modalMessage.value = 'Устанавливаем соединение…';
    modalError.value = '';
    connection.setStatus('connecting', { message: 'Подключение…' });

    const applyResult = await applyConnection(testRequest);

    if (applyResult.connected) {
      connection.setStatus('connected', {
        schema: applyResult.schema,
        database: applyResult.database,
        user: values.authMode === 'windows' ? 'Windows Auth' : values.username || 'sa',
        message: `Подключено к ${applyResult.schema || applyResult.database}`
      });
      connection.updateSavedForm(values);
      void organizationsStore.fetchOrganizations(); // Перезагружаем организации
      connection.navigate('organizations');

      modalStatus.value = 'success';
      modalMessage.value = 'Подключено';

      await nextTick(() => {
        modalOpen.value = false;
      });
    } else {
      modalStatus.value = 'error';
      modalError.value = applyResult.error || 'Не удалось применить конфигурацию';
      modalMessage.value = 'Ошибка применения';
      connection.setStatus('connectionError', {
        error: applyResult.error,
        message: applyResult.message
      });
    }
  } catch (error) {
    const apiError = error as ApiError;
    console.error('[App] Connection process failed:', apiError);
    modalStatus.value = 'error';
    modalError.value = apiError.message || 'Неизвестная ошибка';
    modalMessage.value = 'Ошибка подключения';
    connection.setStatus('connectionError', {
      error: apiError.message,
      message: 'Ошибка подключения'
    });
  }
}

function handleResetDefaults(): void {
  modalForm.value = {
    ...connection.getSavedForm(),
    password: '',
    token: ''
  };
  modalMessage.value = 'Данные восстановлены';
  modalError.value = '';
}

function handleCloseModal(): void {
  if (modalStatus.value === 'connecting') {
    return;
  }
  modalOpen.value = false;
  modalStatus.value = 'idle';
  modalMessage.value = 'Введите параметры подключения';
  modalError.value = '';
}

// Загружаем статус подключения при монтировании компонента
onMounted(async () => {
  await loadConnectionStatus();
});

// Отслеживаем изменение схемы и перезагружаем организации при необходимости
watch(
  () => connection.schema,
  (newSchema, oldSchema) => {
    // Если схема изменилась и мы подключены, перезагружаем организации
    if (newSchema && newSchema !== oldSchema && connection.status === 'connected' && connection.activeView === 'organizations') {
      console.info('[App] Schema changed, reloading organizations:', oldSchema, '→', newSchema);
      void organizationsStore.fetchOrganizations();
    }
  }
);
</script>
