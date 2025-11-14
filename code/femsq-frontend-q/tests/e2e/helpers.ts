import { Page } from '@playwright/test';

/**
 * Настраивает состояние подключения для доступа к экрану организаций
 */
export async function setupConnectionForOrganizations(page: Page): Promise<void> {
  await page.goto('/');
  
  // Настраиваем состояние подключения через Pinia store
  await page.evaluate(() => {
    const win = window as any;
    // Пытаемся получить доступ к Pinia через различные способы
    const app = win.__VUE_APP__ || win.__app__;
    if (app?.config?.globalProperties?.$pinia) {
      const pinia = app.config.globalProperties.$pinia;
      const connectionStore = pinia._s?.get('connection');
      if (connectionStore) {
        connectionStore.setStatus('connected', {
          schema: 'ags_test',
          user: 'test',
          message: 'Подключено для тестирования'
        });
        connectionStore.navigate('organizations');
      }
    } else if (win.__PINIA__) {
      // Альтернативный способ доступа к Pinia
      const pinia = win.__PINIA__;
      const connectionStore = pinia._s?.get('connection');
      if (connectionStore) {
        connectionStore.setStatus('connected', {
          schema: 'ags_test',
          user: 'test',
          message: 'Подключено для тестирования'
        });
        connectionStore.navigate('organizations');
      }
    }
  });

  // Ждём, пока приложение переключится на экран организаций
  // Проверяем наличие заголовка "Организации" или таблицы
  await page.waitForSelector('text=Организации', { timeout: 5000 }).catch(() => {
    // Если заголовок не найден, просто ждём немного для инициализации
  });
}
