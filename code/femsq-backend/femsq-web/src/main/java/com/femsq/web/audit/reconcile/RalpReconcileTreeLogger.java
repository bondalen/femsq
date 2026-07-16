package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Дерево сверки type=3 RALP (§9.3.8.4): один ствол «Отчёты аренды»
 * без развилки ОА/прочие/изм. — NEW / CHANGED / A5 пустое «Поступило» / ошибки A1–A4 / (опц.) лишние.
 */
public final class RalpReconcileTreeLogger {

    private static final String HTML_CRIMSON = "#DC143C";

    private RalpReconcileTreeLogger() {
    }

    /**
     * Данные для ствола type=3.
     *
     * @param stagingTotal        всего строк staging
     * @param newReportCount      новые отчёты (ralpRa)
     * @param newAuCount          новые рассмотрения (ralpRaAu)
     * @param changedCount        обновлённые рассмотрения
     * @param newLines            HTML NEW (лимит SUMMARY)
     * @param changedLines        HTML CHANGED
     * @param emptyArrivedLines   A5: строки без «Поступило» (лимит SUMMARY)
     * @param errors              A1–A4 группировка
     * @param orphanNums          лишние № отчётов в БД (может быть пусто)
     * @param applyRequested      apply vs dry-run
     */
    public record TreeModel(
            int stagingTotal,
            int newReportCount,
            int newAuCount,
            int changedCount,
            Type5ReconcileTreeLogger.ListedBlock newLines,
            Type5ReconcileTreeLogger.ListedBlock changedLines,
            Type5ReconcileTreeLogger.ListedBlock emptyArrivedLines,
            Type5ReconcileErrorGrouper.ErrorTree errors,
            List<String> orphanNums,
            boolean applyRequested
    ) {
    }

    /**
     * Пишет дерево внутри текущего span сверки.
     *
     * @param audit   контекст
     * @param auditId ревизия
     * @param execKey исполнение
     * @param model   данные
     */
    public static void appendScaffold(
            AuditExecutionContext audit,
            long auditId,
            long execKey,
            TreeModel model
    ) {
        if (audit == null || model == null) {
            return;
        }
        Map<String, String> baseMeta = baseMeta(auditId, execKey);
        appendPlain(
                audit,
                "RECONCILE_TYPE3_STAGING_TOTAL",
                "<P>Всего строк: <b><font color=\"" + HTML_CRIMSON + "\">"
                        + model.stagingTotal() + "</font></b></P>",
                withMeta(baseMeta, Map.of("stagingTotal", String.valueOf(model.stagingTotal())),
                        "INFO", "CRIMSON", "BOLD")
        );

        int branchTotal = model.stagingTotal();
        String spanId = audit.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE3_REPORTS_START",
                "<P><b>Отчёты аренды</b>"
                        + (branchTotal > 0
                        ? ": <font color=\"" + HTML_CRIMSON + "\">" + branchTotal + "</font>"
                        : "")
                        + "</P>",
                withMeta(baseMeta, Map.of("branch", "Отчёты аренды", "total", String.valueOf(branchTotal)),
                        "START", "BLUE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> appendBody(audit, baseMeta, model));
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE3_REPORTS_END",
                    "<P>Отчёты аренды — конец</P>",
                    withMeta(baseMeta, Map.of("branch", "Отчёты аренды"), "END", "BLUE", "NORMAL")
            );
        }
    }

    private static void appendBody(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            TreeModel model
    ) {
        int neu = model.newReportCount() + model.newAuCount();
        if (neu > 0) {
            StringBuilder found = new StringBuilder();
            found.append("<P><b><font color=\"").append(HTML_CRIMSON)
                    .append("\">Найдено отсутствующих в БД: ").append(neu).append("</font></b>");
            if (model.newReportCount() > 0 || model.newAuCount() > 0) {
                found.append(" (отчёты: ").append(model.newReportCount())
                        .append(", рассмотрения: ").append(model.newAuCount()).append(')');
            }
            found.append("</P>");
            appendPlain(
                    audit,
                    "RECONCILE_TYPE3_TREE_NEW_COUNT",
                    found.toString(),
                    withMeta(baseMeta, Map.of(
                                    "categoryNew", String.valueOf(neu),
                                    "newReports", String.valueOf(model.newReportCount()),
                                    "newAu", String.valueOf(model.newAuCount())
                            ),
                            "INFO", "CRIMSON", "BOLD")
            );
            appendReadySpan(audit, baseMeta, "RECONCILE_TYPE3_NEW_READY", model.applyRequested(), model.newLines());
        } else {
            appendPlain(
                    audit,
                    "RECONCILE_TYPE3_TREE_NEW_EMPTY",
                    "<P>Не найдены отчёты/рассмотрения отсутствующие в БД.</P>",
                    withMeta(baseMeta, Map.of(), "INFO", "SILVER", "NORMAL")
            );
        }

        if (model.changedCount() > 0) {
            appendPlain(
                    audit,
                    "RECONCILE_TYPE3_TREE_CHANGED_COUNT",
                    "<P><b><font color=\"" + HTML_CRIMSON
                            + "\">Найдено рассмотрений имеющих несоответствия в данных: "
                            + model.changedCount() + "</font></b></P>",
                    withMeta(baseMeta, Map.of("categoryChanged", String.valueOf(model.changedCount())),
                            "INFO", "CRIMSON", "BOLD")
            );
            appendReadySpan(
                    audit, baseMeta, "RECONCILE_TYPE3_CHANGED_READY", model.applyRequested(), model.changedLines());
        } else {
            appendPlain(
                    audit,
                    "RECONCILE_TYPE3_TREE_CHANGED_EMPTY",
                    "<P>Не найдены рассмотрения имеющие несоответствия в данных.</P>",
                    withMeta(baseMeta, Map.of(), "INFO", "SILVER", "NORMAL")
            );
        }

        appendEmptyArrived(audit, baseMeta, model.emptyArrivedLines());
        appendErrorTree(audit, baseMeta, model.errors());
        appendOrphans(audit, baseMeta, model.orphanNums(), model.applyRequested());
    }

    /**
     * Span A5: валидный отчёт без рассмотрения (пустое «Поступило»).
     */
    private static void appendEmptyArrived(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            Type5ReconcileTreeLogger.ListedBlock block
    ) {
        if (block == null || !block.hasContent()) {
            return;
        }
        int shown = block.lineHtmls() == null ? 0 : block.lineHtmls().size();
        int total = shown + Math.max(0, block.suppressed());
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE3_EMPTY_ARRIVED_START",
                "<P><b>Без рассмотрения (пустое «Поступило»)</b>: <font color=\""
                        + HTML_CRIMSON + "\">" + total + "</font></P>",
                withMeta(baseMeta, Map.of(
                                "emptyArrived", String.valueOf(total),
                                "primaryReason", "EMPTY_ARRIVED"
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                if (block.lineHtmls() != null) {
                    int i = 0;
                    for (String html : block.lineHtmls()) {
                        if (html == null || html.isBlank()) {
                            continue;
                        }
                        i++;
                        appendPlain(
                                audit,
                                "RECONCILE_TYPE3_EMPTY_ARRIVED_LINE",
                                html,
                                withMeta(baseMeta, Map.of(
                                                "lineIndex", String.valueOf(i),
                                                "primaryReason", "EMPTY_ARRIVED"
                                        ),
                                        "WARN", "ORANGE", "NORMAL")
                        );
                    }
                }
                if (block.suppressed() > 0) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE3_EMPTY_ARRIVED_OVERFLOW",
                            "<P>и ещё " + block.suppressed()
                                    + " (режим SUMMARY; полный список — в VERBOSE).</P>",
                            withMeta(baseMeta, Map.of("suppressed", String.valueOf(block.suppressed())),
                                    "INFO", "SILVER", "NORMAL")
                    );
                }
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE3_EMPTY_ARRIVED_END",
                    "<P>Без рассмотрения — конец</P>",
                    withMeta(baseMeta, Map.of("primaryReason", "EMPTY_ARRIVED"), "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendReadySpan(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            boolean applyRequested,
            Type5ReconcileTreeLogger.ListedBlock block
    ) {
        if (block == null || !block.hasContent()) {
            return;
        }
        String title = applyRequested ? "внесено" : "готово к внесению";
        int shown = block.lineHtmls() == null ? 0 : block.lineHtmls().size();
        int listed = shown + Math.max(0, block.suppressed());
        String spanId = audit.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.SHEET,
                codePrefix + "_START",
                "<P><b>" + escape(title) + "</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + listed + "</font></P>",
                withMeta(baseMeta, Map.of(
                                "readyMode", applyRequested ? "APPLIED" : "READY",
                                "listed", String.valueOf(listed)
                        ),
                        "START", "SEA_GREEN", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                if (block.lineHtmls() != null) {
                    int i = 0;
                    for (String html : block.lineHtmls()) {
                        if (html == null || html.isBlank()) {
                            continue;
                        }
                        i++;
                        appendPlain(
                                audit,
                                "RECONCILE_TYPE3_TREE_LINE",
                                html,
                                withMeta(baseMeta, Map.of("lineIndex", String.valueOf(i)),
                                        "INFO", "NORMAL", "NORMAL")
                        );
                    }
                }
                if (block.suppressed() > 0) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE3_TREE_LINE_OVERFLOW",
                            "<P>и ещё " + block.suppressed()
                                    + " (режим SUMMARY; полный список — в VERBOSE).</P>",
                            withMeta(baseMeta, Map.of("suppressed", String.valueOf(block.suppressed())),
                                    "INFO", "SILVER", "NORMAL")
                    );
                }
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    codePrefix + "_END",
                    "<P>" + escape(title) + " — конец</P>",
                    withMeta(baseMeta, Map.of(), "END", "SEA_GREEN", "NORMAL")
            );
        }
    }

    private static void appendErrorTree(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            Type5ReconcileErrorGrouper.ErrorTree errors
    ) {
        if (errors == null || !errors.hasErrors()) {
            return;
        }
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE3_ERRORS_START",
                "<P><b>Не участвуют в сверке / ошибки</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + errors.totalHits() + "</font> (A1–A4 Stage 2)</P>",
                withMeta(baseMeta, Map.of(
                                "errorTotal", String.valueOf(errors.totalHits()),
                                "primaryReason", "AGGREGATE"
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                appendErrorCategory(audit, baseMeta, "RECONCILE_TYPE3_ERR_CSTAP",
                        "отсутствуют стройки",
                        Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP,
                        errors.missingCstap());
                appendErrorCategory(audit, baseMeta, "RECONCILE_TYPE3_ERR_SENDER",
                        "отсутствует отправитель",
                        Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER,
                        errors.missingSender());
                appendErrorCategory(audit, baseMeta, "RECONCILE_TYPE3_ERR_AMBIGUOUS",
                        "неоднозначное сопоставление",
                        Type5ReconcileErrorGrouper.PRIMARY_AMBIGUOUS,
                        errors.ambiguous());
                appendOtherErrors(audit, baseMeta, errors.others(), errors.othersOverflow());
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE3_ERRORS_END",
                    "<P>Ошибки — конец</P>",
                    withMeta(baseMeta, Map.of(), "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendErrorCategory(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String title,
            String primaryReason,
            List<Type5ReconcileErrorGrouper.ValueGroup> groups
    ) {
        if (groups == null || groups.isEmpty()) {
            return;
        }
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                codePrefix + "_START",
                "<P><b>" + escape(title) + "</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + groups.size() + "</font> знач.</P>",
                withMeta(baseMeta, Map.of(
                                "primaryReason", primaryReason,
                                "valueCount", String.valueOf(groups.size())
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                for (Type5ReconcileErrorGrouper.ValueGroup group : groups) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE3_TREE_ERROR_VALUE",
                            "<P>- «" + escape(group.value()) + "»: "
                                    + formatExcelRows(group.excelRows(), group.suppressedRowCount())
                                    + "</P>",
                            withMeta(baseMeta, Map.of(
                                            "primaryReason", primaryReason,
                                            "groupValue", group.value() == null ? "" : group.value()
                                    ),
                                    "WARN", "CRIMSON", "NORMAL")
                    );
                }
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    codePrefix + "_END",
                    "<P>" + escape(title) + " — конец</P>",
                    withMeta(baseMeta, Map.of("primaryReason", primaryReason), "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendOtherErrors(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            List<Type5ReconcileErrorGrouper.OtherHit> others,
            int overflow
    ) {
        if ((others == null || others.isEmpty()) && overflow <= 0) {
            return;
        }
        int total = (others == null ? 0 : others.size()) + Math.max(0, overflow);
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE3_ERR_OTHER_START",
                "<P><b>иные ошибки</b>: <font color=\"" + HTML_CRIMSON + "\">" + total + "</font></P>",
                withMeta(baseMeta, Map.of(
                                "primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                                "otherTotal", String.valueOf(total)
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                if (others != null) {
                    for (Type5ReconcileErrorGrouper.OtherHit hit : others) {
                        String rowPart = hit.excelRow() == null
                                ? "строка —"
                                : "строка Excel " + hit.excelRow();
                        appendPlain(
                                audit,
                                "RECONCILE_TYPE3_TREE_ERROR_OTHER",
                                "<P>- " + rowPart + " — " + escape(hit.message()) + "</P>",
                                withMeta(baseMeta, Map.of(
                                                "primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                                                "reasonCode", hit.reasonCode() == null ? "" : hit.reasonCode()
                                        ),
                                        "WARN", "CRIMSON", "NORMAL")
                        );
                    }
                }
                if (overflow > 0) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE3_TREE_ERROR_OTHER_OVERFLOW",
                            "<P>и ещё " + overflow + " иных ошибок (режим SUMMARY; полный список — в VERBOSE).</P>",
                            withMeta(baseMeta, Map.of("suppressed", String.valueOf(overflow)),
                                    "INFO", "SILVER", "NORMAL")
                    );
                }
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE3_ERR_OTHER_END",
                    "<P>иные ошибки — конец</P>",
                    withMeta(baseMeta, Map.of("primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER),
                            "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendOrphans(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            List<String> orphanNums,
            boolean applyRequested
    ) {
        if (orphanNums == null || orphanNums.isEmpty()) {
            return;
        }
        String html = RalpReconcileAnomalyFormatter.formatOrphanReportsHtml(orphanNums, applyRequested);
        if (html == null || html.isBlank()) {
            return;
        }
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE3_ORPHAN_START",
                "<P><b>Лишние отчёты в БД</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + orphanNums.size() + "</font></P>",
                withMeta(baseMeta, Map.of("orphanCount", String.valueOf(orphanNums.size())),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> appendPlain(
                    audit,
                    "RECONCILE_TYPE3_ORPHAN_DETAIL",
                    html,
                    withMeta(baseMeta, Map.of("orphanCount", String.valueOf(orphanNums.size())),
                            "WARN", "CRIMSON", "NORMAL")
            ));
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE3_ORPHAN_END",
                    "<P>Лишние — конец</P>",
                    withMeta(baseMeta, Map.of(), "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static String formatExcelRows(List<Integer> rows, int suppressed) {
        StringBuilder sb = new StringBuilder();
        if (rows == null || rows.isEmpty()) {
            sb.append("строки —");
        } else if (rows.size() == 1) {
            sb.append("строка Excel ").append(rows.get(0));
        } else {
            sb.append("строки Excel ");
            for (int i = 0; i < rows.size(); i++) {
                if (i > 0) {
                    sb.append(", ");
                }
                sb.append(rows.get(i));
            }
        }
        if (suppressed > 0) {
            sb.append(" и ещё ").append(suppressed);
        }
        return sb.toString();
    }

    private static void appendPlain(
            AuditExecutionContext audit,
            String code,
            String html,
            Map<String, String> meta
    ) {
        audit.append(AuditLogLevel.INFO, AuditLogScope.SHEET, code, html, meta);
    }

    private static Map<String, String> baseMeta(long auditId, long execKey) {
        Map<String, String> meta = new LinkedHashMap<>();
        meta.put("auditId", String.valueOf(auditId));
        meta.put("execKey", String.valueOf(execKey));
        meta.put("fileType", "3");
        return meta;
    }

    private static Map<String, String> withMeta(
            Map<String, String> base,
            Map<String, String> extra,
            String phase,
            String color,
            String weight
    ) {
        Map<String, String> meta = new HashMap<>(base);
        if (extra != null) {
            meta.putAll(extra);
        }
        meta.put("messageType", phase);
        meta.put("colorHint", color);
        meta.put("emphasis", weight);
        return meta;
    }

    private static String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
