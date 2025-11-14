import { test, expect } from '@playwright/test';
import { setupConnectionForOrganizations } from './helpers';

test.describe('Organizations View - K2 Scenarios', () => {
  test.beforeEach(async ({ page }) => {
    await setupConnectionForOrganizations(page);
  });

  test.describe('Успешная загрузка организаций', () => {
    test('должен загрузить список организаций и показать детали первой организации', async ({ page }) => {
      const organizationsResponse = {
        content: [
          {
            ogKey: 1,
            ogName: 'Организация 1',
            ogOfficialName: 'ООО "Организация 1"',
            ogFullName: 'Общество с ограниченной ответственностью "Организация 1"',
            inn: 1234567890,
            kpp: 123456789,
            ogrn: 1234567890123,
            okpo: 12345678,
            registrationTaxType: 'REG',
            ogDescription: 'Тестовая организация 1'
          },
          {
            ogKey: 2,
            ogName: 'Организация 2',
            ogOfficialName: 'ООО "Организация 2"',
            ogFullName: 'Общество с ограниченной ответственностью "Организация 2"',
            inn: 9876543210,
            kpp: 987654321,
            registrationTaxType: 'SIMPLIFIED'
          }
        ],
        totalElements: 2,
        totalPages: 1,
        number: 0,
        size: 10
      };

      const agentsResponse = [
        {
          ogAgKey: 101,
          code: 'Агент 1',
          organizationKey: 1,
          legacyOid: 'legacy-001'
        },
        {
          ogAgKey: 102,
          code: 'Агент 2',
          organizationKey: 1
        }
      ];

      // Мокируем API запросы
      await page.route('**/api/v1/organizations*', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(organizationsResponse)
        });
      });

      await page.route('**/api/v1/organizations/1/agents', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(agentsResponse)
        });
      });

      // Ждём загрузки данных
      await page.waitForResponse('**/api/v1/organizations*');
      await page.waitForResponse('**/api/v1/organizations/1/agents');

      // Проверяем отображение организаций
      await expect(page.getByText('Организация 1')).toBeVisible();
      await expect(page.getByText('Организация 2')).toBeVisible();

      // Проверяем детали первой организации
      await expect(page.getByText('ООО "Организация 1"')).toBeVisible();
      await expect(page.getByText('1234567890')).toBeVisible();
      await expect(page.getByText('Агент 1')).toBeVisible();
      await expect(page.getByText('Агент 2')).toBeVisible();
    });

    test('должен переключиться на другую организацию и загрузить её агентов', async ({ page }) => {
      const organizationsResponse = {
        content: [
          { ogKey: 1, ogName: 'Организация 1', ogOfficialName: 'ООО "Организация 1"', ogFullName: 'ООО "Организация 1"' },
          { ogKey: 2, ogName: 'Организация 2', ogOfficialName: 'ООО "Организация 2"', ogFullName: 'ООО "Организация 2"' }
        ],
        totalElements: 2,
        totalPages: 1,
        number: 0,
        size: 10
      };

      let agentsCallCount = 0;

      await page.route('**/api/v1/organizations*', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(organizationsResponse)
        });
      });

      await page.route('**/api/v1/organizations/*/agents', (route) => {
        const url = new URL(route.request().url());
        const orgKey = url.pathname.split('/').slice(-2, -1)[0];
        
        agentsCallCount++;
        if (orgKey === '1') {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify([{ ogAgKey: 101, code: 'Агент 1', organizationKey: 1 }])
          });
        } else if (orgKey === '2') {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify([{ ogAgKey: 201, code: 'Агент 2', organizationKey: 2 }])
          });
        }
      });

      await page.waitForResponse('**/api/v1/organizations*');
      await page.waitForResponse('**/api/v1/organizations/1/agents');

      await expect(page.getByText('Агент 1')).toBeVisible();

      // Кликаем на вторую организацию
      await page.getByText('Организация 2').click();
      await page.waitForResponse('**/api/v1/organizations/2/agents');

      await expect(page.getByText('Агент 2')).toBeVisible();
    });
  });

  test.describe('Пустая выборка', () => {
    test('должен показать сообщение об отсутствии данных', async ({ page }) => {
      await page.route('**/api/v1/organizations*', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            content: [],
            totalElements: 0,
            totalPages: 0,
            number: 0,
            size: 10
          })
        });
      });

      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText('Данные отсутствуют')).toBeVisible({ timeout: 5000 });
    });
  });

  test.describe('Ошибка API', () => {
    test('должен показать баннер ошибки при ошибке сервера (500)', async ({ page }) => {
      await page.route('**/api/v1/organizations*', (route) => {
        route.fulfill({
          status: 500,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'Внутренняя ошибка сервера' })
        });
      });

      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText(/Не удалось загрузить организации/i)).toBeVisible({ timeout: 5000 });
    });

    test('должен показать баннер ошибки при сетевой ошибке', async ({ page }) => {
      await page.route('**/api/v1/organizations*', (route) => {
        route.abort('failed');
      });

      // Ждём, пока запрос завершится с ошибкой
      await page.waitForTimeout(2000);

      await expect(page.getByText(/Не удалось загрузить организации/i)).toBeVisible({ timeout: 5000 });
    });
  });

  test.describe('Фильтрация', () => {
    test('должен отфильтровать организации по названию', async ({ page }) => {
      const allOrganizations = {
        content: [
          { ogKey: 1, ogName: 'Альфа', ogOfficialName: 'ООО "Альфа"', ogFullName: 'ООО "Альфа"' },
          { ogKey: 2, ogName: 'Бета', ogOfficialName: 'ООО "Бета"', ogFullName: 'ООО "Бета"' },
          { ogKey: 3, ogName: 'Гамма', ogOfficialName: 'ООО "Гамма"', ogFullName: 'ООО "Гамма"' }
        ],
        totalElements: 3,
        totalPages: 1,
        number: 0,
        size: 10
      };

      const filteredOrganizations = {
        content: [
          { ogKey: 1, ogName: 'Альфа', ogOfficialName: 'ООО "Альфа"', ogFullName: 'ООО "Альфа"' }
        ],
        totalElements: 1,
        totalPages: 1,
        number: 0,
        size: 10
      };

      await page.route('**/api/v1/organizations*', (route) => {
        const url = new URL(route.request().url());
        const ogName = url.searchParams.get('ogName');
        
        if (ogName === 'Альфа') {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify(filteredOrganizations)
          });
        } else {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify(allOrganizations)
          });
        }
      });

      await page.route('**/api/v1/organizations/1/agents', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([])
        });
      });

      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText('Альфа')).toBeVisible();
      await expect(page.getByText('Бета')).toBeVisible();
      await expect(page.getByText('Гамма')).toBeVisible();

      // Вводим фильтр
      const filterInput = page.getByTestId('organizations-filter');
      await filterInput.fill('Альфа');
      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText('Альфа')).toBeVisible();
      await expect(page.getByText('Бета')).not.toBeVisible();
      await expect(page.getByText('Гамма')).not.toBeVisible();
    });
  });

  test.describe('Пагинация', () => {
    test('должен переключать страницы и загружать данные', async ({ page }) => {
      const page1Response = {
        content: Array.from({ length: 10 }, (_, i) => ({
          ogKey: i + 1,
          ogName: `Организация ${i + 1}`,
          ogOfficialName: `ООО "Организация ${i + 1}"`,
          ogFullName: `ООО "Организация ${i + 1}"`
        })),
        totalElements: 25,
        totalPages: 3,
        number: 0,
        size: 10
      };

      const page2Response = {
        content: Array.from({ length: 10 }, (_, i) => ({
          ogKey: i + 11,
          ogName: `Организация ${i + 11}`,
          ogOfficialName: `ООО "Организация ${i + 11}"`,
          ogFullName: `ООО "Организация ${i + 11}"`
        })),
        totalElements: 25,
        totalPages: 3,
        number: 1,
        size: 10
      };

      await page.route('**/api/v1/organizations*', (route) => {
        const url = new URL(route.request().url());
        const pageParam = url.searchParams.get('page') || '0';
        
        if (pageParam === '0') {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify(page1Response)
          });
        } else if (pageParam === '1') {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify(page2Response)
          });
        }
      });

      await page.route('**/api/v1/organizations/*/agents', (route) => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([])
        });
      });

      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText('Организация 1')).toBeVisible();
      await expect(page.getByText('Организация 10')).toBeVisible();
      await expect(page.getByText('Организация 11')).not.toBeVisible();

      // Кликаем на страницу 2
      await page.locator('.q-pagination').getByText('2').click();
      await page.waitForResponse('**/api/v1/organizations*');

      await expect(page.getByText('Организация 11')).toBeVisible();
      await expect(page.getByText('Организация 20')).toBeVisible();
      await expect(page.getByText('Организация 1')).not.toBeVisible();
    });
  });
});
