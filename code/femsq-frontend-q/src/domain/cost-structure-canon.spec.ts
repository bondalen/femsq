import { describe, expect, it } from 'vitest';

import {
  COST_CANON_TOTAL,
  evaluateCostCanon,
  evaluateCostCanonAfterDelete,
  evaluateCostCanonAfterDetach,
  evaluateCostCanonAfterMove,
  touchesCostCanon
} from './cost-structure-canon';

describe('evaluateCostCanon', () => {
  it('минимум: 212 и одна часть — satisfied, не complete', () => {
    const status = evaluateCostCanon([
      { childKey: 214, parentKey: null },
      { childKey: 212, parentKey: 214 },
      { childKey: 195, parentKey: 212 }
    ]);
    expect(status.satisfied).toBe(true);
    expect(status.complete).toBe(false);
    expect(status.linkedParts).toEqual([195]);
    expect(status.summary).toContain('195');
  });

  it('полный канон 212=195+172+187', () => {
    const status = evaluateCostCanon([
      { childKey: 212, parentKey: 214 },
      { childKey: 195, parentKey: 212 },
      { childKey: 172, parentKey: 212 },
      { childKey: 187, parentKey: 212 }
    ]);
    expect(status.satisfied).toBe(true);
    expect(status.complete).toBe(true);
  });

  it('без рёбер частей — не satisfied', () => {
    const status = evaluateCostCanon([
      { childKey: 214, parentKey: null },
      { childKey: 212, parentKey: 214 }
    ]);
    expect(status.satisfied).toBe(false);
    expect(status.linkedParts).toHaveLength(0);
  });
});

describe('прогнозы мутаций', () => {
  const base = [
    { childKey: 214, parentKey: null },
    { childKey: 212, parentKey: 214 },
    { childKey: 195, parentKey: 212 }
  ];

  it('detach последней части ломает минимум', () => {
    const after = evaluateCostCanonAfterDetach(base, COST_CANON_TOTAL, 195);
    expect(after.satisfied).toBe(false);
  });

  it('move части от 212 ломает минимум', () => {
    const after = evaluateCostCanonAfterMove(base, 195, COST_CANON_TOTAL, 214);
    expect(after.satisfied).toBe(false);
  });

  it('delete 212 ломает минимум', () => {
    const after = evaluateCostCanonAfterDelete(base, COST_CANON_TOTAL);
    expect(after.satisfied).toBe(false);
  });
});

describe('touchesCostCanon', () => {
  it('ловит ключи и родителя канона', () => {
    expect(touchesCostCanon([195])).toBe(true);
    expect(touchesCostCanon([99], 212)).toBe(true);
    expect(touchesCostCanon([99], 214)).toBe(false);
  });
});
