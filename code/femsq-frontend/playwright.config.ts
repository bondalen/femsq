import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright конфигурация для E2E тестов FEMSQ.
 * 
 * Для запуска тестов:
 * - npm run test:e2e - запуск всех E2E тестов
 * - npm run test:e2e:ui - запуск с UI режимом
 * 
 * Требования:
 * - Backend должен быть запущен на http://localhost:8080
 * - База данных должна быть настроена через переменные окружения FEMSQ_DB_*
 */
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'npm run preview',
    url: 'http://localhost:4173',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});


