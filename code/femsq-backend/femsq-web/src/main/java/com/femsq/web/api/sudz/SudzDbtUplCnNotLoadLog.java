package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadInserted;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * HTML-лог шага {@code CnNotLoad} (зеркало Access {@code Form_CnInvDbtUpl_gt_File_f} ≈685–813).
 * При apply — суффиксы «Добавлено / CnId / …»; откат по {@code cnMark}.
 */
public final class SudzDbtUplCnNotLoadLog {

    private static final LocalDate ACCESS_NULL_DATE = LocalDate.of(1900, 1, 1);

    private SudzDbtUplCnNotLoadLog() {
    }

    /**
     * Пишет заголовок и строки «Новый: N. …» в лог воронки.
     *
     * @param progress лог
     * @param rows результат {@code ciduCnNotLoad}
     * @param applyResult итог INSERT или {@code null}, если только просмотр
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<SudzDbtUplCnNotLoad> rows,
            SudzDbtUplCnNotLoadApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (applyResult != null) {
            progress.line("cnMark=<font color=\"DarkViolet\"><b>" + applyResult.cnMark() + "</b></font>"
                    + " — откат: mutation <code>rollbackSudzCnNotLoad(cnMark: "
                    + applyResult.cnMark() + ")</code>. "
                    + "Вставлено договоров: <b>" + applyResult.insertedCount() + "</b>.");
        }
        if (rows.isEmpty()) {
            progress.line("В источнике <font color=\"Goldenrod\">новые договора отсутствуют</font>"
                    + " (не обнаруженные по номеру, дате и исполнителю)");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются новые договора</font>,"
                + " не обнаруженные по номеру, дате и исполнителю");
        Map<Integer, SudzDbtUplCnNotLoadInserted> inserted =
                applyResult == null ? Map.of() : applyResult.insertedByRowIndex();
        int index = 1;
        for (SudzDbtUplCnNotLoad row : rows) {
            progress.line(formatRow(index, row, inserted.get(index)));
            index++;
        }
    }

    /**
     * Одна строка лога Access (без обёртки {@code p}).
     *
     * @param index номер с 1
     * @param row договор
     * @param inserted ключи INSERT или null
     * @return HTML
     */
    static String formatRow(
            int index,
            SudzDbtUplCnNotLoad row,
            SudzDbtUplCnNotLoadInserted inserted
    ) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Новый: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.name())))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(row.buirg() == null ? "" : row.buirg())
                .append("</font>. OrgId: <font color=\"DarkViolet\">")
                .append(row.orgIdKey() == null ? "" : row.orgIdKey())
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
        if (row.countCnName() > 1) {
            html.append(" Среди новых договоров имеются повторы этого № в количестве: "
                    + "<font color=\"Salmon\">")
                    .append(row.countCnName())
                    .append("</font>");
        } else {
            html.append(". Повторы № среди новых <font color=\"DarkGreen\">отсутствуют</font>");
            if (inserted != null) {
                html.append(". <font color=\"DarkGreen\">Добавлено</font>. CnId: <font color=\"CadetBlue\">")
                        .append(inserted.cnKey())
                        .append("</font>. <font color=\"DarkGreen\">Доб. №</font>. cnnCn: <font color=\"CadetBlue\">")
                        .append(inserted.cnnKey())
                        .append("</font>. CnS_Id: <font color=\"Teal\">")
                        .append(inserted.cnSKey())
                        .append("</font>. CnS_OrgIdSmpl: <font color=\"Teal\">")
                        .append(inserted.csosKey())
                        .append("</font>. CnS_OrgId: <font color=\"Teal\">")
                        .append(inserted.cnSOrgKey())
                        .append("</font>");
            }
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
