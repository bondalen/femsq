import { describe, expect, it } from 'vitest';

import type { SudzDbtCanonPortfolioChain, SudzDbtCanonSlot } from '@/types/sudz';
import {
  addCalendarMonth,
  buildCanonPortfolioChartSpec,
  calendarDaysBetween,
  expectedQuarterEndsBetween,
  formatValuePortfolioField,
  hasQuarterMaskGap,
  valueChartDate
} from '@/utils/sudz-canon-chart';

const colors = { current: '#107c10', overdue: '#c19c00' };

function slot(overrides: Partial<SudzDbtCanonSlot> = {}): SudzDbtCanonSlot {
  return {
    slotKey: 1,
    iKey: 10,
    idNum: 2,
    varKey: 100,
    cnNum: '1',
    invNum: 'A19-16343/2021',
    orgBuirg: 1,
    csoDate: '2021-01-01',
    accountKey: 1,
    accountNum: 76,
    values: [
      {
        valueKey: 11,
        uplKey: 901,
        ttl: 200,
        overd: 50,
        uplName: 'Q1',
        uplDate: '2026-04-01',
        uplStatusOnDate: '2026-03-31',
        portfolioLabels: ['yr 2026']
      }
    ],
    ...overrides
  };
}

function chain(upls: { uplKey: number; date: string }[]): SudzDbtCanonPortfolioChain {
  return {
    id: '901',
    label: 'test',
    yrKeys: [901],
    coverage: upls.length,
    upls: upls.map((u) => ({
      uplKey: u.uplKey,
      uplName: `upl ${u.uplKey}`,
      uplDate: u.date,
      uplStatusOnDate: u.date
    }))
  };
}

describe('sudz-canon-chart S78.4 / 1.7.6', () => {
  it('valueChartDate предпочитает статус среза', () => {
    expect(valueChartDate('2026-03-31', '2026-04-01')).toBe('2026-03-31');
    expect(valueChartDate(null, '2026-04-01T00:00:00')).toBe('2026-04-01');
    expect(valueChartDate(null, null)).toBeNull();
  });

  it('formatValuePortfolioField: склейка или вне портфеля', () => {
    expect(formatValuePortfolioField([])).toBe('вне портфелей года');
    expect(formatValuePortfolioField(undefined)).toBe('вне портфелей года');
    expect(formatValuePortfolioField(['A', 'B'])).toBe('A; B');
  });

  it('на upl цепи стопка долей: 2×18000 → серии с общим stack', () => {
    const parent = slot({
      slotKey: 10,
      idNum: 0,
      values: [
        {
          valueKey: 1,
          uplKey: 803,
          ttl: 36000,
          overd: 36000,
          uplName: 'Q2',
          uplDate: '2025-06-30',
          uplStatusOnDate: '2025-06-30',
          portfolioLabels: ['2025']
        }
      ]
    });
    const a = slot({
      slotKey: 11,
      idNum: 1,
      values: [
        {
          valueKey: 2,
          uplKey: 901,
          ttl: 18000,
          overd: 18000,
          uplName: 'YE',
          uplDate: '2026-01-15',
          uplStatusOnDate: '2025-12-31',
          portfolioLabels: ['2026']
        }
      ]
    });
    const b = slot({
      slotKey: 12,
      idNum: 2,
      values: [
        {
          valueKey: 3,
          uplKey: 901,
          ttl: 18000,
          overd: 18000,
          uplName: 'YE',
          uplDate: '2026-01-15',
          uplStatusOnDate: '2025-12-31',
          portfolioLabels: ['2026']
        }
      ]
    });
    const spec = buildCanonPortfolioChartSpec(
      [parent, a, b],
      chain([
        { uplKey: 803, date: '2025-06-30' },
        { uplKey: 901, date: '2025-12-31' }
      ]),
      colors,
      null
    );
    expect(spec?.series.filter((s) => s.stack === 'canon-chain')).toHaveLength(6);
    const overd901 = spec?.series.find((s) => s.id === 'slot-11-overd')?.points.find((p) => p.x === '2025-12-31');
    expect(overd901?.y).toBe(18000);
    const parentAt901 = spec?.series.find((s) => s.id === 'slot-10-overd')?.points.find((p) => p.x === '2025-12-31');
    expect(parentAt901?.y).toBe(0);
  });

  it('вне портфеля — scatter, не область цепи', () => {
    const s = slot({
      values: [
        {
          valueKey: 9,
          uplKey: 910,
          ttl: 36000,
          overd: 36000,
          uplName: 'funnel',
          uplDate: '2026-01-20',
          uplStatusOnDate: '2025-12-31',
          portfolioLabels: []
        },
        {
          valueKey: 2,
          uplKey: 901,
          ttl: 18000,
          overd: 18000,
          uplName: 'YE',
          uplDate: '2026-01-15',
          uplStatusOnDate: '2025-12-31',
          portfolioLabels: ['2026']
        }
      ]
    });
    const spec = buildCanonPortfolioChartSpec(
      [s],
      chain([{ uplKey: 901, date: '2025-12-31' }]),
      colors,
      null
    );
    const off = spec?.series.find((ser) => ser.id === 'off-pf-9');
    expect(off?.chartType).toBe('scatter');
    expect(off?.points[0]).toEqual({ x: '2025-12-31', y: 36000 });
  });

  it('addCalendarMonth не перескакивает с 31 декабря', () => {
    expect(addCalendarMonth('2025-12-31')).toBe('2026-01-31');
    expect(addCalendarMonth('2025-06-30')).toBe('2025-07-30');
  });

  it('calendarDaysBetween считает сутки', () => {
    expect(calendarDaysBetween('2025-06-30', '2025-12-31')).toBeGreaterThan(120);
  });

  it('expectedQuarterEndsBetween: Q3 между Q2 и YE', () => {
    expect(expectedQuarterEndsBetween('2025-06-30', '2025-12-31')).toEqual(['2025-09-30']);
    expect(expectedQuarterEndsBetween('2025-06-30', '2025-09-30')).toEqual([]);
  });

  it('дыра маски: нет Q3 между Q2 и YE — пунктирный мост', () => {
    const s = slot({
      values: [
        {
          valueKey: 1,
          uplKey: 803,
          ttl: 100,
          overd: 100,
          uplName: 'Q2',
          uplDate: '2025-06-30',
          uplStatusOnDate: '2025-06-30',
          portfolioLabels: ['2025']
        },
        {
          valueKey: 2,
          uplKey: 901,
          ttl: 200,
          overd: 200,
          uplName: 'YE',
          uplDate: '2026-01-15',
          uplStatusOnDate: '2025-12-31',
          portfolioLabels: ['2026']
        }
      ]
    });
    const spec = buildCanonPortfolioChartSpec(
      [s],
      chain([
        { uplKey: 803, date: '2025-06-30' },
        { uplKey: 901, date: '2025-12-31' }
      ]),
      colors,
      null
    );
    const gap = spec?.series.find((ser) => ser.id === 'gap-803-901') as
      | { lineDash?: boolean }
      | undefined;
    expect(gap?.lineDash).toBe(true);
  });

  it('соседние кварталы без дыры — без пунктира (даже при большом интервале суток)', () => {
    const present = new Set(['2025-03-31', '2025-06-30', '2025-09-30', '2025-12-31']);
    expect(hasQuarterMaskGap('2025-06-30', '2025-09-30', present)).toBe(false);
    expect(hasQuarterMaskGap('2025-03-31', '2025-09-30', present)).toBe(false);
    expect(hasQuarterMaskGap('2025-03-31', '2025-09-30', new Set(['2025-03-31', '2025-09-30']))).toBe(
      true
    );

    const s = slot({
      values: [
        {
          valueKey: 1,
          uplKey: 802,
          ttl: 100,
          overd: 50,
          uplName: 'Q1',
          uplDate: '2025-04-01',
          uplStatusOnDate: '2025-03-31',
          portfolioLabels: ['2025']
        },
        {
          valueKey: 2,
          uplKey: 803,
          ttl: 120,
          overd: 60,
          uplName: 'Q2',
          uplDate: '2025-07-01',
          uplStatusOnDate: '2025-06-30',
          portfolioLabels: ['2025']
        }
      ]
    });
    const spec = buildCanonPortfolioChartSpec(
      [s],
      chain([
        { uplKey: 802, date: '2025-03-31' },
        { uplKey: 803, date: '2025-06-30' }
      ]),
      colors,
      null
    );
    expect(spec?.series.some((ser) => String(ser.id).startsWith('gap-'))).toBe(false);
  });
});
