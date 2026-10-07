import type {
  SudzCnInvUplSfDouble,
  SudzPmtUplInvNot,
  SudzPmtUplTwoLoad
} from '@/types/sudz';

/**
 * Строка единого грида «повторяющиеся СФ»: зерно = очередь КСДСФ (1 ciput),
 * флаги — принадлежность к диагностикам InvNot / TwoLoad.
 */
export interface SudzPmtSfWorkRow extends SudzCnInvUplSfDouble {
  fromInvNot: boolean;
  fromTwoLoad: boolean;
  /** ci× из TwoLoad, если номер есть в диагностике. */
  twoLoadCiCount: number | null;
}

/**
 * Нормализует номер СФ для сопоставления диагнозов и очереди.
 *
 * @param value сырое значение
 * @return ключ сравнения или null
 */
export function normalizePmtInvNum(value: string | null | undefined): string | null {
  if (value == null) {
    return null;
  }
  const t = value.trim();
  if (t === '') {
    return 'NullИлиПусто';
  }
  return t;
}

/**
 * Собирает worklist: строки SfDouble + флаги InvNot/TwoLoad по № СФ (± cn).
 * Пересечение диагнозов на одном ciput даёт оба флага — число строк = очередь разбора.
 *
 * @param sfDoubles очередь КСДСФ пакета
 * @param invNot диагностика InvNot
 * @param twoLoad диагностика TwoLoad
 * @return строки для одного грида
 */
export function buildPmtSfWorklist(
  sfDoubles: SudzCnInvUplSfDouble[],
  invNot: SudzPmtUplInvNot[],
  twoLoad: SudzPmtUplTwoLoad[]
): SudzPmtSfWorkRow[] {
  const invByNum = new Map<string, SudzPmtUplInvNot[]>();
  for (const row of invNot) {
    const key = normalizePmtInvNum(row.cnInv);
    if (key == null) {
      continue;
    }
    const list = invByNum.get(key);
    if (list) {
      list.push(row);
    } else {
      invByNum.set(key, [row]);
    }
  }
  const twoByNum = new Map<string, SudzPmtUplTwoLoad>();
  for (const row of twoLoad) {
    const key = normalizePmtInvNum(row.cnInv);
    if (key == null) {
      continue;
    }
    twoByNum.set(key, row);
  }

  return sfDoubles.map((sf) => {
    const invKey = normalizePmtInvNum(sf.ciusInvNum);
    const invHits = invKey != null ? (invByNum.get(invKey) ?? []) : [];
    // cn на очереди задан (обычно из InvNot) — требуем тот же cn; иначе (TwoLoad) достаточно №
    const fromInvNot =
      invHits.length > 0 &&
      (sf.ciusCnKey == null || invHits.some((h) => h.cnKey === sf.ciusCnKey));
    const two = invKey != null ? twoByNum.get(invKey) : undefined;
    return {
      ...sf,
      fromInvNot,
      fromTwoLoad: two != null,
      twoLoadCiCount: two?.ciCount ?? null
    };
  });
}
