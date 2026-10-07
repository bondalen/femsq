/**
 * График канона Dbt: области по цепи портфелей + красные маркеры вне портфеля.
 */

import type { ChartSpec, ChartSeriesSpec } from 'fequlib';

import type {
  SudzDbtCanonChainUpl,
  SudzDbtCanonPortfolioChain,
  SudzDbtCanonSlot
} from '@/types/sudz';

export interface CanonChartColors {
  current: string;
  overdue: string;
}

/** Красный маркер свода вне портфеля. */
export const CANON_OFF_PORTFOLIO_COLOR = '#c10015';

/** Концы кварталов: 31.03 / 30.06 / 30.09 / 31.12. */
const QUARTER_END_MD: ReadonlyArray<readonly [number, number]> = [
  [3, 31],
  [6, 30],
  [9, 30],
  [12, 31]
];

/**
 * Цвета серий из токенов темы (хост, не feQuLib).
 */
export function readCanonChartColors(): CanonChartColors {
  if (typeof document === 'undefined') {
    return { current: '#98c379', overdue: '#d19a66' };
  }
  const styles = getComputedStyle(document.documentElement);
  const current = styles.getPropertyValue('--femsq-chart-current').trim();
  const overdue = styles.getPropertyValue('--femsq-chart-overdue').trim();
  return {
    current: current || '#98c379',
    overdue: overdue || '#d19a66'
  };
}

/**
 * Дата точки: статус среза, иначе дата выгрузки.
 *
 * @param uplStatusOnDate статус
 * @param uplDate дата выгрузки
 */
export function valueChartDate(
  uplStatusOnDate: string | null | undefined,
  uplDate: string | null | undefined
): string | null {
  const status = uplStatusOnDate?.trim() ?? '';
  if (status.length >= 10) {
    return status.slice(0, 10);
  }
  const raw = uplDate?.trim() ?? '';
  return raw.length >= 10 ? raw.slice(0, 10) : null;
}

/**
 * Дата плюс один календарный месяц.
 *
 * @param iso ГГГГ-ММ-ДД
 */
export function addCalendarMonth(iso: string): string {
  const parts = iso.slice(0, 10).split('-').map(Number);
  const year0 = parts[0];
  const month0 = parts[1];
  const day0 = parts[2];
  if (year0 == null || month0 == null || day0 == null) {
    return iso.slice(0, 10);
  }
  let year = year0;
  let month = month0 + 1;
  if (month > 12) {
    month = 1;
    year += 1;
  }
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const day = Math.min(day0, lastDay);
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

/**
 * Текст портфелей для строки Value в дереве.
 *
 * @param labels portfolioLabels с API
 */
export function formatValuePortfolioField(labels: string[] | null | undefined): string {
  if (!labels || labels.length === 0) {
    return 'вне портфелей года';
  }
  return labels.join('; ');
}

/**
 * Дата оси для точки цепи.
 *
 * @param upl точка цепи
 */
export function chainUplChartDate(upl: SudzDbtCanonChainUpl): string | null {
  return valueChartDate(upl.uplStatusOnDate, upl.uplDate);
}

/**
 * Число суток между двумя ISO-датами.
 *
 * @param a ГГГГ-ММ-ДД
 * @param b ГГГГ-ММ-ДД
 */
export function calendarDaysBetween(a: string, b: string): number {
  const ta = Date.parse(`${a.slice(0, 10)}T00:00:00Z`);
  const tb = Date.parse(`${b.slice(0, 10)}T00:00:00Z`);
  if (!Number.isFinite(ta) || !Number.isFinite(tb)) {
    return 0;
  }
  return Math.round(Math.abs(tb - ta) / 86_400_000);
}

/**
 * Канонические даты концов кварталов строго между left и right.
 *
 * @param left ГГГГ-ММ-ДД (включительно не входит)
 * @param right ГГГГ-ММ-ДД (включительно не входит)
 */
export function expectedQuarterEndsBetween(left: string, right: string): string[] {
  const a = left.slice(0, 10);
  const b = right.slice(0, 10);
  if (a >= b) {
    return [];
  }
  const yStart = Number(a.slice(0, 4));
  const yEnd = Number(b.slice(0, 4));
  if (!Number.isFinite(yStart) || !Number.isFinite(yEnd)) {
    return [];
  }
  const out: string[] = [];
  for (let y = yStart; y <= yEnd; y++) {
    for (const [m, d] of QUARTER_END_MD) {
      const iso = `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      if (iso > a && iso < b) {
        out.push(iso);
      }
    }
  }
  return out;
}

/**
 * Между двумя present-upl есть дыра маски кварталов (конец Q отсутствует в цепи).
 *
 * @param leftDate дата левого upl
 * @param rightDate дата правого upl
 * @param presentDates множество дат среза upl цепи
 */
export function hasQuarterMaskGap(
  leftDate: string,
  rightDate: string,
  presentDates: ReadonlySet<string>
): boolean {
  for (const expected of expectedQuarterEndsBetween(leftDate, rightDate)) {
    if (!presentDates.has(expected)) {
      return true;
    }
  }
  return false;
}

/**
 * ChartSpec по выбранной цепи портфелей.
 * На каждом upl цепи — стопка долей (общий stack); нет Value → 0.
 * Вне портфеля — scatter. Дыра маски кварталов — пунктирный мост.
 *
 * @param slots слоты карточки
 * @param chain выбранная цепь
 * @param colors палитра
 * @param selectedSlotKey подсветка слота
 */
export function buildCanonPortfolioChartSpec(
  slots: SudzDbtCanonSlot[],
  chain: SudzDbtCanonPortfolioChain | null | undefined,
  colors: CanonChartColors,
  selectedSlotKey: number | null
): ChartSpec | null {
  const series: ChartSeriesSpec[] = [];
  const chainUpls = chain?.upls ?? [];
  const chainUplKeys = new Set(chainUpls.map((u) => u.uplKey));

  if (chainUpls.length) {
    const axisDates: { uplKey: number; date: string }[] = [];
    for (const upl of chainUpls) {
      const date = chainUplChartDate(upl);
      if (date) {
        axisDates.push({ uplKey: upl.uplKey, date });
      }
    }
    if (!axisDates.length) {
      return null;
    }

    const presentDates = new Set(axisDates.map((p) => p.date));

    const seenSlots = new Set<number>();
    for (const slot of slots) {
      if (seenSlots.has(slot.slotKey)) {
        continue;
      }
      seenSlots.add(slot.slotKey);
      const byUpl = new Map<number, { overd: number; current: number }>();
      for (const item of slot.values) {
        if (!chainUplKeys.has(item.uplKey)) {
          continue;
        }
        const ttl = item.ttl ?? 0;
        const overd = item.overd ?? 0;
        byUpl.set(item.uplKey, { overd, current: Math.max(ttl - overd, 0) });
      }
      const points = axisDates.map(({ uplKey, date }) => {
        const sums = byUpl.get(uplKey) ?? { overd: 0, current: 0 };
        return { date, overd: sums.overd, current: sums.current };
      });
      const dim = selectedSlotKey != null && selectedSlotKey !== slot.slotKey;
      const opacity = dim ? 0.18 : 0.55;
      const label = `#${slot.idNum}`;
      /** Общая стопка состава канона на upl цепи. */
      const stack = 'canon-chain';
      series.push({
        id: `slot-${slot.slotKey}-overd`,
        name: `${label} проср.`,
        points: points.map((p) => ({ x: p.date, y: p.overd })),
        color: colors.overdue,
        area: true,
        areaOpacity: opacity,
        stack,
        step: 'end',
        showLine: !dim
      });
      series.push({
        id: `slot-${slot.slotKey}-curr`,
        name: `${label} текущ.`,
        points: points.map((p) => ({ x: p.date, y: p.current })),
        color: colors.current,
        area: true,
        areaOpacity: opacity,
        stack,
        step: 'end',
        showLine: !dim
      });
    }

    for (let i = 0; i < axisDates.length - 1; i++) {
      const left = axisDates[i];
      const right = axisDates[i + 1];
      if (!left || !right) {
        continue;
      }
      if (!hasQuarterMaskGap(left.date, right.date, presentDates)) {
        continue;
      }
      let yLeft = 0;
      let yRight = 0;
      for (const slot of slots) {
        for (const item of slot.values) {
          if (item.uplKey === left.uplKey) {
            yLeft += item.ttl ?? 0;
          }
          if (item.uplKey === right.uplKey) {
            yRight += item.ttl ?? 0;
          }
        }
      }
      series.push({
        id: `gap-${left.uplKey}-${right.uplKey}`,
        name: 'пробел данных',
        points: [
          { x: left.date, y: yLeft },
          { x: right.date, y: yRight }
        ],
        color: '#888888',
        area: false,
        showLine: true,
        lineDash: true,
        symbolSize: 0
      } as ChartSeriesSpec);
    }
  }

  for (const slot of slots) {
    for (const item of slot.values) {
      const labels = item.portfolioLabels ?? [];
      if (labels.length > 0) {
        continue;
      }
      const date = valueChartDate(item.uplStatusOnDate, item.uplDate);
      if (!date) {
        continue;
      }
      series.push({
        id: `off-pf-${item.valueKey}`,
        name: `вне pf · upl ${item.uplKey}`,
        points: [{ x: date, y: item.ttl ?? 0 }],
        color: CANON_OFF_PORTFOLIO_COLOR,
        chartType: 'scatter',
        symbolSize: 10,
        showLine: false
      });
    }
  }

  if (!series.length) {
    return null;
  }
  return {
    kind: 'line',
    title: 'Суммы по выгрузкам портфеля',
    x: { type: 'time', label: 'Дата среза', tickFormat: 'yy-MM', padEndDays: 20 },
    y: { format: 'money' },
    series,
    zoomControls: true
  };
}

/**
 * @deprecated Используйте {@link buildCanonPortfolioChartSpec}.
 */
export function buildCanonSlotAreasSpec(
  slots: SudzDbtCanonSlot[],
  colors: CanonChartColors,
  selectedSlotKey: number | null
): ChartSpec | null {
  return buildCanonPortfolioChartSpec(slots, null, colors, selectedSlotKey);
}
