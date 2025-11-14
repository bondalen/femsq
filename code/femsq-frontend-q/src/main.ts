import { createApp } from 'vue';
import { Quasar, Notify } from 'quasar';
import { createPinia } from 'pinia';

import App from './App.vue';
import 'quasar/dist/quasar.css';
import '@quasar/extras/material-icons/material-icons.css';

function bootstrap(): void {
  console.info('[femsq-ui-q] bootstrap start');
  const appElement = document.getElementById('app');
  if (!appElement) {
    console.error('[femsq-ui-q] #app element not found!');
    return;
  }
  console.info('[femsq-ui-q] #app element found:', appElement);
  const app = createApp(App);
  app.use(createPinia());
  app.use(Quasar, {
    plugins: {
      Notify
    }
  });
  app.mount('#app');
  console.info('[femsq-ui-q] bootstrap completed, app mounted');
  console.info('[femsq-ui-q] app element after mount:', document.getElementById('app'));
}

bootstrap();
