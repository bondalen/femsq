/**
 * TypeScript типы для модуля отчётов.
 *
 * Соответствуют моделям backend (com.femsq.reports.model).
 */

/**
 * Базовая информация об отчёте для отображения в каталоге.
 */
export interface ReportInfo {
  id: string;
  name: string;
  description?: string;
  category?: string;
  tags: string[];
  source: 'embedded' | 'external';
  thumbnail?: string;
  uiIntegration?: UiIntegration;
}

/**
 * Полные метаданные отчёта.
 */
export interface ReportMetadata {
  id: string;
  version: string;
  name: string;
  description?: string;
  category?: string;
  author?: string;
  created: string;
  lastModified: string;
  files: ReportFiles;
  parameters?: ReportParameter[];
  uiIntegration?: UiIntegration;
  tags?: string[];
  accessLevel?: string;
}

/**
 * Информация о файлах отчёта.
 */
export interface ReportFiles {
  template: string;
  compiled?: string;
  thumbnail?: string;
}

/**
 * Параметр отчёта.
 */
export interface ReportParameter {
  name: string;
  type: 'string' | 'integer' | 'long' | 'double' | 'boolean' | 'date' | 'enum';
  label: string;
  description?: string;
  required: boolean;
  defaultValue?: string;
  validation?: ParameterValidation;
  options?: ParameterOption[];
  source?: ParameterSource;
}

/**
 * Валидация параметра.
 */
export interface ParameterValidation {
  min?: number;
  max?: number;
  pattern?: string;
  minDate?: string;
  maxDate?: string;
}

/**
 * Опция для enum типа параметра.
 */
export interface ParameterOption {
  value: string | number;
  label: string;
}

/**
 * Источник данных для загрузки опций параметра.
 */
export interface ParameterSource {
  type: 'api';
  endpoint: string;
  valueField: string;
  labelField: string;
}

/**
 * Интеграция с UI компонентами.
 */
export interface UiIntegration {
  showInReportsList: boolean;
  contextMenus?: ContextMenu[];
}

/**
 * Контекстное меню для UI компонента.
 */
export interface ContextMenu {
  component: string;
  label: string;
  icon?: string;
  parameterMapping: Record<string, string>;
}

/**
 * Запрос на генерацию отчёта.
 */
export interface ReportGenerationRequest {
  reportId: string;
  parameters: Record<string, unknown>;
  format: 'pdf' | 'excel' | 'html';
}

/**
 * Результат генерации отчёта.
 */
export interface ReportGenerationResult {
  reportId: string;
  format: string;
  content: Blob;
  fileName: string;
  size: number;
  generatedAt: string;
}






