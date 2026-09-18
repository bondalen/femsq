package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат log-only шага воронки платежей (H2): полный счётчик + сжатая выборка строк.
 *
 * @param total полное число попаданий
 * @param samples первые K подписей для лога (без построчного дампа)
 */
public record SudzPmtUplLogOnlyResult(int total, List<String> samples) {

    /**
     * @param total счётчик
     * @param samples выборка
     */
    public SudzPmtUplLogOnlyResult {
        if (total < 0) {
            throw new IllegalArgumentException("total не может быть отрицательным: " + total);
        }
        samples = samples == null ? List.of() : List.copyOf(samples);
    }

    /** Пустой результат. */
    public static SudzPmtUplLogOnlyResult empty() {
        return new SudzPmtUplLogOnlyResult(0, List.of());
    }
}
