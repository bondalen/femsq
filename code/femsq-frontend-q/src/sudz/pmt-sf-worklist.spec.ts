import { describe, expect, it } from 'vitest';

import { buildPmtSfWorklist } from '@/sudz/pmt-sf-worklist';
import type {
  SudzCnInvUplSfDouble,
  SudzPmtUplInvNot,
  SudzPmtUplTwoLoad
} from '@/types/sudz';

function sf(
  partial: Partial<SudzCnInvUplSfDouble> & Pick<SudzCnInvUplSfDouble, 'ciusKey'>
): SudzCnInvUplSfDouble {
  return {
    ciusCidut: null,
    ciusCiput: partial.ciusKey,
    ciusDbtFile: null,
    ciusPmtFile: 1,
    ciusUnloadKey: 59,
    ciusDbtTblCnInvRow: null,
    ciusPmtTblCnInvRow: null,
    ciusCnKey: null,
    ciusCnNum: null,
    ciusInvNum: null,
    ciusInvNumCount: null,
    ciusStatus: 'open',
    ciusStatusAt: null,
    ciusCreatedInvKey: null,
    ...partial
  };
}

describe('buildPmtSfWorklist', () => {
  it('ставит оба флага на пересечении и даёт число строк = SfDouble', () => {
    const doubles = [
      sf({ ciusKey: 1, ciusInvNum: '108', ciusCnKey: 308, ciusCnNum: 'КС-51' }),
      sf({ ciusKey: 2, ciusInvNum: 'б/н', ciusCnKey: null }),
      sf({ ciusKey: 3, ciusInvNum: 'only-inv', ciusCnKey: 1, ciusCnNum: 'A' })
    ];
    const invNot: SudzPmtUplInvNot[] = [
      {
        cntrPrtNum: 1,
        cntrPrtName: 'X',
        cnName: 'КС-51',
        cnKey: 308,
        cnInv: '108',
        invNumCount: 2
      },
      {
        cntrPrtNum: 1,
        cntrPrtName: 'X',
        cnName: 'A',
        cnKey: 1,
        cnInv: 'only-inv',
        invNumCount: 1
      }
    ];
    const twoLoad: SudzPmtUplTwoLoad[] = [
      { cnInv: '108', cntrPrtNum: 1, cntrPrtName: 'X', ciCount: 2 },
      { cnInv: 'б/н', cntrPrtNum: 1, cntrPrtName: 'X', ciCount: 11 }
    ];
    const rows = buildPmtSfWorklist(doubles, invNot, twoLoad);
    expect(rows).toHaveLength(3);
    expect(rows[0]).toMatchObject({ fromInvNot: true, fromTwoLoad: true, twoLoadCiCount: 2 });
    expect(rows[1]).toMatchObject({ fromInvNot: false, fromTwoLoad: true, twoLoadCiCount: 11 });
    expect(rows[2]).toMatchObject({ fromInvNot: true, fromTwoLoad: false, twoLoadCiCount: null });
  });
});
