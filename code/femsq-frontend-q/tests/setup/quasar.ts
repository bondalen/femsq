import { Quasar, Notify } from 'quasar';
import { beforeEach } from 'vitest';
import { config } from '@vue/test-utils';

config.global.plugins.unshift([Quasar, { plugins: { Notify } }]);

beforeEach(() => {
  Notify.setDefaults({ timeout: 0 });
});
