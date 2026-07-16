package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditAnomalyHtmlHighlight;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

/**
 * Тексты аномалий сверки RALP (задача 0051 / §9.3.6.4): A5–A7 и ссылка на invalid Stage 2.
 */
public final class RalpReconcileAnomalyFormatter {

    private static final DateTimeFormatter DATE_RU =
            DateTimeFormatter.ofPattern("dd.MM.yyyy", Locale.forLanguageTag("ru-RU"));
    private static final String DEFAULT_SHEET = "Аренда_Земли";

    private RalpReconcileAnomalyFormatter() {
    }

    /**
     * A5 в дереве сверки: Excel-строка + отчёт (причина — в заголовке span, без дубля).
     */
    public static String formatEmptyArrivedHtml(Integer excelRow, String reportNum, LocalDate reportDate) {
        StringBuilder sb = new StringBuilder("<P>⚠ ");
        sb.append(AuditAnomalyHtmlHighlight.excelRowPrefixHtml(excelRow, DEFAULT_SHEET));
        sb.append("отчёт ").append(AuditAnomalyHtmlHighlight.guillemetRef(nullToEmpty(reportNum)));
        if (reportDate != null) {
            sb.append(" от ").append(DATE_RU.format(reportDate));
        }
        sb.append(".</P>");
        return sb.toString();
    }

    /**
     * Краткая отсылка к некорректным строкам (детализация уже на Этапе 2).
     */
    public static String formatInvalidReferToStage2Html(int invalidCount) {
        return "<P>Сверка: некорректных строк = " + invalidCount
                + " (причины и Excel-строки — в предупреждениях Этапа 2 выше).</P>";
    }

    /**
     * A6: лишние отчёты в домене (orphan delete), стиль Access.
     *
     * @param reportNums номера отчётов (порядок сохранения)
     * @param applied    {@code true}, если реально удаляли; иначе dry-run
     */
    public static String formatOrphanReportsHtml(List<String> reportNums, boolean applied) {
        if (reportNums == null || reportNums.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder("<P>⚠ Лишние отчёты в БД");
        if (!applied) {
            sb.append(" (dry-run, к удалению)");
        }
        sb.append(": ");
        for (int i = 0; i < reportNums.size(); i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append(i + 1).append(". <font color=\"Salmon\">")
                    .append(escape(nullToEmpty(reportNums.get(i))))
                    .append("</font>");
        }
        sb.append(".</P>");
        return sb.toString();
    }

    /**
     * A7: одна операция demote sibling AU.
     */
    public static String formatDemoteHtml(
            Integer excelRow,
            String reportNum,
            String oldArrived,
            boolean hadSent,
            boolean applied
    ) {
        StringBuilder sb = new StringBuilder("<P>");
        sb.append(applied ? "" : "(dry-run) ");
        sb.append(AuditAnomalyHtmlHighlight.excelRowPrefixHtml(excelRow, DEFAULT_SHEET));
        sb.append("отчёт ").append(AuditAnomalyHtmlHighlight.guillemetRef(nullToEmpty(reportNum))).append(": ");
        if (hadSent) {
            sb.append("AU понижено (sent→returned)");
        } else {
            sb.append("AU закрыто (in-process→returned)");
        }
        sb.append(" — прежнее письмо «").append(escape(nullToEmpty(oldArrived))).append("».</P>");
        return sb.toString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static String escape(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
