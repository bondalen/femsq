package com.femsq.web.audit;

/**
 * Счётчики и тайминги сохранения HTML-лога ревизии в {@code adt_results} (задача 0046).
 */
public final class AuditLogPersistStats {

    private int flushCount;
    private int skippedUnchanged;
    private int skippedThrottled;
    private long buildHtmlTotalMs;
    private long dbUpdateTotalMs;
    private int lastHtmlChars;

    /**
     * @return число фактических записей в БД через {@code saveProgress}
     */
    public int getFlushCount() {
        return flushCount;
    }

    public int getSkippedUnchanged() {
        return skippedUnchanged;
    }

    public int getSkippedThrottled() {
        return skippedThrottled;
    }

    public long getBuildHtmlTotalMs() {
        return buildHtmlTotalMs;
    }

    public long getDbUpdateTotalMs() {
        return dbUpdateTotalMs;
    }

    public int getLastHtmlChars() {
        return lastHtmlChars;
    }

    public void recordSkippedUnchanged() {
        skippedUnchanged++;
    }

    public void recordSkippedThrottled() {
        skippedThrottled++;
    }

    /**
     * @param buildMs время {@link AuditExecutionContext#buildHtmlLog()}
     * @param updateMs время {@code raAService.update}
     * @param htmlChars длина HTML-блоба
     */
    public void recordFlush(long buildMs, long updateMs, int htmlChars) {
        flushCount++;
        buildHtmlTotalMs += buildMs;
        dbUpdateTotalMs += updateMs;
        lastHtmlChars = htmlChars;
    }
}
