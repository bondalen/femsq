import { defineComponent } from 'vue';
import { render } from '@testing-library/vue';
import { QLayout, QPageContainer } from 'quasar';

export function renderInvestmentChainsView(component: unknown, options: Record<string, unknown> = {}) {
  const Host = defineComponent({
    name: 'InvestmentChainsViewHost',
    components: { TestComponent: component as any, QLayout, QPageContainer },
    template: '<q-layout view="lHh Lpr lFf"><q-page-container><TestComponent /></q-page-container></q-layout>'
  });

  return render(Host, options);
}
