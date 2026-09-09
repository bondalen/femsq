/**
 * Узлы FemsqTree карточки канона Dbt (S78.4C) и вкладки комментариев.
 */

import { formatMoney } from 'fequlib';

import type { SudzDbtCanonComment, SudzDbtCanonSlot } from '@/types/sudz';

export type CanonTreeKind = 'dbt' | 'slot' | 'var' | 'value' | 'comment';

/** Группа года для комментария. */
export type CanonCommentGroupKind = 'official' | 'new' | 'other';

/** Тип текста cnInvCmm: 1 мероприятия, 8 куратор. */
export type CanonCommentTypeKind = 'mery' | 'curator';

/**
 * Комментарий на DbtValue (GraphQL cnInvCmm).
 */
export interface CanonCommentStub {
  id: string;
  cmmKey?: number;
  valueKey: number;
  cmmGrKey?: number;
  groupKind: CanonCommentGroupKind;
  typeKind: CanonCommentTypeKind;
  text: string;
}

export interface CanonTreeNode {
  id: string;
  kind: CanonTreeKind;
  title: string;
  leaf?: boolean;
  children?: CanonTreeNode[];
  slotKey?: number;
  valueKey?: number;
  slot?: SudzDbtCanonSlot;
  value?: SudzDbtCanonValue;
  comment?: CanonCommentStub;
}

/**
 * Строит корни дерева: слоты канона → var → Value (upl в заголовке).
 *
 * @param slots слоты карточки
 */
export function buildCanonTreeNodes(slots: SudzDbtCanonSlot[]): CanonTreeNode[] {
  return slots.map((slot) => {
    const varChild: CanonTreeNode = {
      id: `var:${slot.slotKey}`,
      kind: 'var',
      title:
        slot.varKey != null
          ? `var ${slot.varKey} · ${slot.invNum ?? '—'} / ${slot.cnNum ?? '—'} · БУиРГ ${slot.orgBuirg ?? '—'}`
          : 'var — нет',
      leaf: true,
      slotKey: slot.slotKey,
      slot
    };
    const valueChildren: CanonTreeNode[] = slot.values.map((value) => {
      const date = value.uplStatusOnDate ?? value.uplDate ?? '—';
      const name = value.uplName ? ` ${value.uplName}` : '';
      return {
        id: `val:${value.valueKey}`,
        kind: 'value',
        title: `upl ${value.uplKey}${name} · ${date} · ttl ${formatMoney(value.ttl)} / проср. ${formatMoney(value.overd)}`,
        leaf: true,
        slotKey: slot.slotKey,
        valueKey: value.valueKey,
        slot,
        value
      };
    });
    const valuesFolder: CanonTreeNode = {
      id: `vals:${slot.slotKey}`,
      kind: 'value',
      title: `DbtValue (${slot.values.length})`,
      leaf: false,
      children: valueChildren,
      slotKey: slot.slotKey,
      slot
    };
    return {
      id: `slot:${slot.slotKey}`,
      kind: 'slot',
      title: `slot ${slot.slotKey} · idNum ${slot.idNum} · iKey ${slot.iKey}`,
      leaf: false,
      children: [varChild, valuesFolder],
      slotKey: slot.slotKey,
      slot
    };
  });
}

/**
 * Ключи слотов для авто-раскрытия.
 *
 * @param nodes корни
 */
export function defaultExpandedKeys(nodes: CanonTreeNode[]): string[] {
  const keys: string[] = [];
  for (const node of nodes) {
    keys.push(node.id);
    if (node.children) {
      for (const child of node.children) {
        if (child.id.startsWith('vals:')) {
          keys.push(child.id);
        }
      }
    }
  }
  return keys;
}

const COMMENT_TITLE_MAX = 80;

/**
 * Подпись листа комментария: группа · тип · обрезка текста.
 *
 * @param stub комментарий
 */
export function formatCanonCommentTitle(stub: CanonCommentStub): string {
  const group =
    stub.groupKind === 'official'
      ? 'yr_CmmGr'
      : stub.groupKind === 'new'
        ? 'yr_CmmGr_New'
        : stub.cmmGrKey != null
          ? `gr ${stub.cmmGrKey}`
          : 'группа';
  const type = stub.typeKind === 'mery' ? 'мероприятия' : 'куратор';
  const body = stub.text.trim().replace(/\s+/g, ' ');
  const clipped =
    body.length <= COMMENT_TITLE_MAX ? body : `${body.slice(0, COMMENT_TITLE_MAX - 1)}…`;
  return clipped ? `${group} · ${type} · ${clipped}` : `${group} · ${type}`;
}

/**
 * Вешает листья комментариев на узлы DbtValue (якорь dvKey, не группа года).
 *
 * @param nodes дерево слотов вкладки «Долг»
 * @param comments комментарии по valueKey
 */
function attachCommentsToValues(
  nodes: CanonTreeNode[],
  comments: CanonCommentStub[]
): CanonTreeNode[] {
  return nodes.map((node) => {
    if (node.kind === 'value' && node.valueKey != null) {
      const kids = comments
        .filter((stub) => stub.valueKey === node.valueKey)
        .map((stub) => ({
          id: stub.id,
          kind: 'comment' as const,
          title: formatCanonCommentTitle(stub),
          leaf: true,
          slotKey: node.slotKey,
          valueKey: node.valueKey,
          slot: node.slot,
          value: node.value,
          comment: stub
        }));
      return {
        ...node,
        leaf: false,
        children: kids
      };
    }
    if (node.children?.length) {
      return { ...node, children: attachCommentsToValues(node.children, comments) };
    }
    return node;
  });
}

/**
 * Комментарии карточки → листья дерева.
 *
 * @param slots слоты канона
 */
export function commentsFromSlots(slots: SudzDbtCanonSlot[]): CanonCommentStub[] {
  const out: CanonCommentStub[] = [];
  for (const slot of slots) {
    for (const value of slot.values) {
      for (const comment of value.comments ?? []) {
        out.push(apiCommentToStub(comment));
      }
    }
  }
  return out;
}

/**
 * GraphQL-комментарий → узел дерева.
 *
 * @param comment ответ API
 */
export function apiCommentToStub(comment: SudzDbtCanonComment): CanonCommentStub {
  const groupKind: CanonCommentGroupKind =
    comment.groupKind === 'new' || comment.groupKind === 'other'
      ? comment.groupKind
      : 'official';
  return {
    id: `cmm:${comment.cmmKey}`,
    cmmKey: comment.cmmKey,
    valueKey: comment.valueKey,
    cmmGrKey: comment.cmmGrKey,
    groupKind,
    typeKind: comment.cnicType === 8 ? 'curator' : 'mery',
    text: comment.text ?? ''
  };
}

/**
 * Дерево вкладки «Комментарии»: Dbt → слот → var / DbtValue → cmm на Value.
 *
 * @param dbtKey канон
 * @param slots слоты карточки
 * @param comments комментарии (по умолчанию из slots.values.comments)
 */
export function buildCanonCommentTreeNodes(
  dbtKey: number,
  slots: SudzDbtCanonSlot[],
  comments: CanonCommentStub[] = commentsFromSlots(slots)
): CanonTreeNode[] {
  return [
    {
      id: `dbt:${dbtKey}`,
      kind: 'dbt',
      title: `Dbt ${dbtKey}`,
      leaf: false,
      children: attachCommentsToValues(buildCanonTreeNodes(slots), comments)
    }
  ];
}

/**
 * Раскрыть Dbt, слоты, папки Value и Value, у которых уже есть комментарии.
 *
 * @param nodes корни дерева комментариев
 */
export function commentTreeExpandedKeys(nodes: CanonTreeNode[]): string[] {
  const keys: string[] = [];
  const walk = (node: CanonTreeNode): void => {
    if (node.kind === 'dbt' || node.kind === 'slot' || node.id.startsWith('vals:')) {
      keys.push(node.id);
    }
    if (node.kind === 'value' && node.valueKey != null && (node.children?.length ?? 0) > 0) {
      keys.push(node.id);
    }
    node.children?.forEach(walk);
  };
  nodes.forEach(walk);
  return keys;
}
