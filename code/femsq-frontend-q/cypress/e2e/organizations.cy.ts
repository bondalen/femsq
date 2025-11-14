describe('Organizations View - K2 Scenarios', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.setupConnectionForOrganizations();
  });

  describe('Успешная загрузка организаций', () => {
    it('должен загрузить список организаций и показать детали первой организации', () => {
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

      cy.intercept('GET', '**/api/v1/organizations*', {
        statusCode: 200,
        body: organizationsResponse
      }).as('getOrganizations');

      cy.intercept('GET', '**/api/v1/organizations/1/agents', {
        statusCode: 200,
        body: agentsResponse
      }).as('getAgents');

      cy.wait('@getOrganizations', { timeout: 10000 });
      cy.wait('@getAgents', { timeout: 10000 });

      cy.contains('Организация 1').should('be.visible');
      cy.contains('Организация 2').should('be.visible');

      cy.contains('ООО "Организация 1"').should('be.visible');
      cy.contains('1234567890').should('be.visible');
      cy.contains('Агент 1').should('be.visible');
      cy.contains('Агент 2').should('be.visible');
    });

    it('должен переключиться на другую организацию и загрузить её агентов', () => {
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

      cy.intercept('GET', '**/api/v1/organizations*', {
        statusCode: 200,
        body: organizationsResponse
      }).as('getOrganizations');

      cy.intercept('GET', '**/api/v1/organizations/1/agents', {
        statusCode: 200,
        body: [{ ogAgKey: 101, code: 'Агент 1', organizationKey: 1 }]
      }).as('getAgents1');

      cy.intercept('GET', '**/api/v1/organizations/2/agents', {
        statusCode: 200,
        body: [{ ogAgKey: 201, code: 'Агент 2', organizationKey: 2 }]
      }).as('getAgents2');

      cy.wait('@getOrganizations', { timeout: 10000 });
      cy.wait('@getAgents1', { timeout: 10000 });

      cy.contains('Агент 1').should('be.visible');

      cy.contains('Организация 2').click();
      cy.wait('@getAgents2', { timeout: 10000 });

      cy.contains('Агент 2').should('be.visible');
    });
  });

  describe('Пустая выборка', () => {
    it('должен показать сообщение об отсутствии данных', () => {
      cy.intercept('GET', '**/api/v1/organizations*', {
        statusCode: 200,
        body: {
          content: [],
          totalElements: 0,
          totalPages: 0,
          number: 0,
          size: 10
        }
      }).as('getEmptyOrganizations');

      cy.wait('@getEmptyOrganizations', { timeout: 10000 });

      cy.contains('Данные отсутствуют', { timeout: 5000 }).should('be.visible');
    });
  });

  describe('Ошибка API', () => {
    it('должен показать баннер ошибки при ошибке сервера (500)', () => {
      cy.intercept('GET', '**/api/v1/organizations*', {
        statusCode: 500,
        body: { message: 'Внутренняя ошибка сервера' }
      }).as('getOrganizationsError');

      cy.wait('@getOrganizationsError', { timeout: 10000 });

      cy.contains(/Не удалось загрузить организации/i, { timeout: 5000 }).should('be.visible');
    });

    it('должен показать баннер ошибки при сетевой ошибке', () => {
      cy.intercept('GET', '**/api/v1/organizations*', {
        forceNetworkError: true
      }).as('getOrganizationsNetworkError');

      cy.wait('@getOrganizationsNetworkError', { timeout: 10000 });

      cy.contains(/Не удалось загрузить организации/i, { timeout: 5000 }).should('be.visible');
    });
  });

  describe('Фильтрация', () => {
    it('должен отфильтровать организации по названию', () => {
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

      cy.intercept('GET', '**/api/v1/organizations*', (req) => {
        if (req.query.ogName === 'Альфа') {
          req.reply({ statusCode: 200, body: filteredOrganizations });
        } else {
          req.reply({ statusCode: 200, body: allOrganizations });
        }
      }).as('getOrganizations');

      cy.intercept('GET', '**/api/v1/organizations/1/agents', {
        statusCode: 200,
        body: []
      }).as('getAgents');

      cy.wait('@getOrganizations', { timeout: 10000 });

      cy.contains('Альфа').should('be.visible');
      cy.contains('Бета').should('be.visible');
      cy.contains('Гамма').should('be.visible');

      cy.get('[data-testid="organizations-filter"]').type('Альфа');
      cy.wait('@getOrganizations', { timeout: 10000 });

      cy.contains('Альфа').should('be.visible');
      cy.contains('Бета').should('not.exist');
      cy.contains('Гамма').should('not.exist');
    });
  });

  describe('Пагинация', () => {
    it('должен переключать страницы и загружать данные', () => {
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

      cy.intercept('GET', '**/api/v1/organizations*', (req) => {
        const page = req.query.page || '0';
        if (page === '0') {
          req.reply({ statusCode: 200, body: page1Response });
        } else if (page === '1') {
          req.reply({ statusCode: 200, body: page2Response });
        }
      }).as('getOrganizations');

      cy.intercept('GET', '**/api/v1/organizations/*/agents', {
        statusCode: 200,
        body: []
      }).as('getAgents');

      cy.wait('@getOrganizations', { timeout: 10000 });

      cy.contains('Организация 1').should('be.visible');
      cy.contains('Организация 10').should('be.visible');
      cy.contains('Организация 11').should('not.exist');

      cy.get('.q-pagination').contains('2').click();
      cy.wait('@getOrganizations', { timeout: 10000 });

      cy.contains('Организация 11').should('be.visible');
      cy.contains('Организация 20').should('be.visible');
      cy.contains('Организация 1').should('not.exist');
    });
  });
});
