package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplOrgNotInBuirg;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code orgNotInBuirg} (зеркало Access {@code Form_CnInvDbtUpl_gt_File_f} ≈173–201).
 * Домен не изменяется; {@code cidufFlLoad} не используется.
 */
public final class SudzDbtUplOrgNotInBuirgLog {

    private SudzDbtUplOrgNotInBuirgLog() {
    }

    /**
     * Пишет заголовок и строки «Новая: N. …» в хронологическом логе FEMSQ
     * (в Access строки prepend-ились в начало поля).
     *
     * @param progress лог воронки
     * @param rows результат LEFT JOIN без type=1
     */
    public static void append(SudzDbtUplProgressLog progress, List<SudzDbtUplOrgNotInBuirg> rows) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (rows.isEmpty()) {
            progress.line("В источнике <font color=\"Olive\"><b>новые организации отсутствуют</b></font>.");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются новые организации</font>,"
                + " не обнаруженные по коду БУиРГ.");
        int index = 1;
        for (SudzDbtUplOrgNotInBuirg row : rows) {
            progress.line(formatRow(index, row));
            index++;
        }
    }

    /**
     * Одна строка лога Access (без обёртки {@code p}).
     *
     * @param index номер с 1
     * @param row организация
     * @return HTML
     */
    static String formatRow(int index, SudzDbtUplOrgNotInBuirg row) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Новая: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(row.name()))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(row.buirg() == null ? "" : row.buirg())
                .append("</font>. ИНН: <font color=\"DarkSlateBlue\">")
                .append(SudzDbtUplProgressLog.escape(row.itn()))
                .append("</font>");
        String existing = row.existingOgNm();
        if (existing != null && !existing.isBlank()) {
            html.append(". <font color=\"Salmon\">Уже имеется</font> организация: <font color=\"Maroon\"><b>")
                    .append(SudzDbtUplProgressLog.escape(existing))
                    .append("</b></font></font>.");
        } else {
            html.append("</font>.");
        }
        return html.toString();
    }
}
