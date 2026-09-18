package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import com.femsq.database.model.sudz.SudzPmtUplLogOnlyResult;
import java.util.List;
import java.util.Objects;

/**
 * Сжатый HTML-лог log-only шагов H2: сводка N + первые K образцов.
 */
public final class SudzPmtUplCompressedLog {

    private SudzPmtUplCompressedLog() {
    }

    /**
     * Пишет итог шага в {@code progress}.
     *
     * @param progress лог воронки
     * @param emptyMessage текст при N=0
     * @param foundPrefix префикс при N&gt;0 (до числа)
     * @param result счётчик и образцы
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            String emptyMessage,
            String foundPrefix,
            SudzPmtUplLogOnlyResult result
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(result, "result");
        if (result.total() == 0) {
            progress.line(emptyMessage == null
                    ? "<font color=\"Olive\"><b>нет попаданий</b></font>."
                    : emptyMessage);
            return;
        }
        String prefix = foundPrefix == null ? "Найдено" : foundPrefix;
        progress.line(prefix + " <font color=\"DarkCyan\"><b>" + result.total() + "</b></font>"
                + " (в логе первые "
                + Math.min(result.samples().size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT)
                + " из " + result.total() + ").");
        List<String> samples = result.samples();
        int shown = Math.min(samples.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT);
        for (int i = 0; i < shown; i++) {
            progress.line("<font color=\"silver\">" + (i + 1) + ".</font> "
                    + SudzDbtUplProgressLog.escape(samples.get(i)));
        }
        if (result.total() > shown) {
            progress.line("<font color=\"gray\">… ещё "
                    + (result.total() - shown) + " (не в логе)</font>.");
        }
    }
}
