import { beforeEach, describe, expect, it, vi } from 'vitest';
import { createPinia, setActivePinia } from 'pinia';

import * as sudzApi from '@/api/sudz-api';
import { useSudzPmtUplStore } from '@/stores/sudz-pmt-upl';
import type {
  SudzPmtUplCstNew,
  SudzPmtUplInvNot,
  SudzPmtUplLauncher,
  SudzPmtUplTabBadges,
  SudzPmtUplTwoLoad
} from '@/types/sudz';

vi.mock('@/api/sudz-api', () => ({
  createSudzPmUpl: vi.fn(),
  getSudzPmUplLauncher: vi.fn(),
  getSudzPmUplLookups: vi.fn(),
  getSudzPmtUplCstMatch: vi.fn(),
  getSudzPmtUplCstNew: vi.fn(),
  getSudzPmtUplInvNot: vi.fn(),
  getSudzPmtUplSfDoubles: vi.fn(),
  getSudzPmtUplTabBadges: vi.fn(),
  getSudzPmtUplTwoLoad: vi.fn(),
  rebuildSudzPmtUplSfDouble: vi.fn(),
  runSudzPmtUplFunnel: vi.fn(),
  updateSudzPmUplFile: vi.fn()
}));

const launcher: SudzPmtUplLauncher = {
  upl: { pmKey: 59, name: 'pm 59', date: '2026-01-30' },
  file: {
    cipufKey: 1,
    cipufUpload: 59,
    cipufPath: '',
    cipufFlLoad: false,
    cipufFlTbl: false,
    cipufLoadingProgress: null,
    cipufSheet: null
  }
};

const cstRows: SudzPmtUplCstNew[] = [
  { cacOrNull: '001-1234567', sh: '234567', ipCode: '234567', pirIDnew: null, pirName: null }
];

const invNotRows: SudzPmtUplInvNot[] = [
  {
    cntrPrtNum: 1000376,
    cntrPrtName: 'Акт',
    cnName: 'КС-14',
    cnKey: 877,
    cnInv: 'Акт № 3',
    invNumCount: 1
  }
];

const twoLoadRows: SudzPmtUplTwoLoad[] = [
  { cnInv: '108', cntrPrtNum: 1009345, cntrPrtName: 'ООО', ciCount: 2 }
];

const badges: SudzPmtUplTabBadges = { cstNew: 1, invNot: 8, twoLoad: 13, sfOpen: 0 };

describe('useSudzPmtUplStore queues', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    vi.mocked(sudzApi.getSudzPmUplLauncher).mockResolvedValue(launcher);
    vi.mocked(sudzApi.getSudzPmtUplCstNew).mockResolvedValue(cstRows);
    vi.mocked(sudzApi.getSudzPmtUplInvNot).mockResolvedValue(invNotRows);
    vi.mocked(sudzApi.getSudzPmtUplTwoLoad).mockResolvedValue(twoLoadRows);
    vi.mocked(sudzApi.rebuildSudzPmtUplSfDouble).mockResolvedValue(2);
    vi.mocked(sudzApi.getSudzPmtUplSfDoubles)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);
    vi.mocked(sudzApi.getSudzPmtUplTabBadges).mockResolvedValue(badges);
  });

  it('selectUpl грузит лаунчер, очереди и бейджи по pmKey', async () => {
    const store = useSudzPmtUplStore();
    await store.selectUpl(59);

    expect(sudzApi.getSudzPmUplLauncher).toHaveBeenCalledWith(59);
    expect(sudzApi.getSudzPmtUplCstNew).toHaveBeenCalledWith(59);
    expect(sudzApi.getSudzPmtUplInvNot).toHaveBeenCalledWith(59);
    expect(sudzApi.getSudzPmtUplTwoLoad).toHaveBeenCalledWith(59);
    expect(sudzApi.rebuildSudzPmtUplSfDouble).toHaveBeenCalledWith(59);
    expect(sudzApi.getSudzPmtUplSfDoubles).toHaveBeenCalledWith(59);
    expect(sudzApi.getSudzPmtUplSfDoubles).toHaveBeenCalledTimes(2);
    expect(sudzApi.getSudzPmtUplTabBadges).toHaveBeenCalledWith(59);
    expect(store.cstNew).toEqual(cstRows);
    expect(store.invNot).toEqual(invNotRows);
    expect(store.twoLoad).toEqual(twoLoadRows);
    expect(store.badges).toEqual(badges);
    expect(store.cstNewLoading).toBe(false);
    expect(store.invNotLoading).toBe(false);
    expect(store.twoLoadLoading).toBe(false);
    expect(store.badgesLoading).toBe(false);
  });

  it('loadCstMatch хранит дерево по хвосту и clearCstMatch его снимает', async () => {
    vi.mocked(sudzApi.getSudzPmtUplCstMatch).mockResolvedValue([
      { cstKey: 10, cstName: 'Север', agents: [] }
    ]);
    const store = useSudzPmtUplStore();
    await store.loadCstMatch('006707');

    expect(sudzApi.getSudzPmtUplCstMatch).toHaveBeenCalledWith('006707');
    expect(store.cstMatch).toEqual([{ cstKey: 10, cstName: 'Север', agents: [] }]);
    expect(store.cstMatchLoading).toBe(false);

    store.clearCstMatch();
    expect(store.cstMatch).toEqual([]);
    expect(store.cstMatchSuffix).toBeNull();
  });

  it('ошибка бейджей не стирает уже загруженные гриды', async () => {
    vi.mocked(sudzApi.getSudzPmtUplTabBadges).mockRejectedValue(new Error('badges down'));
    const store = useSudzPmtUplStore();
    await store.selectUpl(59);

    expect(store.cstNew).toEqual(cstRows);
    expect(store.invNot).toEqual(invNotRows);
    expect(store.twoLoad).toEqual(twoLoadRows);
    expect(store.badges).toBeNull();
    expect(store.error).toBe('badges down');
  });
});
