import { describe, expect, it } from 'vitest';

import type { SudzDbtCanonSlot } from '@/types/sudz';
import {
  addCalendarMonth,
  buildCanonSlotAreasSpec,
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
        uplStatusOnDate: '2026-03-31'
      }
    ],
    ...overrides
  };
}

describe('sudz-canon-chart S78.4', () => {
  it('valueChartDate предпочитает статус среза', () => {
    expect(valueChartDate('2026-03-31', '2026-04-01')).toBe('2026-03-31');
    expect(valueChartDate(null, '2026-04-01T00:00:00')).toBe('2026-04-01');
    expect(valueChartDate(null, null)).toBeNull();
  });

  it('две stacked area-серии на слот: overd снизу, current = ttl−overd', () => {
    const spec = buildCanonSlotAreasSpec([slot()], colors, 1);
    expect(spec?.kind).toBe('line');
    expect(spec?.series).toHaveLength(2);
    expect(spec?.series[0].stack).toBe('canon-split');
    expect(spec?.series[0].area).toBe(true);
    expect(spec?.series[0].points).toEqual([
      { x: '2026-03-31', y: 50 },
      { x: '2026-04-30', y: 50 }
    ]);
    expect(spec?.series[1].points).toEqual([
      { x: '2026-03-31', y: 150 },
      { x: '2026-04-30', y: 150 }
    ]);
    expect(spec?.series[0].step).toBe('end');
    expect(spec?.x.tickFormat).toBe('yy-MM');
    expect(spec?.x.padEndDays).toBe(20);
  });

  it('дубли слота и одной даты не плодят серии', () => {
    const twin = slot();
    const sameDay = slot({
      values: [
        {
          valueKey: 11,
          uplKey: 901,
          ttl: 200,
          overd: 50,
          uplName: 'Q1',
          uplDate: '2026-04-01',
          uplStatusOnDate: '2026-03-31'
        },
        {
          valueKey: 12,
          uplKey: 900,
          ttl: 180,
          overd: 40,
          uplName: 'Q0',
          uplDate: '2026-03-01',
          uplStatusOnDate: '2026-03-31'
        }
      ]
    });
    const spec = buildCanonSlotAreasSpec([sameDay, twin], colors, 1);
    expect(spec?.series).toHaveLength(2);
    expect(spec?.series[0].points).toHaveLength(2);
  });

  it('addCalendarMonth не перескакивает с 31 декабря', () => {
    expect(addCalendarMonth('2025-12-31')).toBe('2026-01-31');
    expect(addCalendarMonth('2025-06-30')).toBe('2025-07-30');
  });

  it('включает всю историю Value, не только последний год', () => {
    const long = slot({
      values: [
        {
          valueKey: 11,
          uplKey: 901,
          ttl: 200,
          overd: 50,
          uplName: 'YE',
          uplDate: '2025-12-31',
          uplStatusOnDate: '2025-12-31'
        },
        {
          valueKey: 12,
          uplKey: 100,
          ttl: 80,
          overd: 10,
          uplName: 'old',
          uplDate: '2018-05-23',
          uplStatusOnDate: '2018-05-23'
        }
      ]
    });
    const spec = buildCanonSlotAreasSpec([long], colors, 1);
    const xs = spec?.series[0].points.map((p) => p.x);
    expect(xs?.[0]).toBe('2018-05-23');
    expect(xs).toContain('2025-12-31');
    expect(xs?.[xs.length - 1]).toBe('2025-12-31');
  });

  it('хвост +1 месяц только у слотов с одной датой (доли split)', () => {
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
          uplStatusOnDate: '2025-06-30'
        },
        {
          valueKey: 2,
          uplKey: 910,
          ttl: 36000,
          overd: 36000,
          uplName: 'YE',
          uplDate: '2025-12-31',
          uplStatusOnDate: '2025-12-31'
        }
      ]
    });
    const child = slot({
      slotKey: 11,
      idNum: 1,
      values: [
        {
          valueKey: 3,
          uplKey: 901,
          ttl: 18000,
          overd: 18000,
          uplName: 'YE',
          uplDate: '2025-12-31',
          uplStatusOnDate: '2025-12-31'
        }
      ]
    });
    const spec = buildCanonSlotAreasSpec([parent, child], colors, 10);
    const parentXs = spec?.series[0].points.map((p) => p.x);
    const childXs = spec?.series[2].points.map((p) => p.x);
    expect(parentXs).toEqual(['2025-06-30', '2025-12-31']);
    expect(childXs).toEqual(['2025-12-31', '2026-01-31']);
    const ids = spec?.series.map((s) => s.id) ?? [];
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('без даты точки не рисует нулём', () => {
    const emptyDate = slot({
      values: [
        {
          valueKey: 12,
          uplKey: 900,
          ttl: 10,
          overd: 0,
          uplName: 'x',
          uplDate: null,
          uplStatusOnDate: null
        }
      ]
    });
    expect(buildCanonSlotAreasSpec([emptyDate], colors, null)).toBeNull();
  });
});
