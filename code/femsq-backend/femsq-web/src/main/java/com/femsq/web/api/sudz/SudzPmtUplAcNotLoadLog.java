package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplAcNotLoad;
import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага 9 платежей {@code cipuCn_CtptCnOneInvOneAcNotLoad}.
 */
public final class SudzPmtUplAcNotLoadLog {

    private SudzPmtUplAcNotLoadLog() {
    }

    /**
     * Пишет сводку и строки diff; при apply — число INSERT.
     *
     * @param progress лог
     * @param rows результат find
     * @param applyResult итог INSERT или {@code null}
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<SudzPmtUplAcNotLoad> rows,
            SudzDbtUplAccSmplNotApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (applyResult != null) {
            progress.line("Внесено пар СФ+СГК (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>.");
        }
        if (rows.isEmpty()) {
            progress.line("В источнике <font color=\"Olive\">отсутствуют счета-фактуры с "
                    + "<b>отсутствующими</b> в БД парами *счёт-фактура + счёт главной книги*</font>.");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются счета-фактуры</font>, "
                + " для которых в БД <font color=\"Goldenrod\">отсутствуют пары "
                + "*счёт-фактура + счёт главной книги*</font>. Для задолженностей в количестве "
                + rows.size() + " (в логе первые "
                + Math.min(rows.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT) + ").");
        int shown = Math.min(rows.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT);
        for (int i = 0; i < shown; i++) {
            progress.line(formatRow(i + 1, rows.get(i)));
        }
        if (rows.size() > shown) {
            progress.line("<font color=\"gray\">… ещё " + (rows.size() - shown) + " (не в логе)</font>.");
        }
    }

    /**
     * Одна строка лога Access.
     *
     * @param index номер с 1
     * @param row diff
     * @return HTML
     */
    static String formatRow(int index, SudzPmtUplAcNotLoad row) {
        Objects.requireNonNull(row, "row");
        return "<font color=\"silver\">Договор: <font color=\"DarkSlateBlue\">"
                + index
                + "</font>. <font color=\"CadetBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.name()))
                + "</font>. БУиРГ: <font color=\"DarkCyan\">"
                + (row.buirg() == null ? "—" : row.buirg())
                + "</font>. № договора: <font color=\"CadetBlue\"><b>"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName()))
                + "</b></font>. CnId: <font color=\"DarkViolet\">"
                + row.cnKey()
                + "</font>. Счета-фактура: <font color=\"DarkSlateBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnInv()))
                + "</font>. ciKey: <font color=\"DarkViolet\">"
                + row.ciKey()
                + "</font>. Счета главной книги: <font color=\"DarkGoldenrod\"><b>"
                + row.accountNum()
                + "</b></font>. AccountKey: <font color=\"DarkViolet\">"
                + row.accountKey()
                + "</font></font>.";
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
