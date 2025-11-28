/**
 * Утилиты для разрешения контекстных параметров отчётов.
 */

import type { ReportMetadata, ContextMenu } from '@/types/reports';

/**
 * Разрешает параметры отчёта на основе контекста компонента.
 *
 * @param contextMenu конфигурация контекстного меню из метаданных отчёта
 * @param context контекст компонента (например, { contractorId: '123', contractorName: 'ООО "Рога и копыта"' })
 * @returns объект с разрешёнными параметрами
 */
export function resolveContextParameters(
  contextMenu: ContextMenu,
  context: Record<string, string | number | boolean>
): Record<string, unknown> {
  const resolved: Record<string, unknown> = {};

  Object.entries(contextMenu.parameterMapping).forEach(([paramName, expression]) => {
    const value = resolveExpression(expression, context);
    if (value !== null && value !== undefined) {
      resolved[paramName] = value;
    }
  });

  return resolved;
}

/**
 * Разрешает выражение вида ${key} или ${key.property} на основе контекста.
 *
 * @param expression выражение для разрешения (например, "${contractor.id}" или "${contractor.name}")
 * @param context контекст компонента
 * @returns разрешённое значение или null
 */
function resolveExpression(
  expression: string,
  context: Record<string, string | number | boolean>
): string | number | boolean | null {
  // Простое разрешение ${key}
  const simpleMatch = expression.match(/^\$\{([^}]+)\}$/);
  if (simpleMatch) {
    const key = simpleMatch[1];
    const value = context[key];
    if (value !== undefined && value !== null) {
      return value;
    }
  }

  // Разрешение вложенных свойств ${key.property} - упрощённая версия
  // В реальном приложении может потребоваться более сложная логика
  const nestedMatch = expression.match(/^\$\{([^.]+)\.([^}]+)\}$/);
  if (nestedMatch) {
    const [, objectKey, propertyKey] = nestedMatch;
    const object = context[objectKey];
    if (object && typeof object === 'object') {
      const value = (object as Record<string, unknown>)[propertyKey];
      if (value !== undefined && value !== null) {
        return String(value);
      }
    }
  }

  return null;
}

/**
 * Фильтрует отчёты по компоненту для контекстного меню.
 *
 * @param reports список всех отчётов
 * @param componentName имя компонента (например, "ContractorCard")
 * @returns список отчётов, доступных для данного компонента
 */
export function filterReportsByComponent(
  reports: Array<{ uiIntegration?: { contextMenus?: ContextMenu[] } }>,
  componentName: string
): Array<{ id: string; name: string; contextMenu: ContextMenu }> {
  const filtered: Array<{ id: string; name: string; contextMenu: ContextMenu }> = [];

  reports.forEach((report) => {
    const contextMenus = report.uiIntegration?.contextMenus;
    if (!contextMenus) {
      return;
    }

    const matchingMenu = contextMenus.find((menu) => menu.component === componentName);
    if (matchingMenu) {
      // Предполагаем, что у report есть id и name
      filtered.push({
        id: (report as { id: string }).id,
        name: (report as { name: string }).name,
        contextMenu: matchingMenu
      });
    }
  });

  return filtered;
}

/**
 * Проверяет, все ли обязательные параметры заполнены на основе контекста.
 *
 * @param metadata метаданные отчёта
 * @param contextParameters уже разрешённые параметры из контекста
 * @returns true, если все обязательные параметры заполнены
 */
export function areAllRequiredParametersFilled(
  metadata: ReportMetadata,
  contextParameters: Record<string, unknown>
): boolean {
  if (!metadata.parameters || metadata.parameters.length === 0) {
    return true; // Нет параметров - всё заполнено
  }

  return metadata.parameters.every((param) => {
    if (!param.required) {
      return true; // Параметр не обязательный
    }

    // Проверяем, есть ли значение в контекстных параметрах или defaultValue
    const hasValue = contextParameters[param.name] !== undefined &&
                     contextParameters[param.name] !== null &&
                     contextParameters[param.name] !== '';

    if (hasValue) {
      return true;
    }

    // Если есть defaultValue, считаем, что параметр заполнен
    if (param.defaultValue) {
      return true;
    }

    return false;
  });
}
