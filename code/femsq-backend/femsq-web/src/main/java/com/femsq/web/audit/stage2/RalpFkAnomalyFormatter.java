package com.femsq.web.audit.stage2;

import com.femsq.web.audit.AuditAnomalyHtmlHighlight;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Форматирование сообщений Stage 2 RALP о неразрешённых FK (стиль Access {@code RAAudit_ralp}).
 */
public final class RalpFkAnomalyFormatter {

    private static final DateTimeFormatter DATE_RU =
            DateTimeFormatter.ofPattern("dd.MM.yyyy", Locale.forLanguageTag("ru-RU"));
    /** VBA Like {@code ###-#######}. */
    private static final Pattern CST_CODE_PATTERN = Pattern.compile("\\d{3}-\\d{7}");

    private RalpFkAnomalyFormatter() {
    }

    /**
     * Собирает человекочитаемые причины (A1–A4) для одной staging-строки.
     *
     * @param row строка после Stage 2
     * @return список причин (может быть пустым, если всё разрешено)
     */
    public static List<String> reasonLines(RalpFkAnomalyRow row) {
        List<String> reasons = new ArrayList<>(3);
        if (row == null) {
            return reasons;
        }
        if (row.cstAgPn() == null) {
            reasons.add(formatCstReason(row.cstCodeStr()));
        }
        if (row.reportDate() == null) {
            reasons.add("дата отсутствует");
        }
        if (row.ogSender() == null) {
            reasons.add(formatOgReason(row.ogSenderStr(), row.ogBranchStr()));
        }
        return reasons;
    }

    /**
     * HTML-{@code <P>} для SUMMARY/VERBOSE: Excel-строка + отчёт + причины.
     *
     * @param row       staging-аномалия
     * @param sheetName имя листа (может быть {@code null})
     * @return HTML-фрагмент для {@code adt_results}
     */
    public static String formatWarningHtml(RalpFkAnomalyRow row, String sheetName) {
        List<String> reasonsHtml = reasonLinesHtml(row);
        if (reasonsHtml.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder("<P>⚠ ");
        sb.append(AuditAnomalyHtmlHighlight.excelRowPrefixHtml(row.excelRow(), sheetName));
        sb.append("отчёт ").append(AuditAnomalyHtmlHighlight.guillemetRef(nullToEmpty(row.reportNum())));
        if (row.reportDate() != null) {
            sb.append(" от ").append(DATE_RU.format(row.reportDate()));
        }
        sb.append(":<br/>");
        for (String reasonHtml : reasonsHtml) {
            sb.append(" — ").append(reasonHtml).append(".<br/>");
        }
        sb.append(" → строка исключена из сверки (некорректная).</P>");
        return sb.toString();
    }

    /**
     * HTML-причины с подсвеченными некорректными значениями (для {@code adt_results}).
     */
    static List<String> reasonLinesHtml(RalpFkAnomalyRow row) {
        List<String> reasons = new ArrayList<>(3);
        if (row == null) {
            return reasons;
        }
        if (row.cstAgPn() == null) {
            reasons.add(formatCstReasonHtml(row.cstCodeStr()));
        }
        if (row.reportDate() == null) {
            reasons.add("дата отсутствует");
        }
        if (row.ogSender() == null) {
            reasons.add(formatOgReasonHtml(row.ogSenderStr(), row.ogBranchStr()));
        }
        return reasons;
    }

    /**
     * Итог Stage 2 с количеством неразрешённых строк.
     */
    public static String formatStage2SummaryHtml(
            int resolvedCst,
            int resolvedOg,
            int resolvedSm,
            int computedStatus,
            int stagingRows,
            int unresolvedRows,
            int unresolvedCst,
            int unresolvedOg,
            int unresolvedDate
    ) {
        return "<P>Этап 2 (RALP) выполнен: заказчик (CstAgPn) разрешён = " + resolvedCst
                + ", отправитель ОГ разрешён = " + resolvedOg
                + ", агент (сводка) разрешён = " + resolvedSm
                + ", статус пересчитан = " + computedStatus
                + "; промежуточная таблица = " + stagingRows
                + ", неразрешённых строк = " + unresolvedRows
                + " (стройка NULL = " + unresolvedCst
                + ", отправитель NULL = " + unresolvedOg
                + ", дата NULL = " + unresolvedDate
                + ").</P>";
    }

    static String formatCstReason(String cstCodeRaw) {
        String code = trimToEmpty(cstCodeRaw);
        if (code.isEmpty()) {
            return "код стройки пуст";
        }
        if (!CST_CODE_PATTERN.matcher(code).matches()) {
            return "стройка не найдена: «" + code + "»";
        }
        return "стройка «" + code + "» в БД отсутствует";
    }

    static String formatCstReasonHtml(String cstCodeRaw) {
        String code = trimToEmpty(cstCodeRaw);
        if (code.isEmpty()) {
            return "код стройки пуст";
        }
        if (!CST_CODE_PATTERN.matcher(code).matches()) {
            return "стройка не найдена: " + AuditAnomalyHtmlHighlight.guillemet(code);
        }
        return "стройка " + AuditAnomalyHtmlHighlight.guillemet(code) + " в БД отсутствует";
    }

    static String formatOgReason(String senderRaw, String branchRaw) {
        String sender = trimToEmpty(senderRaw);
        String branch = trimToEmpty(branchRaw);
        if (!branch.isEmpty()) {
            return "филиал-отправитель в БД отсутствует, или их несколько: «"
                    + sender + "» / «" + branch + "»";
        }
        return "отправитель в БД отсутствует, или их несколько: «" + sender + "»";
    }

    static String formatOgReasonHtml(String senderRaw, String branchRaw) {
        String sender = trimToEmpty(senderRaw);
        String branch = trimToEmpty(branchRaw);
        if (!branch.isEmpty()) {
            return "филиал-отправитель в БД отсутствует, или их несколько: "
                    + AuditAnomalyHtmlHighlight.guillemet(sender)
                    + " / "
                    + AuditAnomalyHtmlHighlight.guillemet(branch);
        }
        return "отправитель в БД отсутствует, или их несколько: "
                + AuditAnomalyHtmlHighlight.guillemet(sender);
    }

    private static String trimToEmpty(String value) {
        return value == null ? "" : value.trim();
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
