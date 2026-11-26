package com.femsq.database.util;

import java.math.BigDecimal;

/**
 * Согласование оси итог = сумма частей (ADR 012 / R-MONEY-AGG).
 *
 * <p>Каноны: Q — авторитет Ttl, δ→Oth; A — части→Ttl; A-hard — BLOCK; S — STRUCT без выдуманной разбивки.
 */
public final class AggAxis {

    private AggAxis() {
    }

    /**
     * Согласование в млн ₽ (scale 8).
     *
     * @param ttl  итог / 212 (nullable)
     * @param wrk  СМР / 195
     * @param equ  оборудование / 172
     * @param oth  прочие / 187
     */
    public static AggAxisResult reconcileMln(
            BigDecimal ttl, BigDecimal wrk, BigDecimal equ, BigDecimal oth) {
        BigDecimal t = FemsqMoney.roundMln(ttl);
        BigDecimal w = FemsqMoney.roundMln(wrk);
        BigDecimal e = FemsqMoney.roundMln(equ);
        BigDecimal o = FemsqMoney.roundMln(oth);
        return reconcile(
                t, w, e, o,
                FemsqMoney.EPS_Q_MLN,
                FemsqMoney.epsBlockMln(t, sumParts(w, e, o)),
                FemsqMoney.SCALE_MLN);
    }

    /**
     * Согласование в ₽ (scale 4, money).
     */
    public static AggAxisResult reconcileRub(
            BigDecimal total, BigDecimal work, BigDecimal equip, BigDecimal others) {
        BigDecimal t = FemsqMoney.roundRub(total);
        BigDecimal w = FemsqMoney.roundRub(work);
        BigDecimal e = FemsqMoney.roundRub(equip);
        BigDecimal o = FemsqMoney.roundRub(others);
        BigDecimal epsQ = new BigDecimal("0.01");
        return reconcile(
                t, w, e, o,
                epsQ,
                FemsqMoney.epsBlockRub(t, sumParts(w, e, o)),
                FemsqMoney.SCALE_RUB);
    }

    private static AggAxisResult reconcile(
            BigDecimal t,
            BigDecimal w,
            BigDecimal e,
            BigDecimal o,
            BigDecimal epsQ,
            BigDecimal epsBlock,
            int scale) {
        boolean anyPart = isNonZero(w) || isNonZero(e) || isNonZero(o);
        boolean hasTtl = isNonZero(t);

        if (!hasTtl && !anyPart) {
            return new AggAxisResult(AggAxisKind.OK, t, w, e, o, BigDecimal.ZERO.setScale(scale),
                    AggAxisResult.CODE_OK);
        }

        if (hasTtl && !anyPart) {
            return new AggAxisResult(AggAxisKind.STRUCT, t, w, e, o, t,
                    AggAxisResult.CODE_STRUCT);
        }

        if (!hasTtl && anyPart) {
            BigDecimal parts = sumParts(w, e, o);
            return new AggAxisResult(AggAxisKind.STRUCT, t, w, e, o, parts.negate(),
                    AggAxisResult.CODE_STRUCT);
        }

        BigDecimal parts = sumParts(w, e, o);
        BigDecimal delta = t.subtract(parts);
        BigDecimal absDelta = delta.abs();

        if (absDelta.compareTo(BigDecimal.ZERO) == 0) {
            return new AggAxisResult(AggAxisKind.OK, t, w, e, o, delta, AggAxisResult.CODE_OK);
        }

        if (absDelta.compareTo(epsBlock) > 0) {
            return new AggAxisResult(AggAxisKind.BLOCK, t, w, e, o, delta, AggAxisResult.CODE_BLOCK);
        }

        if (absDelta.compareTo(epsQ) <= 0) {
            // Q: Ttl авторитет, δ → Oth (создаём Oth=0 если null)
            BigDecimal oBase = o == null ? BigDecimal.ZERO.setScale(scale) : o;
            BigDecimal oFixed = oBase.add(delta).setScale(scale, java.math.RoundingMode.HALF_UP);
            return new AggAxisResult(AggAxisKind.QUANTUM_FIX, t, w, e, oFixed, delta,
                    AggAxisResult.CODE_QUANTUM);
        }

        // A: части → Ttl
        BigDecimal tFixed = parts.setScale(scale, java.math.RoundingMode.HALF_UP);
        return new AggAxisResult(AggAxisKind.AUTHOR_FIX, tFixed, w, e, o, delta,
                AggAxisResult.CODE_AUTHOR);
    }

    private static BigDecimal sumParts(BigDecimal w, BigDecimal e, BigDecimal o) {
        return FemsqMoney.nz(w).add(FemsqMoney.nz(e)).add(FemsqMoney.nz(o));
    }

    private static boolean isNonZero(BigDecimal v) {
        return v != null && v.compareTo(BigDecimal.ZERO) != 0;
    }
}
