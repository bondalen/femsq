import { defineComponent } from 'vue';
import { render } from '@testing-library/vue';
import { QLayout, QPageContainer } from 'quasar';

/**
 * Рендерит ConstructionSitesView внутри QLayout (нужен для QPage).
 */
export function renderConstructionSitesView(
  component: unknown,
  options: Record<string, unknown> = {}
) {
  const Host = defineComponent({
    name: 'ConstructionSitesViewHost',
    components: { TestComponent: component as object, QLayout, QPageContainer },
    template:
      '<q-layout view="lHh Lpr lFf"><q-page-container><TestComponent /></q-page-container></q-layout>'
  });

  return render(Host, options);
}
