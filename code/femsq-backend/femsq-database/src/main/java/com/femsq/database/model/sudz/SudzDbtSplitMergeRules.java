package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Objects;

/**
 * Инварианты Split/Merge (S77.3), без JDBC: сумма долей, число частей, допуск как Consistency.
 */
public final class SudzDbtSplitMergeRules {

    /** Допуск сумм (как {@code trg_DbtValue_Consistency} п.4). */
    public static final BigDecimal EPS = new BigDecimal("0.01");

    private SudzDbtSplitMergeRules() {
    }

    /**
     * Проверяет, что частей не меньше двух и каждая доля {@code ttl} &gt; 0.
     *
     * @param parts доли Split
     */
    public static void requireSplitParts(List<SudzDbtSplitPart> parts) {
        if (parts == null || parts.size() < 2) {
            throw new IllegalArgumentException("Split: нужно не меньше двух долей");
        }
        for (int i = 0; i < parts.size(); i++) {
            SudzDbtSplitPart part = Objects.requireNonNull(parts.get(i), "parts[" + i + "]");
            if (part.ttl() == null || part.ttl().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("Split: доля[" + i + "] ttl должна быть > 0");
            }
        }
    }

    /**
     * Сумма {@code ttl} долей должна совпасть с каноном на срезе (± EPS).
     *
     * @param expected канон (Value исходного слота или последняя история)
     * @param parts доли
     */
    public static void requireSplitSum(BigDecimal expected, List<SudzDbtSplitPart> parts) {
        if (expected == null) {
            throw new IllegalArgumentException("Split: нет эталонной суммы канона");
        }
        BigDecimal sum = BigDecimal.ZERO;
        for (SudzDbtSplitPart part : parts) {
            sum = sum.add(part.ttl());
        }
        if (!moneyEquals(expected, sum)) {
            throw new IllegalArgumentException(
                    "Сумма долей " + sum.toPlainString()
                            + " ≠ канон " + expected.toPlainString()
                            + " — нужен Split с сохранением суммы, не Link доли на целый слот");
        }
    }

    /**
     * Просрочка доли: явная или пропорционально {@code ttl}.
     *
     * @param partTtl ttl доли
     * @param sourceTtl ttl канона
     * @param sourceOverd просрочка канона (может быть null)
     * @param partOverd явная просрочка доли
     * @return overd доли
     */
    public static BigDecimal splitOverd(
            BigDecimal partTtl,
            BigDecimal sourceTtl,
            BigDecimal sourceOverd,
            BigDecimal partOverd
    ) {
        if (partOverd != null) {
            return partOverd;
        }
        if (sourceOverd == null || sourceTtl == null || sourceTtl.compareTo(BigDecimal.ZERO) == 0) {
            return partTtl;
        }
        return sourceOverd.multiply(partTtl).divide(sourceTtl, 4, RoundingMode.HALF_UP);
    }

    /**
     * Сравнение денег с допуском EPS.
     *
     * @param left левое
     * @param right правое
     * @return true, если |left−right| ≤ 0.01
     */
    public static boolean moneyEquals(BigDecimal left, BigDecimal right) {
        if (left == null || right == null) {
            return false;
        }
        return left.subtract(right).abs().compareTo(EPS) <= 0;
    }
}
