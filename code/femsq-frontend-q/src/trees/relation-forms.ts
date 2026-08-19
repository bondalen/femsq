/**
 * Контракт универсальной формы записи / связи для хоста FEMSQ.
 * Walker не исполняет форму, а только инициирует action.
 */
import type { RelationTreeSpec } from '@/trees/relation-tree';
import type { FemsqTableColumn } from 'fequlib';

/** Режим формы. */
export type RelationFormMode = 'create' | 'edit' | 'view';

/** Базовые типы полей v1. */
export type RelationFormFieldKind =
  | 'display'
  | 'text'
  | 'number'
  | 'date'
  | 'boolean'
  | 'fk-single'
  | 'enum-fk'
  | 'readonly-fixed';

/** Простое поле формы. */
export interface RelationFormFieldState {
  name: string;
  label: string;
  kind: RelationFormFieldKind;
  required?: boolean;
  locked?: boolean;
  value: string | number | boolean | null;
  displayValue?: string | null;
}

/** Строка кандидата в picker-таблице. */
export interface RelationPickerRow {
  rowKey: string;
  [key: string]: string | number | null;
}

/** Описание picker-вкладки. */
export interface RelationPickerState {
  id: string;
  kind: 'lookup-list' | 'table-tree-picker';
  tabLabel: string;
  valueField: string;
  displayField?: string;
  disabled?: boolean;
  searchValue?: string;
  searchPlaceholder?: string;
  searchHint?: string;
  searchDebounceMs?: number;
  rows: RelationPickerRow[];
  columns: FemsqTableColumn<RelationPickerRow>[];
  selected: RelationPickerRow[];
  treeSpec?: RelationTreeSpec;
  treeRootId?: number | null;
}

/** Состояние модалки формы. */
export interface RelationFormState {
  id: string;
  title: string;
  mode: RelationFormMode;
  fields: RelationFormFieldState[];
  pickers: RelationPickerState[];
}
