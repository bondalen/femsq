// Custom Cypress commands will be defined here.

declare global {
  namespace Cypress {
    interface Chainable {
      /**
       * Настраивает состояние подключения для доступа к экрану организаций
       */
      setupConnectionForOrganizations(): Chainable<void>;
    }
  }
}

Cypress.Commands.add('setupConnectionForOrganizations', () => {
  cy.window().then((win) => {
    // Пытаемся получить доступ к Pinia через различные способы
    const app = (win as any).__VUE_APP__ || (win as any).__app__;
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
    } else if ((win as any).__PINIA__) {
      // Альтернативный способ доступа к Pinia
      const pinia = (win as any).__PINIA__;
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
});

export {};
