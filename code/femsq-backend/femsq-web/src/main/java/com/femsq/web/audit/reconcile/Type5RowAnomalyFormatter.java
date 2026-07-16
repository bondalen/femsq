package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditAnomalyHtmlHighlight;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * Построчные WARN type=5 (задача 0051 / §9.3.6.5): Excel-строка + причина.
 */
public final class Type5RowAnomalyFormatter {

    private static final DateTimeFormatter DATE_RU =
            DateTimeFormatter.ofPattern("dd.MM.yyyy", Locale.forLanguageTag("ru-RU"));
    private static final String DEFAULT_SHEET = "Отчеты";

    private Type5RowAnomalyFormatter() {
    }

    /**
     * HTML для отказа валидации RA (некорректная / неоднозначная).
     */
    public static String formatRaFailHtml(
            Integer excelRow,
            String raNum,
            LocalDate raDate,
            String reasonCode,
            String detailText
    ) {
        return formatFailHtml("ОА", excelRow, raNum, raDate, reasonCode, detailText, humanRaOutcome(reasonCode));
    }

    /**
     * HTML для отказа валидации RC («ОА изм»).
     */
    public static String formatRcFailHtml(
            Integer excelRow,
            String raNum,
            LocalDate raDate,
            String reasonCode,
            String detailText
    ) {
        return formatFailHtml("ОА изм", excelRow, raNum, raDate, reasonCode, detailText, humanRcOutcome(reasonCode));
    }

    private static String formatFailHtml(
            String kind,
            Integer excelRow,
            String raNum,
            LocalDate raDate,
            String reasonCode,
            String detailText,
            String outcome
    ) {
        StringBuilder sb = new StringBuilder("<P>⚠ ");
        sb.append(AuditAnomalyHtmlHighlight.excelRowPrefixHtml(excelRow, DEFAULT_SHEET));
        sb.append(escape(kind)).append(" ").append(AuditAnomalyHtmlHighlight.guillemetRef(nullToEmpty(raNum)));
        if (raDate != null) {
            sb.append(" от ").append(DATE_RU.format(raDate));
        }
        sb.append(": ").append(AuditAnomalyHtmlHighlight.highlightGuillemetValues(nullToEmpty(detailText)));
        if (reasonCode != null && !reasonCode.isBlank()) {
            sb.append(" <font color=\"silver\">[").append(escape(reasonCode)).append("]</font>");
        }
        sb.append(" → ").append(escape(outcome)).append(".</P>");
        return sb.toString();
    }

    static String humanRaOutcome(String reasonCode) {
        if ("AMBIGUOUS_MATCH".equals(reasonCode)) {
            return "неоднозначная";
        }
        return "некорректная";
    }

    static String humanRcOutcome(String reasonCode) {
        if (reasonCode != null && reasonCode.contains("AMBIGUOUS")) {
            return "неоднозначная";
        }
        return "некорректная";
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
