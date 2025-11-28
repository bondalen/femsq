/**
 * Утилиты для разрешения контекстных параметров отчётов.
 */

import type { ContextMenu, ReportMetadata } from '@/types/reports';

/**
 * Разрешает параметры отчёта на основе контекста компонента.
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
 */
function resolveExpression(
  expression: string,
  context: Record<string, string | number | boolean>
): string | number | boolean | null {
  const simpleMatch = expression.match(/^\$\{([^}]+)\}$/);
  if (simpleMatch) {
    const key = simpleMatch[1];
    const value = context[key];
    if (value !== undefined && value !== null) {
      return value;
    }
  }

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
 */
export function filterReportsByComponent<
  T extends { id: string; name: string; uiIntegration?: { contextMenus?: ContextMenu[] } }
>(reports: T[], componentName: string): Array<{ id: string; name: string; contextMenu: ContextMenu }> {
  const filtered: Array<{ id: string; name: string; contextMenu: ContextMenu }> = [];

  reports.forEach((report) => {
    const contextMenus = report.uiIntegration?.contextMenus;
    if (!contextMenus) {
      return;
    }

    const matchingMenu = contextMenus.find((menu) => menu.component === componentName);
    if (matchingMenu) {
      filtered.push({
        id: report.id,
        name: report.name,
        contextMenu: matchingMenu
      });
    }
  });

  return filtered;
}

/**
 * Проверяет, все ли обязательные параметры заполнены на основе контекста.
 */
export function areAllRequiredParametersFilled(
  metadata: ReportMetadata,
  contextParameters: Record<string, unknown>
): boolean {
  if (!metadata.parameters || metadata.parameters.length === 0) {
    return true;
  }

  return metadata.parameters.every((param) => {
    if (!param.required) {
      return true;
    }

    const hasValue =
      contextParameters[param.name] !== undefined &&
      contextParameters[param.name] !== null &&
      contextParameters[param.name] !== '';

    if (hasValue) {
      return true;
    }

    if (param.defaultValue) {
      return true;
    }

    return false;
  });
}






