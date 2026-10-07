/**
 * Хост леса платёжных документов: документ → платёж пакета → счёт-фактура.
 * Данные приходят одним ответом GraphQL, обход идёт из кэша.
 */

import type { FemsqWalkFetchRow } from 'fequlib';
import { formatMoneyOrDash } from 'fequlib';

import type { SudzPmDocForest, SudzPmDocLink } from '@/types/sudz';

/** Корни — документы. */
export const PM_DOC_ROOTS = 'sudz.pmDoc.roots';

/** Платежи документа. */
export const PM_DOC_PAYMENTS = 'sudz.pmDoc.payments';

/** Привязка платежа к счёту-фактуре. */
export const PM_DOC_LINK = 'sudz.pmDoc.link';

/**
 * Нормализация кода «№ докум.» для сравнения с {@code docKod} леса.
 *
 * @param code сырой код Excel / Tbl
 * @return trim или null, если пусто
 */
export function normalizePmDocCode(code: string | null | undefined): string | null {
  if (code == null) {
    return null;
  }
  const trimmed = String(code).trim();
  return trimmed === '' ? null : trimmed;
}

/**
 * Лес, суженный до одного кода «№ докум.» (выбор белой строки кейса).
 * Пустой код → пустой лес с {@code fileCodes=0}.
 *
 * @param forest полный ответ по cius
 * @param docCode код выбранной строки
 */
export function filterPmDocForestByDocCode(
  forest: SudzPmDocForest,
  docCode: string | null | undefined
): SudzPmDocForest {
  const code = normalizePmDocCode(docCode);
  if (!code) {
    return {
      fileCodes: 0,
      matchedDocs: 0,
      currentUplKey: forest.currentUplKey,
      links: []
    };
  }
  const links = forest.links.filter(
    (link) => normalizePmDocCode(link.docKod) === code
  );
  const docKeys = new Set(links.map((link) => link.docKey));
  return {
    fileCodes: 1,
    matchedDocs: docKeys.size,
    currentUplKey: forest.currentUplKey,
    links
  };
}

/**
 * Токен пересборки леса.
 *
 * @param forest ответ GraphQL
 */
export function pmDocRootsToken(forest: SudzPmDocForest | null): string {
  if (!forest) {
    return '';
  }
  return forest.links
    .map((link) => `${link.docKey}:${link.pmKey}:${link.invKey ?? ''}:${link.uplKey}:${link.cstCode ?? ''}`)
    .join(';');
}

/**
 * Корни: по одному узлу на код документа.
 *
 * @param forest кэш
 */
export function pmDocRootRows(forest: SudzPmDocForest): FemsqWalkFetchRow[] {
  const seen = new Set<number>();
  const rows: FemsqWalkFetchRow[] = [];
  for (const link of forest.links) {
    if (seen.has(link.docKey)) {
      continue;
    }
    seen.add(link.docKey);
    rows.push({
      key: link.docKey,
      fields: [
        { name: 'title', value: link.docKod },
        { name: 'docKod', value: link.docKod },
        { name: 'docDate', value: link.docDate ?? '—' },
        { name: 'docSum', value: formatMoneyOrDash(link.docSum) }
      ]
    });
  }
  return rows;
}

/**
 * Дети документа или платежа.
 *
 * @param queryId уровень
 * @param fromId ключ родителя
 * @param forest кэш
 * @param currentUplKey пакет строки очереди, чтобы подписать «этот пакет»
 */
export function pmDocQueryRows(
  queryId: string,
  fromId: number,
  forest: SudzPmDocForest,
  currentUplKey: number | null
): FemsqWalkFetchRow[] {
  if (queryId === PM_DOC_PAYMENTS) {
    return forest.links
      .filter((link) => link.docKey === fromId)
      .map((link) => paymentRow(link, currentUplKey));
  }
  if (queryId === PM_DOC_LINK) {
    const link = forest.links.find((item) => item.pmKey === fromId);
    return link ? [linkRow(link)] : [];
  }
  return [];
}

/**
 * Ключ счёта-фактуры на узле привязки, если кнопка «Открыть дерево СФ» нажата на нём.
 *
 * @param nodeKey ключ узла (отрицательный pmKey)
 * @param forest кэш
 */
export function pmDocInvKeyFromNode(nodeKey: number, forest: SudzPmDocForest): number | null {
  const pmKey = nodeKey < 0 ? -nodeKey : nodeKey;
  return forest.links.find((link) => link.pmKey === pmKey)?.invKey ?? null;
}

function paymentRow(link: SudzPmDocLink, currentUplKey: number | null): FemsqWalkFetchRow {
  const here = currentUplKey != null && link.uplKey === currentUplKey ? ' · этот пакет' : '';
  const cstLabel = formatCstLabel(link);
  return {
    key: link.pmKey,
    fields: [
      { name: 'title', value: `pm ${link.pmKey}${here}` },
      { name: 'uplName', value: link.uplName ?? String(link.uplKey) },
      { name: 'uplDate', value: link.uplDate ?? '—' },
      { name: 'blns', value: formatMoneyOrDash(link.blns) },
      { name: 'dbt', value: formatMoneyOrDash(link.dbtBlns) },
      { name: 'cdt', value: formatMoneyOrDash(link.cdtBlns) },
      { name: 'cstCode', value: cstLabel }
    ]
  };
}

function linkRow(link: SudzPmDocLink): FemsqWalkFetchRow {
  const contract = [link.cnNumber, link.cnName].filter(Boolean).join(' · ')
    || (link.cnKey != null ? `cn ${link.cnKey}` : '—');
  return {
    key: -link.pmKey,
    fields: [
      { name: 'title', value: link.invNum ?? (link.invKey != null ? `inv ${link.invKey}` : '—') },
      { name: 'contract', value: contract },
      { name: 'counterparty', value: link.counterparty ?? '—' },
      { name: 'accountNum', value: link.accountNum ?? '—' },
      { name: 'cstCode', value: formatCstLabel(link) }
    ]
  };
}

/**
 * Подпись стройки: код · имя.
 *
 * @param link строка леса
 */
function formatCstLabel(link: SudzPmDocLink): string {
  if (!link.cstCode?.trim()) {
    return '—';
  }
  const name = link.cstName?.trim();
  return name ? `${link.cstCode} · ${name}` : link.cstCode;
}
