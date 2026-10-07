import { describe, expect, it } from 'vitest';

import {
  PMT_CST_AGENTS_QUERY,
  PMT_CST_POINTS_QUERY,
  lookupsForAgentCode,
  pmtCstMatchQueryRows,
  pmtCstMatchRootRows,
  pmtCstMatchRootsToken,
  queueAgentCode
} from '@/sudz/pmt-cst-match-tree';
import type { SudzPmtUplCstMatch } from '@/types/sudz';

const sites: SudzPmtUplCstMatch[] = [
  {
    cstKey: 10,
    cstName: 'Север',
    agents: [
      {
        cstaKey: 1,
        agentLabel: 'Газпром',
        ogaCode: '051',
        points: [
          { cstapKey: 100, cstapIpgPnN: '051-2006707', sameSuffix: true },
          { cstapKey: 101, cstapIpgPnN: '051-1999999', sameSuffix: false }
        ]
      },
      { cstaKey: 2, agentLabel: null, ogaCode: null, points: [] }
    ]
  }
];

describe('pmtCstMatch forest host', () => {
  it('токен меняется с хвостом и составом каталога', () => {
    expect(pmtCstMatchRootsToken('6707', sites)).toContain('6707|10[1:100+101,2:]');
    expect(pmtCstMatchRootsToken('', sites)).toBe('');
    expect(pmtCstMatchRootsToken('6707', [])).toBe('6707|');
  });

  it('корни и дети несут подпись, ключ и отметку хвоста', () => {
    expect(pmtCstMatchRootRows(sites)).toEqual([
      {
        key: 10,
        fields: [
          { name: 'label', value: 'Север' },
          { name: 'keyText', value: '10' },
          { name: 'extra', value: '' }
        ]
      }
    ]);
    expect(pmtCstMatchQueryRows(PMT_CST_AGENTS_QUERY, 10, sites)[0]).toEqual({
      key: 1,
      fields: [
        { name: 'label', value: 'Газпром' },
        { name: 'keyText', value: '1' },
        { name: 'extra', value: '051' }
      ]
    });
    const points = pmtCstMatchQueryRows(PMT_CST_POINTS_QUERY, 1, sites);
    expect(points[0].fields.find((field) => field.name === 'extra')?.value).toBe('тот же хвост');
    expect(points[1].fields.find((field) => field.name === 'extra')?.value).toBe('');
  });

  it('подсказывает агента по первым трём символам кода и не предлагает остальных', () => {
    expect(queueAgentCode('051-2006707')).toBe('051');
    const matches = lookupsForAgentCode(
      [
        { ogaKey: 1, ogaNm: '051 Газпром инвест, ООО' },
        { ogaKey: 2, ogaNm: '014 Строй' }
      ],
      '051'
    );
    expect(matches.map((item) => item.ogaKey)).toEqual([1]);
    expect(lookupsForAgentCode([{ ogaKey: 3, ogaNm: '014 Строй' }], '051')).toEqual([]);
  });
});
