/**
 * Хост канона долга: лес слотов для FemsqWalkTree (view list).
 * Данные из карточки sudzDbtCanon; GraphQL expand не нужен.
 */

import type { FemsqWalkFetchRow } from 'fequlib';
import { formatMoney } from 'fequlib';

import type { SudzDbtCanonSlot, SudzDbtCanonValue } from '@/types/sudz';
import {
  apiCommentToStub,
  commentsFromSlots,
  type CanonCommentStub
} from '@/utils/sudz-canon-tree';

/** Корни леса — слоты канона. */
export const DBT_CANON_SLOTS_QUERY = 'sudz.dbtCanon.slots';

/** Контекст (var) слота. */
export const DBT_CANON_VAR_QUERY = 'sudz.dbtCanon.var';

/** DbtValue слота. */
export const DBT_CANON_VALUES_QUERY = 'sudz.dbtCanon.values';

/** Комментарии Value. */
export const DBT_CANON_COMMENTS_QUERY = 'sudz.dbtCanon.comments';

/**
 * Токен пересборки леса по составу карточки.
 *
 * @param dbtKey канон
 * @param slots слоты деталки
 */
export function dbtCanonRootsToken(
  dbtKey: number | null | undefined,
  slots: SudzDbtCanonSlot[] | null | undefined
): string {
  if (dbtKey == null || !slots) {
    return '';
  }
  const body = slots
    .map((slot) => {
      const values = slot.values
        .map((value) => {
          const comments = (value.comments ?? []).map((c) => c.cmmKey).join('+');
          return `${value.valueKey}:${value.ttl ?? ''}:${value.overd ?? ''}:${comments}`;
        })
        .join(',');
      return `${slot.slotKey}:${slot.varKey ?? ''}:${slot.idNum}[${values}]`;
    })
    .join(';');
  return `${dbtKey}|${body}`;
}

/**
 * Корни: слоты.
 *
 * @param slots слоты карточки
 */
export function dbtCanonRootRows(slots: SudzDbtCanonSlot[]): FemsqWalkFetchRow[] {
  return slots.map((slot) => ({
    key: slot.slotKey,
    fields: [
      { name: 'title', value: `slot ${slot.slotKey}` },
      { name: 'idNum', value: String(slot.idNum) },
      { name: 'iKey', value: String(slot.iKey) }
    ]
  }));
}

/**
 * Строка var / values / comments по queryId.
 *
 * @param queryId идентификатор из JSON
 * @param fromId slotKey или valueKey
 * @param slots кэш карточки
 */
export function dbtCanonQueryRows(
  queryId: string,
  fromId: number,
  slots: SudzDbtCanonSlot[]
): FemsqWalkFetchRow[] {
  if (queryId === DBT_CANON_VAR_QUERY) {
    const slot = slots.find((item) => item.slotKey === fromId);
    if (!slot) {
      return [];
    }
    const key = slot.varKey ?? slot.slotKey;
    const context =
      slot.varKey != null
        ? `${slot.invNum ?? '—'} / ${slot.cnNum ?? '—'} · БУиРГ ${slot.orgBuirg ?? '—'}`
        : 'нет';
    return [
      {
        key,
        fields: [
          {
            name: 'title',
            value: slot.varKey != null ? `var ${slot.varKey}` : 'var — нет'
          },
          { name: 'varKey', value: slot.varKey != null ? String(slot.varKey) : '' },
          { name: 'context', value: context }
        ]
      }
    ];
  }
  if (queryId === DBT_CANON_VALUES_QUERY) {
    const slot = slots.find((item) => item.slotKey === fromId);
    return (slot?.values ?? []).map((value) => valueToRow(value));
  }
  if (queryId === DBT_CANON_COMMENTS_QUERY) {
    for (const slot of slots) {
      const value = slot.values.find((item) => item.valueKey === fromId);
      if (!value) {
        continue;
      }
      return (value.comments ?? []).map((comment) => commentToRow(apiCommentToStub(comment)));
    }
    return [];
  }
  return [];
}

/**
 * @param value DbtValue
 */
function valueToRow(value: SudzDbtCanonValue): FemsqWalkFetchRow {
  const date = value.uplStatusOnDate ?? value.uplDate ?? '—';
  const name = value.uplName ? ` ${value.uplName}` : '';
  const portfolios =
    value.portfolioLabels && value.portfolioLabels.length > 0
      ? value.portfolioLabels.join('; ')
      : 'вне портфелей года';
  return {
    key: value.valueKey,
    fields: [
      { name: 'title', value: `upl ${value.uplKey}${name}` },
      { name: 'valueKey', value: String(value.valueKey) },
      { name: 'ttl', value: value.ttl != null ? String(value.ttl) : null },
      { name: 'overd', value: value.overd != null ? String(value.overd) : null },
      { name: 'uplName', value: value.uplName },
      { name: 'uplDate', value: date },
      { name: 'portfolios', value: portfolios }
    ]
  };
}

/**
 * @param stub комментарий
 */
function commentToRow(stub: CanonCommentStub): FemsqWalkFetchRow {
  const groupLabel =
    stub.groupKind === 'official'
      ? 'yr_CmmGr'
      : stub.groupKind === 'new'
        ? 'yr_CmmGr_New'
        : stub.cmmGrKey != null
          ? `gr ${stub.cmmGrKey}`
          : 'группа';
  const typeLabel = stub.typeKind === 'mery' ? 'мероприятия' : 'куратор';
  const key = stub.cmmKey ?? hashCommentId(stub.id);
  return {
    key,
    fields: [
      { name: 'title', value: stub.text.trim().slice(0, 40) || typeLabel },
      { name: 'groupLabel', value: groupLabel },
      { name: 'typeLabel', value: typeLabel },
      { name: 'text', value: stub.text }
    ]
  };
}

/**
 * Стабильный числовой ключ, если у черновика нет cmmKey.
 *
 * @param id строковый id stub
 */
function hashCommentId(id: string): number {
  let hash = 0;
  for (let i = 0; i < id.length; i += 1) {
    hash = (hash * 31 + id.charCodeAt(i)) | 0;
  }
  return Math.abs(hash) || 1;
}

/**
 * slotKey из id узла WalkTree.
 *
 * @param nodeKey id узла
 * @param slots слоты
 */
export function slotKeyFromWalkNodeId(
  nodeKey: string | number | null | undefined,
  slots: SudzDbtCanonSlot[]
): number | null {
  if (nodeKey == null) {
    return null;
  }
  const text = String(nodeKey);
  const slotMatch = /^invDbt:(\d+)$/.exec(text);
  if (slotMatch) {
    return Number(slotMatch[1]);
  }
  const parent = /^invDbt:(\d+)\//.exec(text);
  if (parent) {
    return Number(parent[1]);
  }
  const valueMatch = /^DbtValue:(\d+)/.exec(text);
  if (valueMatch) {
    const vk = Number(valueMatch[1]);
    const slot = slots.find((item) => item.values.some((value) => value.valueKey === vk));
    return slot?.slotKey ?? null;
  }
  const commentMatch = /^cnInvCmm:(\d+)$/.exec(text);
  if (commentMatch) {
    const ck = Number(commentMatch[1]);
    for (const slot of slots) {
      for (const value of slot.values) {
        if ((value.comments ?? []).some((c) => c.cmmKey === ck)) {
          return slot.slotKey;
        }
      }
    }
  }
  return null;
}

/**
 * valueKey из id узла `DbtValue:N` или папки комментариев под ним.
 *
 * @param nodeKey id
 */
export function valueKeyFromWalkNodeId(nodeKey: string | number | null | undefined): number | null {
  if (nodeKey == null) {
    return null;
  }
  const text = String(nodeKey);
  const valueMatch = /^DbtValue:(\d+)/.exec(text);
  return valueMatch ? Number(valueMatch[1]) : null;
}

/**
 * Stub комментария по id узла WalkTree.
 *
 * @param nodeKey id
 * @param slots слоты
 */
export function commentStubFromWalkNodeId(
  nodeKey: string | number | null | undefined,
  slots: SudzDbtCanonSlot[]
): CanonCommentStub | null {
  if (nodeKey == null) {
    return null;
  }
  const text = String(nodeKey);
  const match = /^cnInvCmm:(\d+)$/.exec(text);
  if (!match) {
    return null;
  }
  const key = Number(match[1]);
  return (
    commentsFromSlots(slots).find((stub) => stub.cmmKey === key || hashCommentId(stub.id) === key) ??
    null
  );
}
