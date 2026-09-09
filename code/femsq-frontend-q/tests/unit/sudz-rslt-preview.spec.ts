import { describe, expect, it } from 'vitest';

import type { SudzRsltDebt } from '@/types/sudz';
import { buildSudzRsltPreview, pogashenoAccess } from '@/utils/sudz-rslt-preview';

describe('sudz-rslt-preview S77.5', () => {
  it('pogashenoAccess не изобретает долю', () => {
    expect(pogashenoAccess(36000, 36000)).toBeNull();
    expect(pogashenoAccess(36000, 30000)).toBe(6000);
  });

  it('полоса A: две строки факта QI, QIV Ttl только на первой, погашено null', () => {
    const debt: SudzRsltDebt = {
      dbtKey: 11897,
      accountNum: '76.10',
      curator: 'куратор',
      mery: 'мероприятие',
      cstCode: null,
      cstName: null,
      periods: [
        period(910, '2025-12-31', 'А45-19974/2024', 0, 36000),
        period(901, '2026-03-31', 'А45-19974/2024', 1, 18000),
        period(901, '2026-03-31', 'А45-19974/2024', 2, 18000)
      ]
    };
    const preview = buildSudzRsltPreview([debt], false);
    expect(preview.rows).toHaveLength(2);
    expect(preview.rows[0].rowKey).toBe('11897:0');
    expect(preview.rows[1].rowKey).toBe('11897:1');
    expect(preview.rows[0]['2025-12-31_Ttl']).toBe(36000);
    expect(preview.rows[1]['2025-12-31_Ttl']).toBeNull();
    expect(preview.rows[0]['2026-03-31_Ttl']).toBe(18000);
    expect(preview.rows[1]['2026-03-31_Ttl']).toBe(18000);
    expect(preview.rows[0]['2026-03-31_idNum']).toBe(1);
    expect(preview.rows[1]['2026-03-31_idNum']).toBe(2);
    expect(preview.rows[0]['2026-03-31_погашено']).toBeNull();
    expect(preview.rows[1]['2026-03-31_погашено']).toBeNull();
  });
});

function period(
  uplKey: number,
  uplDate: string,
  inv: string,
  idNum: number,
  ttl: number
) {
  return {
    uplKey,
    uplDate,
    asOf: uplDate,
    invNumEnum: inv,
    idNum,
    cnNumEnum: null,
    csoCnDate: null,
    orgIdValueL: null,
    itn: null,
    ctptOrg: 'контрагент',
    maturity: null,
    ttl,
    overd: ttl,
    cstAgPnCode: null,
    cstAgPnName: null,
    agOrg: null,
    pogasheno: null
  };
}
