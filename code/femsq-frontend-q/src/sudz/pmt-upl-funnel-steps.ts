/**
 * Реестр шагов загрузки платежей (0072 visual v1) — префикс цепочки cipu*, без пресетов.
 * Подписи — комментарий VBA «Процедура *…*», шаг 6 — текст §2.9 («агент более одного раза»).
 */

export interface SudzPmtUplFunnelStepDef {
  id: string;
  /** Подпись из комментария VBA (шаг 6 — формулировка владельца). */
  titleRu: string;
  enabled: boolean;
}

export const SUDZ_PMT_UPL_FUNNEL_STEPS: SudzPmtUplFunnelStepDef[] = [
  {
    id: 'cipuCtpt_All_OIdNot',
    titleRu: 'Отображаем отсутствующих контрагентов по выгрузке платежей',
    enabled: true
  },
  {
    id: 'cipuCacNot',
    titleRu: 'Отображаем отсутствующие стройки',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnNotLoad',
    titleRu: 'Отображаем отсутствующие договоры (по выгрузке платежей) либо добавляем их',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnTwo',
    titleRu: 'Отображаем пары договор+исполнитель более одного раза',
    enabled: true
  },
  {
    id: 'cipuCn_AgNotLoad',
    titleRu: 'Отображаем договора, не имеющие агента в БД, либо добавляем их',
    enabled: true
  },
  {
    id: 'cipuCn_AgTwo',
    titleRu: 'Отображаем агента более одного раза',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnOneInvNotLoad',
    titleRu: 'Отображаем новые счета-фактуры для существующих договоров либо добавляем их',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnOneInvTwoLoad',
    titleRu: 'Отображаем счета-фактуры, уже более чем однократно в БД (только показ; apply закрыт S69)',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnOneInvOneAcNotLoad',
    titleRu: 'Отображаем СФ без пары СФ+счёт ГК либо добавляем их',
    enabled: true
  },
  {
    id: 'cipuDocNotLoad',
    titleRu: 'Отображаем отсутствующие платёжные документы либо добавляем их',
    enabled: true
  },
  {
    id: 'cipuCn_CtptCnOneInvOneAcDcNot',
    titleRu: 'Отображаем СФ без платёжного документа',
    enabled: true
  },
  {
    id: 'cipuInsPmNotLoad',
    titleRu: 'Отображаем платежи, готовые к внесению в БД, либо вносим их',
    enabled: true
  },
  {
    id: 'cipuInsPmExt',
    titleRu: 'Отображаем платежи, уже в БД (построчный diff)',
    enabled: true
  }
];

/** Enabled step ids in pipeline order. */
export const SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS: string[] = SUDZ_PMT_UPL_FUNNEL_STEPS.filter(
  (s) => s.enabled
).map((s) => s.id);

/**
 * Префикс цепочки длины n среди enabled-шагов.
 */
export function pmtFunnelPrefixIds(count: number): string[] {
  const n = Math.max(0, Math.min(count, SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS.length));
  return SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS.slice(0, n);
}
