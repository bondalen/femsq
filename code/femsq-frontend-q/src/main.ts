import { createApp } from 'vue';
import { Dark, Quasar, Notify } from 'quasar';
import { createPinia } from 'pinia';
import { DefaultApolloClient } from '@vue/apollo-composable';

import App from './App.vue';
import { apolloClient } from './plugins/apollo';
import { applyFemsqThemeToDocument, readStoredFemsqTheme } from '@/theme/femsq-theme';
import 'quasar/dist/quasar.css';
import '@quasar/extras/material-icons/material-icons.css';
import './styles/femsq-theme-tokens.css';
import './styles/femsq-app-shell.css';
import './styles/audit-log.css';

const initialTheme = readStoredFemsqTheme();
applyFemsqThemeToDocument(initialTheme);

function bootstrap(): void {
  console.info('[femsq-ui-q] bootstrap start');
  const appElement = document.getElementById('app');
  if (!appElement) {
    console.error('[femsq-ui-q] #app element not found!');
    return;
  }
  console.info('[femsq-ui-q] #app element found:', appElement);
  const app = createApp(App);
  const pinia = createPinia();
  app.use(pinia);
  app.provide(DefaultApolloClient, apolloClient);
  app.use(Quasar, {
    plugins: {
      Notify,
      Dark
    },
    config: {
      dark: initialTheme === 'kimbie-dark'
    }
  });
  app.mount('#app');
  console.info('[femsq-ui-q] bootstrap completed, app mounted');
  console.info('[femsq-ui-q] app element after mount:', document.getElementById('app'));
}

bootstrap();
