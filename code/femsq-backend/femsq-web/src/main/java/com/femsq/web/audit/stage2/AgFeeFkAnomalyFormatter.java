package com.femsq.web.audit.stage2;

import java.util.List;
import java.util.Objects;

/**
 * HTML-форматирование diagnostic Stage 2a для type=6 (AgentNo / CstNo).
 *
 * <p>Заголовки и тела разделены, чтобы процессор мог обернуть блоки в свёртываемые spans.
 */
public final class AgFeeFkAnomalyFormatter {

    private static final int SUMMARY_CST_LIMIT = 40;
    private static final int EXCEL_ROWS_SHOWN = 12;

    private AgFeeFkAnomalyFormatter() {
    }

    /**
     * Заголовок блока отправителей (для span START).
     */
    public static String formatAgentTitleHtml(List<AgFeeAgentAnomaly> anomalies) {
        Objects.requireNonNull(anomalies, "anomalies");
        if (anomalies.isEmpty()) {
            return "<P>Все отправители идентифицированы.</P>";
        }
        return "<P>Отсутствуют или неоднозначны отправители: <b><font color=\"Crimson\">"
                + anomalies.size() + "</font></b></P>";
    }

    /**
     * Тело блока отправителей (внутри span); {@code null}, если аномалий нет.
     */
    public static String formatAgentBodyHtml(List<AgFeeAgentAnomaly> anomalies) {
        Objects.requireNonNull(anomalies, "anomalies");
        if (anomalies.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder("<P>");
        boolean first = true;
        for (AgFeeAgentAnomaly a : anomalies) {
            if (!first) {
                sb.append(' ');
            }
            first = false;
            String name = a.senderName() == null || a.senderName().isBlank()
                    ? "(пусто)"
                    : a.senderName().trim();
            String hint = a.keyCount() == 0 ? "не найден" : ("ключей=" + a.keyCount());
            sb.append("<font color=\"Crimson\">")
                    .append(escape(name))
                    .append("</font> (")
                    .append(hint)
                    .append(");");
        }
        sb.append("</P>");
        return sb.toString();
    }

    /**
     * Сводка по неоднозначным / отсутствующим агентам (совместимость / тесты).
     *
     * @param anomalies список аномалий агента
     * @return HTML или null, если аномалий нет
     */
    public static String formatAgentAnomaliesHtml(List<AgFeeAgentAnomaly> anomalies) {
        String body = formatAgentBodyHtml(anomalies);
        if (body == null) {
            return null;
        }
        String title = formatAgentTitleHtml(anomalies);
        // title ends with </P>; body is <P>...</P> — склеиваем в один блок
        return title.substring(0, title.length() - 4) + " " + body.substring(3);
    }

    /**
     * Заголовок блока строек (для span START).
     */
    public static String formatCstTitleHtml(List<AgFeeCstAnomaly> anomalies) {
        Objects.requireNonNull(anomalies, "anomalies");
        if (anomalies.isEmpty()) {
            return "<P>В источнике отсутствуют стройки, отсутствующие в БД.</P>";
        }
        return "<P>В источнике имеются стройки, отсутствующие в БД: <b><font color=\"Crimson\">"
                + anomalies.size() + "</font></b></P>";
    }

    /**
     * Тело блока строек (внутри span); {@code null}, если аномалий нет.
     */
    public static String formatCstBodyHtml(List<AgFeeCstAnomaly> anomalies) {
        Objects.requireNonNull(anomalies, "anomalies");
        if (anomalies.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        int shown = 0;
        for (AgFeeCstAnomaly a : anomalies) {
            if (shown >= SUMMARY_CST_LIMIT) {
                sb.append("<P>… и ещё ").append(anomalies.size() - SUMMARY_CST_LIMIT).append(" строек.</P>");
                break;
            }
            shown++;
            sb.append("<P><b>").append(shown).append("</b>. стройка <b><font color=\"Red\">«")
                    .append(escape(nullToEmpty(a.cstCode())))
                    .append("»</font></b> — ")
                    .append(formatExcelRows(a.excelRows(), a.rowCount()))
                    .append(";</P>");
        }
        return sb.toString();
    }

    /**
     * Сводка по стройкам (совместимость / тесты).
     *
     * @param anomalies список аномалий стройки
     * @return HTML-абзац или null, если аномалий нет
     */
    public static String formatCstAnomaliesHtml(List<AgFeeCstAnomaly> anomalies) {
        String body = formatCstBodyHtml(anomalies);
        if (body == null) {
            return null;
        }
        return formatCstTitleHtml(anomalies) + body;
    }

    /**
     * Форматирует список Excel-строк (с усечением и числом упоминаний).
     */
    static String formatExcelRows(List<Integer> rows, int rowCount) {
        if (rows == null || rows.isEmpty()) {
            return rowCount > 0
                    ? ("упоминаний в файле: " + rowCount + " (номера строк недоступны)")
                    : "строки —";
        }
        StringBuilder sb = new StringBuilder();
        int show = Math.min(rows.size(), EXCEL_ROWS_SHOWN);
        if (show == 1) {
            sb.append("строка Excel ").append(rows.get(0));
        } else {
            sb.append("строки Excel ");
            for (int i = 0; i < show; i++) {
                if (i > 0) {
                    sb.append(", ");
                }
                sb.append(rows.get(i));
            }
        }
        int suppressed = rows.size() - show;
        if (suppressed > 0) {
            sb.append(" и ещё ").append(suppressed);
        }
        if (rowCount > rows.size()) {
            sb.append(" (упоминаний=").append(rowCount).append(")");
        } else if (rows.size() > 1) {
            sb.append(" (").append(rows.size()).append(")");
        }
        return sb.toString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static String escape(String raw) {
        return raw
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
