package com.femsq.database.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Квант денежных сумм FEMSQ (ADR 012 / R-MONEY-AGG).
 *
 * <ul>
 *   <li>млн ₽ ({@code decimal(23,8)}): scale 8 → 1e−8 млн = 1 коп</li>
 *   <li>₽ ({@code money}): scale 4</li>
 * </ul>
 */
public final class FemsqMoney {

    /** Scale для полей в млн ₽ (ipgpSm*, ipgPnLim, UtPl). */
    public static final int SCALE_MLN = 8;

    /** Scale для полей в ₽ (ra_summ / factDocCost money). */
    public static final int SCALE_RUB = 4;

    /** ε_q в млн ₽: один ulp кванта (= 1 коп после ×1e6). */
    public static final BigDecimal EPS_Q_MLN = new BigDecimal("0.00000001");

    /** Нижняя граница ε_block в млн ₽ (= 1 млн ₽ в деньгах отчёта после ×1e6… фактически 1 единица млн). */
    public static final BigDecimal EPS_BLOCK_FLOOR_MLN = BigDecimal.ONE;

    private static final BigDecimal PCT_BLOCK = new BigDecimal("0.01");

    private FemsqMoney() {
    }

    /**
     * Округляет сумму в млн ₽ до scale 8 (HALF_UP). {@code null} → {@code null}.
     */
    public static BigDecimal roundMln(BigDecimal value) {
        if (value == null) {
            return null;
        }
        return value.setScale(SCALE_MLN, RoundingMode.HALF_UP);
    }

    /**
     * Округляет сумму в ₽ до scale 4 (HALF_UP). {@code null} → {@code null}.
     */
    public static BigDecimal roundRub(BigDecimal value) {
        if (value == null) {
            return null;
        }
        return value.setScale(SCALE_RUB, RoundingMode.HALF_UP);
    }

    /**
     * ε_block (млн) = max(1, 1% · max(|ttl|, |parts|)).
     */
    public static BigDecimal epsBlockMln(BigDecimal ttl, BigDecimal partsSum) {
        BigDecimal ref = abs(nz(ttl)).max(abs(nz(partsSum)));
        BigDecimal pct = ref.multiply(PCT_BLOCK).setScale(SCALE_MLN, RoundingMode.HALF_UP);
        return EPS_BLOCK_FLOOR_MLN.max(pct);
    }

    /**
     * ε_block (₽) = max(1.00, 1% · max(|total|, |parts|)).
     */
    public static BigDecimal epsBlockRub(BigDecimal total, BigDecimal partsSum) {
        BigDecimal floor = new BigDecimal("1.00");
        BigDecimal ref = abs(nz(total)).max(abs(nz(partsSum)));
        BigDecimal pct = ref.multiply(PCT_BLOCK).setScale(SCALE_RUB, RoundingMode.HALF_UP);
        return floor.max(pct);
    }

    static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }

    static BigDecimal abs(BigDecimal v) {
        return v.abs();
    }
}
