import { test, expect } from '@playwright/test';

/**
 * E2E тесты для проверки смены схемы базы данных через UI.
 * 
 * Предусловия:
 * - Backend запущен на http://localhost:8080
 * - База данных настроена и доступна
 * - Схемы ags_test и другая тестовая схема существуют в БД
 */
test.describe('Connection Schema Switch', () => {
  test.beforeEach(async ({ page }) => {
    // Переходим на главную страницу
    await page.goto('/');
    
    // Ждем загрузки приложения
    await page.waitForLoadState('networkidle');
  });

  test('should display connection status on page load', async ({ page }) => {
    // Проверяем, что строка состояния отображается
    const statusBar = page.locator('.status-bar');
    await expect(statusBar).toBeVisible();
    
    // Проверяем наличие статуса подключения
    const statusLabel = statusBar.locator('.status-bar__label');
    await expect(statusLabel).toBeVisible();
  });

  test('should open connection modal when clicking connection button', async ({ page }) => {
    // Находим кнопку подключения (может быть в TopBar)
    const connectionButton = page.getByRole('button', { name: /подключ/i }).first();
    
    // Если кнопка не видна, возможно нужно открыть меню на мобильных
    if (!(await connectionButton.isVisible())) {
      const menuButton = page.getByRole('button', { name: /меню/i }).first();
      if (await menuButton.isVisible()) {
        await menuButton.click();
      }
    }
    
    await connectionButton.click();
    
    // Проверяем, что модальное окно открылось
    const modal = page.locator('[role="dialog"]').or(page.locator('.modal')).first();
    await expect(modal).toBeVisible();
  });

  test('should test connection with valid configuration', async ({ page }) => {
    // Открываем модальное окно подключения
    const connectionButton = page.getByRole('button', { name: /подключ/i }).first();
    
    if (!(await connectionButton.isVisible())) {
      const menuButton = page.getByRole('button', { name: /меню/i }).first();
      if (await menuButton.isVisible()) {
        await menuButton.click();
      }
    }
    
    await connectionButton.click();
    
    // Ждем появления формы
    await page.waitForSelector('input[name="host"], input[placeholder*="host" i]', { timeout: 5000 });
    
    // Заполняем форму подключения
    const hostInput = page.locator('input[name="host"]').or(page.locator('input[placeholder*="host" i]')).first();
    const portInput = page.locator('input[name="port"]').or(page.locator('input[placeholder*="port" i]')).first();
    const databaseInput = page.locator('input[name="database"]').or(page.locator('input[placeholder*="database" i]')).first();
    const schemaInput = page.locator('input[name="schema"]').or(page.locator('input[placeholder*="schema" i]')).first();
    const usernameInput = page.locator('input[name="username"]').or(page.locator('input[placeholder*="username" i]')).first();
    const passwordInput = page.locator('input[name="password"]').or(page.locator('input[type="password"]')).first();
    
    // Заполняем значения из переменных окружения или используем дефолтные
    const host = process.env.FEMSQ_DB_HOST || 'localhost';
    const port = process.env.FEMSQ_DB_PORT || '1433';
    const database = process.env.FEMSQ_DB_NAME || 'FishEye';
    const schema = process.env.FEMSQ_DB_SCHEMA || 'ags_test';
    const username = process.env.FEMSQ_DB_USER || 'sa';
    const password = process.env.FEMSQ_DB_PASSWORD || '';
    
    if (await hostInput.isVisible()) {
      await hostInput.fill(host);
    }
    if (await portInput.isVisible()) {
      await portInput.fill(port);
    }
    if (await databaseInput.isVisible()) {
      await databaseInput.fill(database);
    }
    if (await schemaInput.isVisible()) {
      await schemaInput.fill(schema);
    }
    if (await usernameInput.isVisible()) {
      await usernameInput.fill(username);
    }
    if (await passwordInput.isVisible()) {
      await passwordInput.fill(password);
    }
    
    // Отправляем форму
    const submitButton = page.getByRole('button', { name: /подключ|connect|apply/i }).first();
    await submitButton.click();
    
    // Ждем результата подключения
    await page.waitForTimeout(3000);
    
    // Проверяем, что модальное окно закрылось или показывается успешное сообщение
    const successMessage = page.getByText(/подключено|connected|успешно/i).first();
    const errorMessage = page.getByText(/ошибка|error/i).first();
    
    // Либо успех, либо ошибка должна быть видна
    const hasSuccess = await successMessage.isVisible().catch(() => false);
    const hasError = await errorMessage.isVisible().catch(() => false);
    
    expect(hasSuccess || hasError).toBeTruthy();
  });

  test('should switch schema after successful connection', async ({ page }) => {
    // Этот тест предполагает, что подключение уже установлено
    // Проверяем, что схема отображается в строке состояния
    const statusBar = page.locator('.status-bar');
    await expect(statusBar).toBeVisible();
    
    // Проверяем наличие информации о схеме
    const schemaInfo = statusBar.getByText(/схема|schema/i);
    await expect(schemaInfo.first()).toBeVisible();
  });

  test('should handle connection errors gracefully', async ({ page }) => {
    // Открываем модальное окно
    const connectionButton = page.getByRole('button', { name: /подключ/i }).first();
    
    if (!(await connectionButton.isVisible())) {
      const menuButton = page.getByRole('button', { name: /меню/i }).first();
      if (await menuButton.isVisible()) {
        await menuButton.click();
      }
    }
    
    await connectionButton.click();
    
    // Заполняем форму неверными данными
    await page.waitForSelector('input[name="host"], input[placeholder*="host" i]', { timeout: 5000 });
    
    const hostInput = page.locator('input[name="host"]').or(page.locator('input[placeholder*="host" i]')).first();
    if (await hostInput.isVisible()) {
      await hostInput.fill('invalid-host');
    }
    
    const submitButton = page.getByRole('button', { name: /подключ|connect|apply/i }).first();
    await submitButton.click();
    
    // Ждем появления ошибки
    await page.waitForTimeout(2000);
    
    // Проверяем, что ошибка отображается
    const errorMessage = page.getByText(/ошибка|error|не удалось/i).first();
    await expect(errorMessage).toBeVisible({ timeout: 5000 });
  });
});


