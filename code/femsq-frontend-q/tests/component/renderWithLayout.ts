import { defineComponent } from 'vue';
import { defineComponent } from 'vue';
import { render } from '@testing-library/vue';
import { QLayout, QPageContainer } from 'quasar';

export function renderOrganizationsView(component: unknown, options: Record<string, unknown> = {}) {
  const Host = defineComponent({
    name: 'OrganizationsViewHost',
    components: { TestComponent: component as any, QLayout, QPageContainer },
    template: '<q-layout view="lHh Lpr lFf"><q-page-container><TestComponent /></q-page-container></q-layout>'
  });

  return render(Host, options);
}
