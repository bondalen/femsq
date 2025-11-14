import { createApp } from 'vue';
import { createPinia } from 'pinia';

import App from './App.vue';
import './styles/base.css';

/**
 * Инициализирует и монтирует frontend-приложение FEMSQ.
 * Добавлено логирование для отслеживания шага загрузки.
 */
function bootstrapApplication(): void {
  console.info('[femsq-ui] bootstrap start');
  const app = createApp(App);
  app.use(createPinia());
  app.mount('#app');
  console.info('[femsq-ui] bootstrap completed');
}

bootstrapApplication();
