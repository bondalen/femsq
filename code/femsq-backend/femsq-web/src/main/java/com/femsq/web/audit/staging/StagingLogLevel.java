package com.femsq.web.audit.staging;

import java.util.Locale;

/**
 * Уровень детализации лога Stage 1 (Excel → staging) в {@code adt_results}.
 *
 * <p>{@link #SUMMARY} — режим по умолчанию: batch INSERT и прогресс раз в 100 строк.</p>
 */
public enum StagingLogLevel {

    /** Построчный HTML-лог и одиночный INSERT (сравнение с VBA). */
    VERBOSE,

    /** Batch INSERT, прогресс раз в 100 строк, лог только ошибочных строк. */
    SUMMARY,

    /** Batch INSERT, только итоговая статистика листа. */
    MINIMAL;

    private static final int SUMMARY_PROGRESS_INTERVAL = 100;

    /**
     * @return {@code true}, если каждая строка вставляется отдельным {@code executeUpdate}
     *         с {@code RETURN_GENERATED_KEYS}
     */
    public boolean logEachStagingRow() {
        return this == VERBOSE;
    }

    /**
     * @return {@code true}, если в {@code adt_results} пишется построчный HTML (VBA-стиль)
     */
    public boolean emitRowParagraphPreview() {
        return this == VERBOSE;
    }

    /**
     * @return {@code true}, если в {@code adt_results} пишется прогресс и ошибочные строки
     */
    public boolean emitSummaryProgress() {
        return this == SUMMARY;
    }

    /**
     * @return интервал (в исходных строках Excel) для heartbeat в режиме {@link #SUMMARY}
     */
    public int summaryProgressInterval() {
        return SUMMARY_PROGRESS_INTERVAL;
    }

    /**
     * @return {@code true}, если в {@code adt_results} пишется построчный аудит apply reconcile (VBA-стиль)
     */
    public boolean emitReconcileRowAudit() {
        return this == VERBOSE;
    }

    /**
     * Разрешает уровень из значения БД и дефолта приложения.
     *
     * @param dbValue             значение {@code adt_staging_log_level} (может быть {@code null})
     * @param applicationDefault  дефолт из {@code audit.staging.default-log-level}
     * @return уровень для выполнения Stage 1
     */
    public static StagingLogLevel resolve(String dbValue, StagingLogLevel applicationDefault) {
        StagingLogLevel fallback = applicationDefault != null ? applicationDefault : SUMMARY;
        if (dbValue == null || dbValue.isBlank()) {
            return fallback;
        }
        try {
            return valueOf(dbValue.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            return fallback;
        }
    }
}
