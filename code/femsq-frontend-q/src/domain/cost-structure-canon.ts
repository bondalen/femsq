/**
 * Канон оси C структуры затрат (UtPl / ADR 012): 212 = Σ присутствующих {195,172,187}.
 *
 * Минимум «охраны»: ключ «Всего» (212) есть в схеме, и хотя бы одна составляющая
 * связана ребром 212→часть. Отсутствие двух других частей — допустимо
 * (сумма из одной составляющей).
 */

/** «Всего» (канон UtPl). */
export const COST_CANON_TOTAL = 212;

/** Составляющие: СМР / оборудование / Прочие. */
export const COST_CANON_PARTS = [195, 172, 187] as const;

export type CostCanonPartKey = (typeof COST_CANON_PARTS)[number];

/** Плоская строка дерева (совместима с fnSt DTO). */
export interface CostCanonFlatNode {
  childKey: number;
  parentKey: number | null;
}

/** Состояние канона в выбранной схеме. */
export interface CostCanonStatus {
  /** 212 присутствует в дереве. */
  totalPresent: boolean;
  /** Какие из {195,172,187} присутствуют в дереве. */
  presentParts: CostCanonPartKey[];
  /** Какие части — прямые дети 212 в этой схеме. */
  linkedParts: CostCanonPartKey[];
  /**
   * Минимум выполнен: 212 есть и ≥1 составляющая связана ребром 212→часть.
   * Полная тройка не требуется.
   */
  satisfied: boolean;
  /** Все три части связаны под 212. */
  complete: boolean;
  /** Краткое описание для UI. */
  summary: string;
}

/**
 * Оценивает канон по плоскому дереву fnSt.
 *
 * @param flat строки обхода схемы
 */
export function evaluateCostCanon(flat: readonly CostCanonFlatNode[]): CostCanonStatus {
  const keys = new Set(flat.map((row) => row.childKey));
  const totalPresent = keys.has(COST_CANON_TOTAL);
  const presentParts = COST_CANON_PARTS.filter((part) => keys.has(part));
  const linkedParts = COST_CANON_PARTS.filter((part) =>
    flat.some((row) => row.childKey === part && row.parentKey === COST_CANON_TOTAL)
  );
  const satisfied = totalPresent && linkedParts.length >= 1;
  const complete = totalPresent && linkedParts.length === COST_CANON_PARTS.length;
  let summary: string;
  if (!totalPresent) {
    summary = 'Канон: нет узла 212 (Всего)';
  } else if (linkedParts.length === 0) {
    summary = 'Канон: 212 есть, но нет рёбер 212→{195,172,187}';
  } else if (complete) {
    summary = 'Канон: 212 = 195+172+187 (полный)';
  } else {
    summary = `Канон: 212 = Σ(${linkedParts.join('+')}) · отсутствуют ${COST_CANON_PARTS.filter(
      (part) => !linkedParts.includes(part)
    ).join(',')}`;
  }
  return {
    totalPresent,
    presentParts: [...presentParts],
    linkedParts: [...linkedParts],
    satisfied,
    complete,
    summary
  };
}

/**
 * Затрагивает ли мутация ключи/рёбра канона.
 *
 * @param keys ключи узлов, участвующих в операции
 * @param parentKey родитель (для ребра), если есть
 */
export function touchesCostCanon(
  keys: readonly number[],
  parentKey?: number | null
): boolean {
  const canon = new Set<number>([COST_CANON_TOTAL, ...COST_CANON_PARTS]);
  if (keys.some((key) => canon.has(key))) {
    return true;
  }
  if (parentKey != null && canon.has(parentKey)) {
    return true;
  }
  return false;
}

/**
 * Прогноз канона после detach ребра parent→child.
 */
export function evaluateCostCanonAfterDetach(
  flat: readonly CostCanonFlatNode[],
  parentKey: number,
  childKey: number
): CostCanonStatus {
  const next = flat.filter(
    (row) => !(row.childKey === childKey && row.parentKey === parentKey)
  );
  return evaluateCostCanon(next);
}

/**
 * Прогноз канона после move child: fromParent → toParent.
 */
export function evaluateCostCanonAfterMove(
  flat: readonly CostCanonFlatNode[],
  childKey: number,
  fromParentKey: number,
  toParentKey: number
): CostCanonStatus {
  const next = flat.map((row) => {
    if (row.childKey === childKey && row.parentKey === fromParentKey) {
      return { ...row, parentKey: toParentKey };
    }
    return row;
  });
  return evaluateCostCanon(next);
}

/**
 * Прогноз канона после удаления узла (убрать узел и его вхождения как parent/child).
 */
export function evaluateCostCanonAfterDelete(
  flat: readonly CostCanonFlatNode[],
  nodeKey: number
): CostCanonStatus {
  const next = flat
    .filter((row) => row.childKey !== nodeKey)
    .map((row) =>
      row.parentKey === nodeKey ? { ...row, parentKey: null } : row
    );
  return evaluateCostCanon(next);
}
