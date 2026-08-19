import { describe, expect, it } from 'vitest';

import {
  SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS,
  SUDZ_PMT_UPL_FUNNEL_STEPS,
  pmtFunnelPrefixIds
} from '@/sudz/pmt-upl-funnel-steps';

describe('pmt-upl-funnel-steps', () => {
  it('содержит 13 шагов cipu* без пресетов', () => {
    expect(SUDZ_PMT_UPL_FUNNEL_STEPS).toHaveLength(13);
    expect(SUDZ_PMT_UPL_FUNNEL_ENABLED_IDS).toHaveLength(13);
    expect(SUDZ_PMT_UPL_FUNNEL_STEPS.map((s) => s.id)).toEqual([
      'cipuCtpt_All_OIdNot',
      'cipuCacNot',
      'cipuCn_CtptCnNotLoad',
      'cipuCn_CtptCnTwo',
      'cipuCn_AgNotLoad',
      'cipuCn_AgTwo',
      'cipuCn_CtptCnOneInvNotLoad',
      'cipuCn_CtptCnOneInvTwoLoad',
      'cipuCn_CtptCnOneInvOneAcNotLoad',
      'cipuDocNotLoad',
      'cipuCn_CtptCnOneInvOneAcDcNot',
      'cipuInsPmNotLoad',
      'cipuInsPmExt'
    ]);
  });

  it('шаг 6 cipuCn_AgTwo — агент более одного раза', () => {
    const step = SUDZ_PMT_UPL_FUNNEL_STEPS[5];
    expect(step.id).toBe('cipuCn_AgTwo');
    expect(step.titleRu).toBe('Отображаем агента более одного раза');
  });

  it('префикс цепочки отсекает хвост', () => {
    expect(pmtFunnelPrefixIds(0)).toEqual([]);
    expect(pmtFunnelPrefixIds(2)).toEqual(['cipuCtpt_All_OIdNot', 'cipuCacNot']);
    expect(pmtFunnelPrefixIds(99)).toHaveLength(13);
  });
});
