package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code CnExistCtptNotLoad}
 * (зеркало Access {@code Form_CnInvDbtUpl_gt_File_f} ≈601–660). Только показ; apply нет.
 */
public final class SudzDbtUplCnExistCtptNotLoadLog {

    private static final LocalDate ACCESS_NULL_DATE = LocalDate.of(1900, 1, 1);

    private SudzDbtUplCnExistCtptNotLoadLog() {
    }

    /**
     * Пишет заголовок и строки «Новый: N. …» в лог воронки.
     *
     * @param progress лог
     * @param rows результат {@code ciduCnExistCtptNot}
     */
    public static void append(SudzDbtUplProgressLog progress, List<SudzDbtUplCnExistCtptNotLoad> rows) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (rows.isEmpty()) {
            progress.line("В источнике отсутствуют договора"
                    + " <font color=\"Goldenrod\">исполнитель по которым не соответствует</font>"
                    + " имеющимся в БД.");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются договора</font>,"
                + " исполнитель по которым <font color=\"Goldenrod\">не соответствует</font>"
                + " имеющимся в БД.");
        int index = 1;
        for (SudzDbtUplCnExistCtptNotLoad row : rows) {
            progress.line(formatRow(index, row));
            index++;
        }
    }

    /**
     * Одна строка лога Access (без OrgId / apply).
     *
     * @param index номер с 1
     * @param row договор
     * @return HTML
     */
    static String formatRow(int index, SudzDbtUplCnExistCtptNotLoad row) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Новый: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.name())))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(row.buirg() == null ? "" : row.buirg())
                .append("</font>. ИНН: <font color=\"DarkSlateBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.itn())))
                .append("</font>. № договора: <font color=\"CadetBlue\"><b>")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName())))
                .append("</b></font>");
        if (isMissingCnDate(row.cnDate())) {
            html.append(" , <font color=\"DarkGoldenrod\">дата отсутствует</font>");
        } else {
            html.append(" от <font color=\"DarkSlateBlue\">")
                    .append(formatAccessDate(row.cnDate()))
                    .append("</font>");
        }
        html.append("</font>.");
        return html.toString();
    }

    private static boolean isMissingCnDate(LocalDate cnDate) {
        return cnDate == null || ACCESS_NULL_DATE.equals(cnDate);
    }

    private static String formatAccessDate(LocalDate date) {
        return String.format("%02d.%02d.%04d", date.getDayOfMonth(), date.getMonthValue(), date.getYear());
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
