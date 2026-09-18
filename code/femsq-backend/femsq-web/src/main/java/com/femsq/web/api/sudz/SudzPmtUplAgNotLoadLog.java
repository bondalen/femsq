package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplAgNotLoad;
import com.femsq.database.model.sudz.SudzPmtUplAgNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplAgNotLoadInserted;
import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * HTML-лог шага 5 платежей {@code cipuCn_AgNotLoad}.
 */
public final class SudzPmtUplAgNotLoadLog {

    private SudzPmtUplAgNotLoadLog() {
    }

    /**
     * Пишет сводку и образцы в лог воронки.
     *
     * @param progress лог
     * @param rows результат find
     * @param applyResult итог INSERT или {@code null}
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<SudzPmtUplAgNotLoad> rows,
            SudzPmtUplAgNotLoadApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(rows, "rows");
        if (applyResult != null) {
            progress.line("Вставлено агентов (smpl type=1): <b>" + applyResult.insertedCount() + "</b>"
                    + " · note=<font color=\"gray\">"
                    + SudzDbtUplProgressLog.escape(applyResult.note()) + "</font>.");
        }
        if (rows.isEmpty()) {
            progress.line("<font color=\"Olive\"><b>договоры без агента (заказчика) отсутствуют</b></font>.");
            return;
        }
        long creatable = rows.stream()
                .filter(r -> r.orgIdKey() != null && r.orgIdKey() > 0)
                .count();
        progress.line("В источнике <font color=\"CadetBlue\">имеются договора</font>,"
                + " для которых в БД <font color=\"Goldenrod\">отсутствуют агенты</font>."
                + " Всего: <font color=\"DarkCyan\"><b>" + rows.size() + "</b></font>"
                + " · к созданию при flLoad: <b>" + creatable + "</b>"
                + " (в логе первые "
                + Math.min(rows.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT)
                + ").");
        Map<Integer, SudzPmtUplAgNotLoadInserted> inserted =
                applyResult == null ? Map.of() : applyResult.insertedByRowIndex();
        int shown = Math.min(rows.size(), SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT);
        for (int i = 0; i < shown; i++) {
            int index = i + 1;
            progress.line(formatRow(index, rows.get(i), inserted.get(index)));
        }
        if (rows.size() > shown) {
            progress.line("<font color=\"gray\">… ещё "
                    + (rows.size() - shown) + " (не в логе)</font>.");
        }
    }

    /**
     * Одна строка лога.
     *
     * @param index номер с 1
     * @param row агент
     * @param inserted ключи INSERT или null
     * @return HTML
     */
    static String formatRow(
            int index,
            SudzPmtUplAgNotLoad row,
            SudzPmtUplAgNotLoadInserted inserted
    ) {
        Objects.requireNonNull(row, "row");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Договор: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.agentName())))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(row.agentNum() == null ? "—" : row.agentNum())
                .append("</font>. № договора: <font color=\"CadetBlue\"><b>")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName())))
                .append("</b></font>. cn_key: <font color=\"DarkViolet\">")
                .append(row.cnKey())
                .append("</font>");
        if (row.cnSKey() == null) {
            html.append(". cn_s_key: <font color=\"Salmon\">пусто</font>");
        } else {
            html.append(". cn_s_key: <font color=\"DarkViolet\">").append(row.cnSKey()).append("</font>");
        }
        if (row.orgIdKey() == null || row.orgIdKey() <= 0) {
            html.append(" — <font color=\"Salmon\">нет org_id агента, без INSERT</font>");
        } else if (inserted != null) {
            if (inserted.createdCnS()) {
                html.append(". Создана: cn_s_key: <font color=\"Teal\">")
                        .append(inserted.cnSKey()).append("</font>");
            }
            html.append(". Добавлено: csos=")
                    .append(inserted.csosKey())
                    .append(" cn_s_org=")
                    .append(inserted.cnSOrgKey());
        }
        html.append(".</font>");
        return html.toString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
