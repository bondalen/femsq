/**
 * Хост decision-TreeList кандидата СФ: профиль GraphQL → строки FemsqWalkTree.
 */

import type { FemsqWalkFetchRow } from 'fequlib';

import type {
  SudzSfDecisionCias,
  SudzSfDecisionCnInv,
  SudzSfDecisionDocSum,
  SudzSfDecisionInvNum,
  SudzSfDecisionParty,
  SudzSfDecisionPayment,
  SudzSfDecisionProfile,
  SudzSfDecisionVerdict
} from '@/types/sudz';

/** Корень / номера / договоры / стороны / платежи / сводки — queryId из JSON. */
export const DECISION_ROOT = 'sudz.ksdsf.decision.root';
export const DECISION_INV_NUMS = 'sudz.ksdsf.decision.invNums';
export const DECISION_CN_INVS = 'sudz.ksdsf.decision.cnInvs';
export const DECISION_EXECUTORS = 'sudz.ksdsf.decision.executors';
export const DECISION_AGENTS = 'sudz.ksdsf.decision.agents';
export const DECISION_PAYMENTS = 'sudz.ksdsf.decision.payments';
export const DECISION_DOC_SUMS = 'sudz.ksdsf.decision.docSums';
export const DECISION_CIAS = 'sudz.ksdsf.decision.cias';
export const DECISION_DEBTS = 'sudz.ksdsf.decision.debts';

/** База синтетических ключей сводки документов (строковые docKod). */
const DOC_KEY_BASE = -2_000_000;

/**
 * Токен пересборки дерева по профилю.
 *
 * @param profile ответ API
 */
export function decisionRootsToken(profile: SudzSfDecisionProfile | null): string {
  if (!profile) {
    return '';
  }
  const pm = profile.payments
    .map(
      (p) =>
        `${p.pmKey}:${p.uplKey}:${p.blns ?? ''}:${p.hlCurrentUpl ? 1 : 0}:${p.cstCode ?? ''}:${p.hlCstDiff ? 1 : 0}:${p.hlCstSuffix ? 1 : 0}`
    )
    .join(';');
  const cn = (profile.cnInvs ?? [])
    .map(
      (row) =>
        `${row.ciKey}:${row.executors.length}/${row.agents.length}:${row.executors
          .map((p) => p.csosKey)
          .join('+')}`
    )
    .join(';');
  const aliases = (profile.invNums ?? [])
    .map((a) => `${a.inKey}:${a.inNum ?? ''}:${a.hitExcel ? 1 : 0}`)
    .join(';');
  const docs = (profile.docSums ?? [])
    .map((d) => `${d.docKod}:${d.otherInvCount}:${d.otherCnCount}:${d.hlDocTransfer ? 1 : 0}`)
    .join(';');
  return `${profile.invKey}|${profile.pmCount}|${pm}|${cn}|${aliases}|${docs}|${profile.compare.docTransferVerdict}`;
}

/**
 * Подпись исхода сверки.
 *
 * @param verdict yes|no|suspicious|na
 */
export function decisionVerdictLabel(verdict: SudzSfDecisionVerdict): string {
  switch (verdict) {
    case 'yes':
      return 'да';
    case 'no':
      return 'нет';
    case 'suspicious':
      return 'подозр.';
    case 'suffix':
      return 'хвост';
    case 'transfer':
      return 'переезд';
    case 'na':
      return 'н/д';
    default:
      return String(verdict);
  }
}

/**
 * Цвет чипа сверки.
 *
 * @param verdict исход
 */
export function decisionVerdictColor(verdict: SudzSfDecisionVerdict): string {
  switch (verdict) {
    case 'yes':
      return 'positive';
    case 'no':
      return 'negative';
    case 'suspicious':
    case 'suffix':
    case 'transfer':
      return 'warning';
    default:
      return 'grey-6';
  }
}

/**
 * Строка корня inv.
 *
 * @param profile профиль
 */
export function decisionRootRow(profile: SudzSfDecisionProfile): FemsqWalkFetchRow {
  const party =
    profile.cntrPrtNum != null || profile.cntrPrtName
      ? `${profile.cntrPrtNum ?? '—'} · ${profile.cntrPrtName ?? '—'}`
      : null;
  const aliases = (profile.invNums ?? [])
    .map((a) => a.inNum?.trim())
    .filter((n): n is string => !!n)
    .filter((n, i, arr) => arr.indexOf(n) === i);
  const aliasesText =
    aliases.length > 1 ? aliases.join(' · ') : aliases.length === 1 ? null : null;
  return {
    key: profile.invKey,
    fields: [
      { name: 'title', value: `inv ${profile.invKey}` },
      { name: 'invNum', value: profile.invNum },
      { name: 'invEntered', value: profile.invEntered },
      { name: 'contract', value: profile.contract },
      { name: 'party', value: party },
      { name: 'aliases', value: aliases.length > 1 ? aliasesText : null },
      { name: 'pmCount', value: String(profile.pmCount) },
      { name: 'blnsSum', value: numberField(profile.blnsSum) },
      { name: 'note', value: profile.note }
    ]
  };
}

/**
 * Дети папок по queryId.
 *
 * @param queryId id JSON
 * @param fromId invKey или ciKey
 * @param profile кэш
 */
export function decisionQueryRows(
  queryId: string,
  fromId: number,
  profile: SudzSfDecisionProfile
): FemsqWalkFetchRow[] {
  if (queryId === DECISION_INV_NUMS) {
    if (fromId !== profile.invKey) {
      return [];
    }
    return (profile.invNums ?? []).map(invNumRow);
  }
  if (queryId === DECISION_CN_INVS) {
    if (fromId !== profile.invKey) {
      return [];
    }
    return (profile.cnInvs ?? []).map(cnInvRow);
  }
  if (queryId === DECISION_EXECUTORS) {
    const cnInv = (profile.cnInvs ?? []).find((row) => row.ciKey === fromId);
    return cnInv ? cnInv.executors.map(partyRow) : [];
  }
  if (queryId === DECISION_AGENTS) {
    const cnInv = (profile.cnInvs ?? []).find((row) => row.ciKey === fromId);
    return cnInv ? cnInv.agents.map(partyRow) : [];
  }
  if (fromId !== profile.invKey) {
    return [];
  }
  if (queryId === DECISION_PAYMENTS) {
    return profile.payments.map(paymentRow);
  }
  if (queryId === DECISION_DOC_SUMS) {
    return profile.docSums.map((row, index) => docSumRow(row, index));
  }
  if (queryId === DECISION_CIAS) {
    return profile.cias.map(ciasRow);
  }
  if (queryId === DECISION_DEBTS) {
    return profile.debts.map((debt, index) => ({
      key: -(index + 1),
      fields: [{ name: 'title', value: debt.title }]
    }));
  }
  return [];
}

function invNumRow(row: SudzSfDecisionInvNum): FemsqWalkFetchRow {
  const mark = row.hitExcel ? ' · Excel' : '';
  const primary = row.primary ? ' · primary' : '';
  const num = row.inNum?.trim() ? row.inNum : '—';
  return {
    key: row.inKey,
    fields: [
      { name: 'title', value: `${num}${primary}${mark}` },
      { name: 'inKey', value: String(row.inKey) },
      { name: 'primary', value: row.primary ? 'да' : '' },
      { name: 'hitExcel', value: row.hitExcel ? 'да' : '' }
    ]
  };
}

function cnInvRow(row: SudzSfDecisionCnInv): FemsqWalkFetchRow {
  const cnLabel = row.contract?.trim()
    ? row.contract
    : row.cnKey != null
      ? `cn ${row.cnKey}`
      : '—';
  return {
    key: row.ciKey,
    fields: [
      { name: 'title', value: cnLabel },
      { name: 'cnKey', value: row.cnKey != null ? String(row.cnKey) : null },
      { name: 'ciKey', value: String(row.ciKey) },
      { name: 'executorCount', value: String(row.executors.length) },
      { name: 'agentCount', value: String(row.agents.length) },
      { name: 'note', value: row.note }
    ]
  };
}

function partyRow(party: SudzSfDecisionParty): FemsqWalkFetchRow {
  const mark = party.hitExcel ? ' · Excel' : '';
  const title = `${party.buirg ?? '—'} · ${party.name?.trim() ? party.name : '—'}${mark}`;
  return {
    key: party.csosKey,
    fields: [
      { name: 'title', value: title },
      { name: 'buirg', value: party.buirg != null ? String(party.buirg) : null },
      { name: 'name', value: party.name },
      { name: 'hitExcel', value: party.hitExcel ? 'да' : '' }
    ]
  };
}

function paymentRow(pm: SudzSfDecisionPayment): FemsqWalkFetchRow {
  const marks: string[] = [];
  if (pm.hlCurrentUpl) {
    marks.push('этот пакет');
  }
  if (pm.hlOrphanLink) {
    marks.push('cias');
  }
  if (pm.hlContractDiff) {
    marks.push('≠договор');
  }
  if (pm.hlCstDiff) {
    marks.push('≠стройка');
  } else if (pm.hlCstSuffix) {
    marks.push('хвост');
  }
  const mark = marks.length ? ` · ${marks.join(' · ')}` : '';
  const cstLabel = pm.cstCode
    ? `${pm.cstCode}${pm.cstName?.trim() ? ` · ${pm.cstName}` : ''}`
    : null;
  return {
    key: pm.pmKey,
    fields: [
      { name: 'title', value: `pm ${pm.pmKey}${mark}` },
      { name: 'uplName', value: pm.uplName ?? String(pm.uplKey) },
      { name: 'uplDate', value: pm.uplDate },
      { name: 'docKod', value: pm.docKod },
      { name: 'docDate', value: pm.docDate },
      { name: 'dbt', value: numberField(pm.dbt) },
      { name: 'cdt', value: numberField(pm.cdt) },
      { name: 'blns', value: numberField(pm.blns) },
      { name: 'accountNum', value: pm.accountNum },
      { name: 'cstCode', value: cstLabel },
      { name: 'ciKey', value: String(pm.ciKey) },
      { name: 'contract', value: pm.contract }
    ]
  };
}

function docSumRow(row: SudzSfDecisionDocSum, index: number): FemsqWalkFetchRow {
  const kod = row.docKod?.trim() ? row.docKod : '—';
  const mark = row.hlDocTransfer ? ' · переезд' : '';
  return {
    key: DOC_KEY_BASE - index,
    fields: [
      { name: 'title', value: `${kod}${mark}` },
      { name: 'docKod', value: kod },
      { name: 'pmCount', value: String(row.pmCount) },
      { name: 'blnsSum', value: numberField(row.blnsSum) },
      { name: 'uplNames', value: row.uplNames },
      { name: 'otherInvCount', value: String(row.otherInvCount ?? 0) },
      { name: 'otherCnCount', value: String(row.otherCnCount ?? 0) },
      { name: 'transferHint', value: row.transferHint },
      { name: 'hlDocTransfer', value: row.hlDocTransfer ? 'да' : '' }
    ]
  };
}

function ciasRow(row: SudzSfDecisionCias): FemsqWalkFetchRow {
  const acc = row.accountNum?.trim() ? row.accountNum : `cias ${row.ciasKey}`;
  return {
    key: row.ciasKey,
    fields: [
      { name: 'title', value: acc },
      { name: 'ciasKey', value: String(row.ciasKey) },
      { name: 'ciKey', value: String(row.ciKey) },
      { name: 'accountNum', value: row.accountNum },
      { name: 'pmCount', value: String(row.pmCount) },
      { name: 'blnsSum', value: numberField(row.blnsSum) }
    ]
  };
}

function numberField(value: number | null | undefined): string | null {
  if (value == null || Number.isNaN(value)) {
    return null;
  }
  return String(value);
}
