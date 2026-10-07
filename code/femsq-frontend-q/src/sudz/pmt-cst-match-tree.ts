/**
 * Хост вкладки «стройки новые»: хвост очереди и отметка «тот же хвост».
 * Обход — FemsqWalkTree (лес по sudz.pmtUpl.cstMatch).
 */

import type { FemsqWalkFetchRow } from 'fequlib';

import type { SudzPmtUplCstMatch } from '@/types/sudz';

/** Идентификатор корней леса в JSON. */
export const PMT_CST_MATCH_ROOT_QUERY = 'sudz.pmtUpl.cstMatch';

/** Агенты выбранной стройки. */
export const PMT_CST_AGENTS_QUERY = 'sudz.pmtUpl.cstAgents';

/** Коды выбранного агента. */
export const PMT_CST_POINTS_QUERY = 'sudz.pmtUpl.cstAgPoints';

/**
 * Токен пересборки леса: хвост очереди и состав каталога после match.
 *
 * @param codeSuffix хвост sh выбранной строки
 * @param sites ответ sudzPmtUplCstMatch
 * @return непрозрачная строка для FemsqWalkTree
 */
export function pmtCstMatchRootsToken(
  codeSuffix: string | null | undefined,
  sites: SudzPmtUplCstMatch[]
): string {
  const suffix = (codeSuffix ?? '').trim();
  if (!suffix) {
    return '';
  }
  const body = sites
    .map((site) => {
      const agents = site.agents
        .map((agent) => {
          const points = agent.points.map((point) => point.cstapKey).join('+');
          return `${agent.cstaKey}:${points}`;
        })
        .join(',');
      return `${site.cstKey}[${agents}]`;
    })
    .join(';');
  return `${suffix}|${body}`;
}

/**
 * Корни леса: стройки из ответа match.
 *
 * @param sites ответ sudzPmtUplCstMatch
 * @return строки fetchRoots
 */
export function pmtCstMatchRootRows(sites: SudzPmtUplCstMatch[]): FemsqWalkFetchRow[] {
  return sites.map((site) => ({
    key: site.cstKey,
    fields: [
      { name: 'label', value: site.cstName },
      { name: 'keyText', value: String(site.cstKey) },
      { name: 'extra', value: '' }
    ]
  }));
}

/**
 * Дети папки: агенты стройки или коды агента.
 * «Тот же хвост» кладёт хост в extra.
 *
 * @param queryId sudz.pmtUpl.cstAgents | sudz.pmtUpl.cstAgPoints
 * @param fromId cstKey или cstaKey
 * @param sites кэш match
 * @return строки fetchQuery
 */
export function pmtCstMatchQueryRows(
  queryId: string,
  fromId: number,
  sites: SudzPmtUplCstMatch[]
): FemsqWalkFetchRow[] {
  if (queryId === PMT_CST_AGENTS_QUERY) {
    const site = sites.find((item) => item.cstKey === fromId);
    return (site?.agents ?? []).map((agent) => ({
      key: agent.cstaKey,
      fields: [
        { name: 'label', value: agent.agentLabel ?? '' },
        { name: 'keyText', value: String(agent.cstaKey) },
        { name: 'extra', value: agent.ogaCode ?? '' }
      ]
    }));
  }
  if (queryId === PMT_CST_POINTS_QUERY) {
    for (const site of sites) {
      const agent = site.agents.find((item) => item.cstaKey === fromId);
      if (!agent) {
        continue;
      }
      return agent.points.map((point) => ({
        key: point.cstapKey,
        fields: [
          { name: 'label', value: point.cstapIpgPnN },
          { name: 'keyText', value: String(point.cstapKey) },
          { name: 'extra', value: point.sameSuffix ? 'тот же хвост' : '' }
        ]
      }));
    }
    return [];
  }
  return [];
}

/**
 * Первые три символа кода очереди — подсказка агента (`051-2006707` → `051`).
 *
 * @param cacOrNull код строки очереди
 * @return префикс или пустая строка
 */
export function queueAgentCode(cacOrNull: string): string {
  return cacOrNull.trim().slice(0, 3);
}

/**
 * Агенты каталога, чья подпись начинается с кода (`051 Газпром…`).
 * Нового агента отсюда не создают: пустой список значит «такого кода нет».
 *
 * @param lookups справочник ogAgCs
 * @param code три символа
 * @return подходящие агенты
 */
export function lookupsForAgentCode<T extends { ogaNm: string }>(lookups: T[], code: string): T[] {
  const prefix = code.trim();
  if (prefix.length !== 3) {
    return [];
  }
  return lookups.filter((item) => {
    const name = item.ogaNm.trim();
    return name === prefix || name.startsWith(`${prefix} `);
  });
}
