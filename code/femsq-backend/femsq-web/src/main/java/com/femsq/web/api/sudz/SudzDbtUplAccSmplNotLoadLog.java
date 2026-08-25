package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotRow;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code CnCtptInvExistAccSmplNotLoad}
 * (зеркало Access {@code CnCtptInvExistAccSmplNot}).
 */
public final class SudzDbtUplAccSmplNotLoadLog {

    private SudzDbtUplAccSmplNotLoadLog() {
    }

    /**
     * Пишет заголовок и строки diff.
     * Хронология сверху вниз (как остальные шаги FEMSQ; VBA prepend давал обратный порядок).
     *
     * @param progress лог
     * @param rows diff
     */
    public static void append(SudzDbtUplProgressLog progress, List<SudzDbtUplAccSmplNotRow> rows) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (rows.isEmpty()) {
            progress.line("В источнике <font color=\"Goldenrod\">отсутствуют счета-фактуры с "
                    + "отсутствующими в БД *Задолженностями простыми*</font>.");
        } else {
            progress.line("В источнике <font color=\"CadetBlue\">имеются счета-фактуры</font>, "
                    + " для которых в БД <font color=\"Goldenrod\">отсутствуют *Задолженности простые*"
                    + "</font>. Для задолженностей в количестве " + rows.size() + ".");
            for (int i = 0; i < rows.size(); i++) {
                progress.line(formatRow(i + 1, rows.get(i)));
            }
        }
    }

    /**
     * Одна строка лога Access.
     *
     * @param index номер с 1
     * @param row diff
     * @return HTML
     */
    static String formatRow(int index, SudzDbtUplAccSmplNotRow row) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Договор: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cntrPrtName())))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(row.cntrPrtNum() == null ? "" : row.cntrPrtNum())
                .append("</font>. № договора: <font color=\"CadetBlue\"><b>")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName())))
                .append("</b></font>");
        if (row.cnDate() == null) {
            html.append(" , <font color=\"DarkGoldenrod\">дата отсутствует</font>");
        } else {
            html.append(" от <font color=\"DarkSlateBlue\">")
                    .append(row.cnDate())
                    .append("</font>");
        }
        html.append(". CnId: <font color=\"DarkViolet\">")
                .append(row.cnKey())
                .append("</font>. Счета-фактура: <font color=\"DarkSlateBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cnInv())))
                .append("</font>. iKey: <font color=\"DarkViolet\">")
                .append(row.iKey())
                .append("</font>. ciKey: <font color=\"DarkViolet\">")
                .append(row.ciKey())
                .append("</font>. Счета главной книги: <font color=\"DarkGoldenrod\"><b>")
                .append(row.accountNum())
                .append("</b></font>. AccountKey: <font color=\"DarkViolet\">")
                .append(row.accountKey())
                .append("</font></font>.");
        return html.toString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
