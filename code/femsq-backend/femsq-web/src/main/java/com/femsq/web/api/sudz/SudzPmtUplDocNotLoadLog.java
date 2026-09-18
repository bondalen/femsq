package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplDocNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага 10 платежей {@code cipuDocNotLoad}.
 */
public final class SudzPmtUplDocNotLoadLog {

    private SudzPmtUplDocNotLoadLog() {
    }

    /**
     * Пишет сводку N и образцы кодов; при apply — число INSERT.
     *
     * @param progress лог
     * @param codes коды find
     * @param applyResult итог или {@code null}
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<String> codes,
            SudzPmtUplDocNotApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(codes, "codes");
        if (applyResult != null) {
            progress.line("Внесено документов (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>.");
        }
        if (codes.isEmpty()) {
            progress.line("В источнике <font color=\"Olive\">отсутствуют документы "
                    + "<b>отсутствующие</b> в БД</font>.");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются документы</font>, "
                + " <font color=\"Salmon\"><b>отсутствующие в БД</b></font>. В количестве <b>"
                + codes.size() + "</b> (в логе первые "
                + Math.min(codes.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT) + ").");
        int shown = Math.min(codes.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT);
        for (int i = 0; i < shown; i++) {
            progress.line("<font color=\"silver\">Документ: <font color=\"DarkSlateBlue\">"
                    + (i + 1)
                    + "</font>. код: <font color=\"DarkCyan\"><b>"
                    + SudzDbtUplProgressLog.escape(codes.get(i))
                    + "</b></font></font>.");
        }
        if (codes.size() > shown) {
            progress.line("<font color=\"gray\">… ещё " + (codes.size() - shown) + " (не в логе)</font>.");
        }
    }
}
