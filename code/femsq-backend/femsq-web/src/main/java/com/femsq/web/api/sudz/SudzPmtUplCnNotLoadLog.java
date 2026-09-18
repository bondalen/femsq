package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadInserted;
import com.femsq.database.model.sudz.SudzPmtUplCnNotLoad;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * HTML-лог шага 3 платежей {@code cipuCn_CtptCnNotLoad} (зеркало Access SqlCipuCn_CtptCnNot).
 */
public final class SudzPmtUplCnNotLoadLog {

    private SudzPmtUplCnNotLoadLog() {
    }

    /**
     * Пишет сводку и строки в лог воронки.
     *
     * @param progress лог
     * @param rows результат find
     * @param applyResult итог INSERT или {@code null} при только просмотре
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<SudzPmtUplCnNotLoad> rows,
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
            progress.line("<font color=\"Olive\"><b>новые договоры (исполнитель+№) отсутствуют</b></font>.");
            return;
        }
        long creatable = rows.stream()
                .filter(r -> r.countCn() == 0
                        && r.orgIdKey() != null && r.orgIdKey() > 0
                        && r.cnName() != null && !r.cnName().isBlank()
                        && !"NullИлиПусто".equals(r.cnName()))
                .count();
        progress.line("Пар без исполнителя в БД: <font color=\"DarkCyan\"><b>"
                + rows.size() + "</b></font>"
                + " · к созданию при flLoad (countCn=0 + org_id): <b>" + creatable + "</b>.");
        Map<Integer, SudzDbtUplCnNotLoadInserted> inserted =
                applyResult == null ? Map.of() : applyResult.insertedByRowIndex();
        int index = 1;
        for (SudzPmtUplCnNotLoad row : rows) {
            progress.line(formatRow(index, row, inserted.get(index)));
            index++;
        }
    }

    /**
     * Одна строка лога.
     *
     * @param index номер с 1
     * @param row договор
     * @param inserted ключи INSERT или null
     * @return HTML
     */
    static String formatRow(
            int index,
            SudzPmtUplCnNotLoad row,
            SudzDbtUplCnNotLoadInserted inserted
    ) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">")
                .append(index)
                .append(".</font> БУиРГ <font color=\"DarkCyan\">")
                .append(row.buirg() == null ? "—" : row.buirg())
                .append("</font> · ")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.name())))
                .append(" · № <font color=\"CadetBlue\"><b>")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName())))
                .append("</b></font> · org_id=")
                .append(row.orgIdKey() == null ? "—" : row.orgIdKey())
                .append(" · countCn=<font color=\"")
                .append(row.countCn() == 0 ? "DarkGreen" : "Salmon")
                .append("\">")
                .append(row.countCn())
                .append("</font>");
        if (row.countCn() > 0) {
            html.append(" — <font color=\"DarkGoldenrod\">похожий № уже в БД, без авто-создания</font>");
        } else if (row.orgIdKey() == null || row.orgIdKey() <= 0) {
            html.append(" — <font color=\"Salmon\">нет org_id, без INSERT</font>");
        } else if (inserted != null) {
            html.append(" — <font color=\"DarkGreen\">Добавлено</font> cn=")
                    .append(inserted.cnKey())
                    .append(" cnn=").append(inserted.cnnKey())
                    .append(" cn_s=").append(inserted.cnSKey());
        }
        html.append(".");
        return html.toString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
