<template>
  <section class="organizations-view">
    <header class="organizations-view__header">
      <div>
        <h1>Организации</h1>
        <p class="organizations-view__subtitle">
          {{ headerMessage }}
        </p>
      </div>
      <div class="organizations-view__meta">
        <span class="organizations-view__counter">Найдено: {{ total }}</span>
        <span v-if="lastLoadedAt" class="organizations-view__timestamp">Обновлено: {{ formattedTimestamp }}</span>
      </div>
    </header>

    <div v-if="error" class="organizations-view__alert organizations-view__alert--error">
      <span>{{ error }}</span>
      <button type="button" @click="reload">Повторить</button>
    </div>

    <div v-else-if="loading" class="organizations-view__alert organizations-view__alert--info">
      <span>Загрузка организаций…</span>
    </div>

    <div v-else class="organizations-view__layout" :data-empty="!hasData">
      <div v-if="hasData" class="organizations-view__table">
        <table>
          <thead>
            <tr>
              <th>Код</th>
              <th>Название</th>
              <th>Тип</th>
              <th>Регион</th>
              <th>Контрактов</th>
              <th>Обновлено</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="organization in organizations"
              :key="organization.id"
              :data-active="organization.id === selectedId"
              @click="selectOrganization(organization.id)"
            >
              <td>{{ organization.ogKey }}</td>
              <td class="organizations-view__cell-name">{{ organization.ogName }}</td>
              <td>{{ organization.ogType }}</td>
              <td>{{ organization.region }}</td>
              <td>{{ organization.contractsCount }}</td>
              <td>{{ formatDate(organization.updatedAt) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-else class="organizations-view__empty">
        <p>Организации не найдены. Измените фильтры или повторите загрузку.</p>
        <button type="button" @click="reload">Обновить</button>
      </div>

      <aside class="organizations-view__details">
        <div v-if="selected">
          <header class="organizations-view__details-header">
            <h2>{{ selected.ogName }}</h2>
            <span class="organizations-view__badge">{{ selected.ogType }}</span>
          </header>

          <dl class="organizations-view__details-grid">
            <div>
              <dt>Код</dt>
              <dd>{{ selected.ogKey }}</dd>
            </div>
            <div>
              <dt>Регион</dt>
              <dd>{{ selected.region || '—' }}</dd>
            </div>
            <div>
              <dt>ИНН</dt>
              <dd>{{ selected.inn || '—' }}</dd>
            </div>
            <div>
              <dt>ОГРН</dt>
              <dd>{{ selected.ogrn || '—' }}</dd>
            </div>
            <div>
              <dt>Адрес</dt>
              <dd>{{ selected.address || '—' }}</dd>
            </div>
            <div>
              <dt>Контакт</dt>
              <dd>{{ selected.contactPerson || '—' }}</dd>
            </div>
          </dl>

          <p v-if="selected.description" class="organizations-view__description">{{ selected.description }}</p>

          <section class="organizations-view__agents">
            <header>
              <h3>Связанные агенты</h3>
              <span>{{ agents.length }}</span>
            </header>

            <div v-if="agents.length === 0" class="organizations-view__agents-empty">
              Агенты не назначены
            </div>
            <table v-else>
              <thead>
                <tr>
                  <th>Код</th>
                  <th>Название</th>
                  <th>Роль</th>
                  <th>Контакты</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="agent in agents" :key="agent.id">
                  <td>{{ agent.agentKey }}</td>
                  <td>{{ agent.agentName }}</td>
                  <td>{{ agent.role }}</td>
                  <td>
                    <div class="organizations-view__agents-contact">
                      <span>{{ agent.phone || '—' }}</span>
                      <span>{{ agent.email || '—' }}</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </section>
        </div>
        <div v-else class="organizations-view__details-empty">
          <p>Выберите организацию для просмотра подробностей.</p>
        </div>
      </aside>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import { useOrganizationsStore } from '@/stores/organizations';

const organizationsStore = useOrganizationsStore();
const loading = computed(() => organizationsStore.loading);
const error = computed(() => organizationsStore.error);
const organizations = computed(() => organizationsStore.organizations);
const selected = computed(() => organizationsStore.selectedOrganization);
const selectedId = computed(() => organizationsStore.selectedId);
const agents = computed(() => organizationsStore.agents);
const total = computed(() => organizationsStore.total);
const hasData = computed(() => organizationsStore.hasData);
const lastLoadedAt = computed(() => organizationsStore.lastLoadedAt);

const headerMessage = computed(() => {
  if (loading.value) {
    return 'Загрузка данных о организациях…';
  }
  if (error.value) {
    return 'Произошла ошибка при загрузке.';
  }
  if (!hasData.value) {
    return 'Данные отсутствуют. Попробуйте изменить фильтры.';
  }
  return 'Выберите организацию, чтобы увидеть подробности и связанных агентов.';
});

const formattedTimestamp = computed(() => {
  if (!lastLoadedAt.value) {
    return '';
  }
  return new Date(lastLoadedAt.value).toLocaleString('ru-RU');
});

function selectOrganization(id: string): void {
  organizationsStore.selectOrganization(id);
}

function formatDate(value: string): string {
  if (!value) {
    return '—';
  }
  return new Date(value).toLocaleDateString('ru-RU');
}

function reload(): void {
  organizationsStore.loadOrganizations({ latencyMs: 600 });
}
</script>

<style scoped>
.organizations-view {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.organizations-view__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.organizations-view__subtitle {
  margin: 4px 0 0;
  color: rgba(28, 35, 51, 0.68);
}

.organizations-view__meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-end;
  font-size: 14px;
  color: rgba(28, 35, 51, 0.64);
}

.organizations-view__counter {
  font-weight: 600;
}

.organizations-view__alert {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  border-radius: 14px;
  font-size: 14px;
}

.organizations-view__alert--info {
  background: rgba(14, 165, 233, 0.1);
  border: 1px solid rgba(14, 165, 233, 0.2);
  color: #0369a1;
}

.organizations-view__alert--error {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
  color: #b91c1c;
}

.organizations-view__alert button {
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-weight: 600;
}

.organizations-view__layout {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  gap: 24px;
}

.organizations-view__layout[data-empty='true'] {
  grid-template-columns: 1fr;
}

.organizations-view__table {
  background: white;
  border-radius: 20px;
  box-shadow: 0 18px 36px rgba(28, 35, 51, 0.06);
  overflow: hidden;
}

.organizations-view__table table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

.organizations-view__table thead {
  background: rgba(28, 35, 51, 0.05);
}

.organizations-view__table th,
.organizations-view__table td {
  padding: 12px 16px;
  border-bottom: 1px solid rgba(28, 35, 51, 0.08);
  text-align: left;
}

.organizations-view__table tbody tr {
  cursor: pointer;
  transition: background 0.15s ease;
}

.organizations-view__table tbody tr[data-active='true'] {
  background: rgba(47, 122, 206, 0.12);
}

.organizations-view__table tbody tr:hover {
  background: rgba(47, 122, 206, 0.08);
}

.organizations-view__cell-name {
  font-weight: 600;
}

.organizations-view__details {
  background: white;
  border-radius: 20px;
  box-shadow: 0 18px 36px rgba(28, 35, 51, 0.06);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.organizations-view__details-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.organizations-view__badge {
  background: rgba(47, 122, 206, 0.12);
  color: #2f7ace;
  border-radius: 999px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
}

.organizations-view__details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
  gap: 12px 16px;
}

.organizations-view__details-grid dt {
  font-size: 12px;
  text-transform: uppercase;
  color: rgba(28, 35, 51, 0.48);
}

.organizations-view__details-grid dd {
  margin: 0;
  font-weight: 600;
}

.organizations-view__description {
  margin: 0;
  font-size: 14px;
  line-height: 1.5;
  color: rgba(28, 35, 51, 0.72);
}

.organizations-view__agents {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.organizations-view__agents header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 600;
}

.organizations-view__agents table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  border: 1px solid rgba(28, 35, 51, 0.08);
  border-radius: 16px;
  overflow: hidden;
}

.organizations-view__agents th,
.organizations-view__agents td {
  padding: 10px 12px;
  border-bottom: 1px solid rgba(28, 35, 51, 0.08);
}

.organizations-view__agents tbody tr:last-child td {
  border-bottom: none;
}

.organizations-view__agents-contact {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.organizations-view__agents-empty {
  padding: 12px;
  border-radius: 12px;
  background: rgba(28, 35, 51, 0.04);
  font-size: 13px;
  color: rgba(28, 35, 51, 0.6);
}

.organizations-view__details-empty,
.organizations-view__empty {
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: center;
  justify-content: center;
  color: rgba(28, 35, 51, 0.6);
  text-align: center;
}

.organizations-view__empty button,
.organizations-view__details-empty button {
  border-radius: 999px;
  border: 1px solid rgba(28, 35, 51, 0.12);
  background: white;
  padding: 10px 18px;
  cursor: pointer;
}

@media (max-width: 1024px) {
  .organizations-view__layout {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .organizations-view__header {
    flex-direction: column;
    align-items: flex-start;
  }

  .organizations-view__meta {
    align-items: flex-start;
  }
}
</style>
