/**
 * Типы JSON экземпляра дерева и чистые функции обходника.
 * Без каталога рёбер и без API хоста.
 */

/** Как рисовать ребёнка: сразу запись или папка. */
export type RelationCard = 'N:1' | '1:1' | '1:N';

/** Действие на узле/папке. Выполняется на хосте. */
export interface RelationTreeActionSpec {
  id: string;
  kind:
    | 'create-child'
    | 'link-related'
    | 'unlink-related'
    | 'open-form'
    | 'navigate'
    | 'delete-record';
  label: string;
  icon?: string;
  scope?: 'record' | 'folder' | 'both';
  modal?: 'record' | 'none';
  form?: string;
  visibleWhen?: {
    nodeKind?: 'record' | 'folder';
    edge?: string;
    table?: string;
  };
}

/**
 * Фильтрует действия по scope относительно типа узла.
 * По умолчанию (scope не задан) — действие показывается и на записи, и на папке.
 */
function filterActionsByScope(
  actions: RelationTreeActionSpec[] | undefined,
  nodeKind: 'record' | 'folder'
): RelationTreeActionSpec[] | undefined {
  if (!actions?.length) return actions;
  return actions.filter((action) => {
    if (!action.scope) return true;
    if (action.scope === 'both') return true;
    return action.scope === nodeKind;
  });
}

/** Спека узла-ребёнка. */
export interface RelationTreeChildSpec {
  edge: string;
  to: string;
  card: RelationCard;
  folder?: string;
  title: string[];
  detail: string[] | '*';
  actions?: RelationTreeActionSpec[];
  children: RelationTreeChildSpec[];
}

/** JSON экземпляра. */
export interface RelationTreeSpec {
  id: string;
  version: number;
  root: { table: string; pk: string };
  title: string[];
  detail: string[] | '*';
  children: RelationTreeChildSpec[];
}

/** Поле детали. */
export interface RelationTreeField {
  label: string;
  value: string;
}

/** Строка, которую отдаёт хост. */
export interface RelationFetchRow {
  key: number;
  fields: Array<{ name: string; value: string | null }>;
}

/** Корень: одна строка таблицы. */
export type RelationFetchNode = (
  table: string,
  id: number
) => Promise<RelationFetchRow | null>;

/** Раскрытие ребра. */
export type RelationFetchExpand = (
  edge: string,
  fromId: number
) => Promise<RelationFetchRow[]>;

/** Узел FemsqTree, который строит обходник. */
export interface RelationTreeNode {
  id: string;
  kind: 'record' | 'folder';
  title: string;
  fields: RelationTreeField[];
  actions?: RelationTreeActionSpec[];
  children?: RelationTreeNode[];
  leaf?: boolean;
  table?: string;
  rowKey?: number;
  childSpecs?: RelationTreeChildSpec[];
  edge?: string;
  fromId?: number;
  folderSpec?: RelationTreeChildSpec;
}

/** Контекст действия, который walker отдаёт хосту. */
export interface RelationTreeActionContext {
  actionId: string;
  root: {
    table: string;
    id: number | null;
  };
  node: {
    kind: 'record' | 'folder';
    table: string | null;
    edge: string | null;
    fromId: number | null;
    rowKey: number | null;
    title: string;
    fields: Record<string, string | null>;
  };
}

const MISSING = '—';

/**
 * Таблица назначения из JSON. Каталог хоста не читаем.
 *
 * @param spec ребёнок
 * @return имя to
 */
export function childTableOf(spec: RelationTreeChildSpec): string {
  if (!spec.to) {
    throw new Error(`JSON ребёнка без to: ${spec.edge}`);
  }
  return spec.to;
}

/**
 * Токен корня: rebuild только если изменился.
 *
 * @param table таблица
 * @param id PK или null
 * @return токен
 */
export function relationRootToken(table: string, id: number | null | undefined): string {
  if (id == null) {
    return '';
  }
  return `${table}:${id}`;
}

/**
 * Нужно ли пересобирать дерево.
 *
 * @param table таблица
 * @param id PK
 * @param previous предыдущий токен
 * @return true если пара сменилась
 */
export function shouldRebuildRelationTree(
  table: string,
  id: number | null | undefined,
  previous: string
): boolean {
  return relationRootToken(table, id) !== previous;
}

/**
 * Карта имя→значение из GraphQL fields.
 *
 * @param fields поля строки
 * @return карта
 */
export function fieldMapOf(
  fields: Array<{ name: string; value: string | null }>
): Record<string, string | null> {
  const map: Record<string, string | null> = {};
  for (const field of fields) {
    map[field.name] = field.value;
  }
  return map;
}

/**
 * Заголовок из колонок spec.title.
 *
 * @param columns имена
 * @param fields карта
 * @return строка
 */
export function formatRelationTitle(
  columns: string[],
  fields: Record<string, string | null>
): string {
  return columns.map((column) => fields[column] || MISSING).join(' · ');
}

/**
 * Строки детали.
 *
 * @param detail spec.detail
 * @param fields карта
 * @return поля
 */
export function formatRelationDetail(
  detail: string[] | '*',
  fields: Record<string, string | null>
): RelationTreeField[] {
  const names = detail === '*' ? Object.keys(fields) : detail;
  return names.map((name) => ({
    label: name,
    value: fields[name] || MISSING
  }));
}

/**
 * Узел записи.
 *
 * @param table таблица
 * @param rowKey PK
 * @param fields карта
 * @param spec title/detail/children
 * @return узел
 */
export function buildRecordNode(
  table: string,
  rowKey: number,
  fields: Record<string, string | null>,
  spec: Pick<RelationTreeChildSpec, 'title' | 'detail' | 'children' | 'actions'>
): RelationTreeNode {
  const hasChildren = spec.children.length > 0;
  return {
    id: `${table}:${rowKey}`,
    kind: 'record',
    title: formatRelationTitle(spec.title, fields),
    fields: formatRelationDetail(spec.detail, fields),
    actions: filterActionsByScope(spec.actions, 'record'),
    table,
    rowKey,
    childSpecs: spec.children,
    ...(hasChildren ? { children: undefined } : { leaf: true, children: [] })
  };
}

/**
 * Папка 1:N. Дети грузятся при expand.
 *
 * @param parentId ключ родителя
 * @param fromId PK записи-родителя
 * @param spec ребёнок JSON
 * @return узел-папка
 */
export function buildFolderNode(
  parentId: string,
  fromId: number,
  spec: RelationTreeChildSpec
): RelationTreeNode {
  return {
    id: `${parentId}/${spec.edge}`,
    kind: 'folder',
    title: spec.folder || spec.edge,
    fields: [],
    actions: filterActionsByScope(spec.actions, 'folder'),
    edge: spec.edge,
    fromId,
    folderSpec: spec,
    table: childTableOf(spec),
    children: undefined
  };
}

/**
 * Дети после @load записи: N:1 сразу строки, 1:N — папка.
 *
 * @param parent запись
 * @param loaded по ребру → строки
 * @return дети
 */
export function childrenAfterRecordLoad(
  parent: RelationTreeNode,
  loaded: Record<string, Array<{ key: number; fields: Record<string, string | null> }>>
): RelationTreeNode[] {
  const specs = parent.childSpecs ?? [];
  const out: RelationTreeNode[] = [];
  for (const spec of specs) {
    if (spec.card === '1:N') {
      if (parent.rowKey == null) continue;
      out.push(buildFolderNode(parent.id, parent.rowKey, spec));
      continue;
    }
    const rows = loaded[spec.edge] ?? [];
    const to = childTableOf(spec);
    for (const row of rows) {
      out.push(buildRecordNode(to, row.key, row.fields, spec));
    }
  }
  return out;
}

/**
 * Строки папки после @load.
 *
 * @param folder папка
 * @param rows expand
 * @return дети-записи
 */
export function childrenAfterFolderLoad(
  folder: RelationTreeNode,
  rows: Array<{ key: number; fields: Record<string, string | null> }>
): RelationTreeNode[] {
  const spec = folder.folderSpec;
  if (!spec) {
    return [];
  }
  const to = childTableOf(spec);
  return rows.map((row) => buildRecordNode(to, row.key, row.fields, spec));
}

/**
 * Контекст action для хоста.
 *
 * @param rootTable таблица корня
 * @param rootId ключ корня
 * @param node выбранный узел/папка
 * @param action действие
 * @return сериализуемый контекст
 */
export function createActionContext(
  rootTable: string,
  rootId: number | null,
  node: RelationTreeNode,
  action: RelationTreeActionSpec
): RelationTreeActionContext {
  return {
    actionId: action.id,
    root: {
      table: rootTable,
      id: rootId
    },
    node: {
      kind: node.kind,
      table: node.table ?? null,
      edge: node.edge ?? null,
      fromId: node.fromId ?? null,
      rowKey: node.rowKey ?? null,
      title: node.title,
      fields: Object.fromEntries(node.fields.map((field) => [field.label, field.value === MISSING ? null : field.value]))
    }
  };
}

/**
 * Иммутабельно подставляет children узлу с данным id.
 *
 * @param nodes дерево
 * @param id ключ
 * @param children новые дети
 * @return новое дерево
 */
export function patchRelationChildren(
  nodes: RelationTreeNode[],
  id: string,
  children: RelationTreeNode[]
): RelationTreeNode[] {
  return nodes.map((node) => {
    if (node.id === id) {
      return { ...node, children };
    }
    if (!node.children) {
      return node;
    }
    return { ...node, children: patchRelationChildren(node.children, id, children) };
  });
}
