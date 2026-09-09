/**
 * График канона Dbt: две области на слот (просрочено / непросрочено).
 */

import type { ChartSpec, ChartSeriesSpec } from 'fequlib';

import type { SudzDbtCanonSlot } from '@/types/sudz';

export interface CanonChartColors {
  current: string;
  overdue: string;
}

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
 * Дата плюс один календарный месяц (для «хвоста» области справа).
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
 * Собирает ChartSpec областей по слотам канона.
 * Все слоты: проср./текущ. в стопке слота. Доли split (одна дата среза) —
 * общая стопка `canon-split` и хвост +1 месяц, чтобы не перекрываться «старым» слотом.
 *
 * @param slots слоты карточки
 * @param colors палитра темы
 * @param selectedSlotKey подсветка слота (остальные приглушены)
 */
export function buildCanonSlotAreasSpec(
  slots: SudzDbtCanonSlot[],
  colors: CanonChartColors,
  selectedSlotKey: number | null
): ChartSpec | null {
  const series: ChartSeriesSpec[] = [];
  const seenSlots = new Set<number>();
  for (const slot of slots) {
    if (seenSlots.has(slot.slotKey)) {
      continue;
    }
    seenSlots.add(slot.slotKey);
    const byDate = new Map<string, { overd: number; current: number }>();
    for (const item of slot.values) {
      const date = valueChartDate(item.uplStatusOnDate, item.uplDate);
      if (!date || byDate.has(date)) {
        continue;
      }
      const ttl = item.ttl ?? 0;
      const overd = item.overd ?? 0;
      byDate.set(date, { overd, current: Math.max(ttl - overd, 0) });
    }
    const points = [...byDate.entries()]
      .map(([date, sums]) => ({ date, ...sums }))
      .sort((a, b) => a.date.localeCompare(b.date));
    if (!points.length) {
      continue;
    }
    const last = points[points.length - 1];
    const first = points[0];
    const isEndSliceOnly = !!(last && first && first.date === last.date);
    if (isEndSliceOnly && last) {
      const tail = addCalendarMonth(last.date);
      if (tail > last.date) {
        points.push({ date: tail, overd: last.overd, current: last.current });
      }
    }
    const dim = selectedSlotKey != null && selectedSlotKey !== slot.slotKey;
    const opacity = dim ? 0.18 : 0.55;
    const stack = isEndSliceOnly ? 'canon-split' : `slot-${slot.slotKey}`;
    const label = `#${slot.idNum}`;
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
  if (!series.length) {
    return null;
  }
  return {
    kind: 'line',
    title: 'Суммы по выгрузкам',
    x: { type: 'time', label: 'Дата среза', tickFormat: 'yy-MM', padEndDays: 20 },
    y: { format: 'money' },
    series,
    zoomControls: true
  };
}
