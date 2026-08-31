/**
 * Реестр шагов воронки загрузки свода (S61f / S66e) — зеркало backend SudzDbtUplFunnelSteps.
 * titleRu — из комментариев VBA / S66e; Access-хвост после AccSmpl — disabled.
 */

export interface SudzDbtUplFunnelStepDef {
  id: string;
  /** Подпись из комментария VBA / S66e (не имя процедуры). */
  titleRu: string;
  /** false — отключён (Access-хвост / CnCtptInvAccExistDbl) */
  enabled: boolean;
}

export const SUDZ_DBT_UPL_FUNNEL_STEPS: SudzDbtUplFunnelStepDef[] = [
  {
    id: 'orgNotInBuirg',
    titleRu: 'Отображаем отсутствующих контрагентов',
    enabled: true
  },
  {
    id: 'CnNotLoad',
    titleRu: 'Отображаем отсутствующие в БД договоры с исполнителями либо добавляем их',
    enabled: true
  },
  {
    id: 'CnExistCtptNotLoad',
    titleRu:
      'Отображаем договора, имеющиеся в БД, в которых отсутствует обнаруженный в БД исполнитель',
    enabled: true
  },
  {
    id: 'CnCtptExistInvNotLoad',
    titleRu: 'Отображаем новые счета-фактуры для существующих договоров',
    enabled: true
  },
  {
    id: 'CnCtptInvExistAccSmplNotLoad',
    titleRu: 'Отображаем счета-фактуры не имеющие Задолженностей простых в БД либо добавляем их',
    enabled: true
  },
  {
    id: 'invDbtVarEnsure',
    titleRu: 'Актуализируем варианты контекста задолженности (invDbtVar)',
    enabled: true
  },
  {
    id: 'invDbtLoad',
    titleRu: 'Загружаем слоты задолженностей СФ (invDbt) либо ставим в очередь разбора',
    enabled: true
  },
  {
    id: 'invDbtDbtEnsure',
    titleRu: 'Привязываем слоты к канону Dbt (invDbtDbt)',
    enabled: true
  },
  {
    id: 'dbtValueLoad',
    titleRu: 'Загружаем Value, diff base→curr и очередь P1 (multi-Dbt)',
    enabled: true
  },
  {
    id: 'invDbtDouble',
    titleRu: 'Проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры',
    enabled: false
  },
  {
    id: 'CnCtptInvExistAccNotLoad',
    titleRu: 'Отображаем счета-фактуры не имеющие Задолженностей в БД либо добавляем их',
    enabled: false
  },
  {
    id: 'ciduTblCnCtptInvAccNameCountOneNot',
    titleRu: 'Отображаем повторяющиеся Задолженности (с именами) имеющиеся в источнике',
    enabled: false
  },
  {
    id: 'CnCtptInvAccExistDbl',
    titleRu: 'Отображаем Задолженности имеющие более одной задолженности в выгрузке (отключён)',
    enabled: false
  },
  {
    id: 'CnCtptInvAccExistDbtNotLoad',
    titleRu: 'Отображаем Задолженности не имеющие задолженности в БД либо добавляем их туда',
    enabled: false
  },
  {
    id: 'CnCtptInvAccDbtExist',
    titleRu: 'Отображаем пары СФ+СГК имеющие задолженности в БД',
    enabled: false
  }
];

/** Enabled step ids in pipeline order. */
export const SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS: string[] = SUDZ_DBT_UPL_FUNNEL_STEPS.filter(
  (s) => s.enabled
).map((s) => s.id);

/**
 * Префикс цепочки длины n среди enabled-шагов.
 */
export function funnelPrefixIds(count: number): string[] {
  const n = Math.max(0, Math.min(count, SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS.length));
  return SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS.slice(0, n);
}

export type FunnelPresetId = 'org' | 'cnDry' | 'fullDry' | 'fullApply';

/**
 * Пресет → длина префикса (число enabled-шагов).
 * org: orgNotInBuirg
 * cnDry: до CnExistCtptNotLoad включительно (3)
 * full*: вся enabled-цепочка
 * Excel→Tbl не в префиксе — переключатель «обнов. по исх?»
 */
export function funnelPresetPrefixCount(preset: FunnelPresetId): number {
  switch (preset) {
    case 'org':
      return 1;
    case 'cnDry':
      return 3;
    case 'fullDry':
    case 'fullApply':
      return SUDZ_DBT_UPL_FUNNEL_ENABLED_IDS.length;
    default:
      return 1;
  }
}
