package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Иерархический лог сверки type=5 (§9.3.8.1–9.3.8.3): ОА / ОА прочие / изменения к базе,
 * списки NEW/CHANGED, группировка ошибок, span «готово к внесению» / «внесено».
 * <p>
 * Вложенные spans используют {@link AuditLogScope#SHEET} (свёрнуты по умолчанию).
 * </p>
 */
public final class Type5ReconcileTreeLogger {

    /** Доменный {@code ra_type} для базовых отчётов ОА. */
    public static final String DOMAIN_OA = "ОА";
    /** Доменный {@code ra_type} для «ОА прочие». */
    public static final String DOMAIN_OA_OTHER = "ОА, прочие";
    /** Excel-признак собственно ОА. */
    public static final String SIGN_OA = "ОА";
    /** Excel-признак собственно ОА прочие. */
    public static final String SIGN_OA_OTHER = "ОА прочие";

    private static final String HTML_CRIMSON = "#DC143C";

    private Type5ReconcileTreeLogger() {
    }

    /**
     * Счётчики одной ветки (собственно RA или изменения RC к базе данного типа).
     *
     * @param total           всего строк ветки
     * @param categoryNew     NEW (отсутствуют в БД)
     * @param categoryChanged CHANGED (несоответствия)
     */
    public record BranchCounts(int total, int categoryNew, int categoryChanged) {
        /** Пустая ветка. */
        public static BranchCounts empty() {
            return new BranchCounts(0, 0, 0);
        }
    }

    /**
     * Список HTML-строк для NEW или CHANGED с учётом SUMMARY-лимита.
     *
     * @param lineHtmls  показанные абзацы
     * @param suppressed число скрытых («и ещё N»)
     */
    public record ListedBlock(List<String> lineHtmls, int suppressed) {
        /** Пустой блок. */
        public static ListedBlock empty() {
            return new ListedBlock(List.of(), 0);
        }

        /** @return есть ли что писать в span готовности */
        public boolean hasContent() {
            return (lineHtmls != null && !lineHtmls.isEmpty()) || suppressed > 0;
        }
    }

    /**
     * Счётчики + списки строк + дерево ошибок (§9.3.8.3) для одной конечной ветки.
     *
     * @param counts       агрегаты NEW/CHANGED
     * @param newLines     NEW
     * @param changedLines CHANGED
     * @param errors       группированные ошибки (может быть {@link Type5ReconcileErrorGrouper.ErrorTree#empty()})
     */
    public record BranchDetail(
            BranchCounts counts,
            ListedBlock newLines,
            ListedBlock changedLines,
            Type5ReconcileErrorGrouper.ErrorTree errors
    ) {
        /** Только счётчики, без списков и ошибок. */
        public static BranchDetail ofCounts(BranchCounts counts) {
            return new BranchDetail(
                    counts == null ? BranchCounts.empty() : counts,
                    ListedBlock.empty(),
                    ListedBlock.empty(),
                    Type5ReconcileErrorGrouper.ErrorTree.empty()
            );
        }

        /** Счётчики и списки без ошибок. */
        public static BranchDetail of(BranchCounts counts, ListedBlock newLines, ListedBlock changedLines) {
            return new BranchDetail(
                    counts == null ? BranchCounts.empty() : counts,
                    newLines == null ? ListedBlock.empty() : newLines,
                    changedLines == null ? ListedBlock.empty() : changedLines,
                    Type5ReconcileErrorGrouper.ErrorTree.empty()
            );
        }
    }

    /**
     * Разбиение для дерева type=5.
     *
     * @param stagingTotal всего строк staging
     * @param oaRa         собственно ОА
     * @param oaRc         изменения к базе ОА
     * @param otherRa      собственно ОА прочие
     * @param otherRc      изменения к базе «ОА, прочие»
     * @param orphanRc     изменения без определённой базы
     */
    public record TreeCounts(
            int stagingTotal,
            BranchDetail oaRa,
            BranchDetail oaRc,
            BranchDetail otherRa,
            BranchDetail otherRc,
            BranchDetail orphanRc
    ) {
    }

    /**
     * Пишет дерево: всего staging → ОА → собственно / изм. → ОА прочие → … → (опц.) orphan.
     *
     * @param audit          контекст (no-op при {@code null})
     * @param auditId        ревизия
     * @param execKey        исполнение
     * @param counts         счётчики и списки
     * @param applyRequested {@code true} → заголовок «внесено», иначе «готово к внесению»
     */
    public static void appendScaffold(
            AuditExecutionContext audit,
            long auditId,
            long execKey,
            TreeCounts counts,
            boolean applyRequested
    ) {
        if (audit == null || counts == null) {
            return;
        }
        Map<String, String> baseMeta = baseMeta(auditId, execKey);
        appendPlain(
                audit,
                "RECONCILE_TYPE5_STAGING_TOTAL",
                "<P>Всего строк: <b><font color=\"" + HTML_CRIMSON + "\">"
                        + counts.stagingTotal() + "</font></b></P>",
                withMeta(baseMeta, Map.of("stagingTotal", String.valueOf(counts.stagingTotal())),
                        "INFO", "CRIMSON", "BOLD")
        );

        appendGroup(
                audit,
                baseMeta,
                "RECONCILE_TYPE5_OA",
                "ОА",
                safeTotal(counts.oaRa()) + safeTotal(counts.oaRc()),
                () -> {
                    appendLeafBranch(
                            audit, baseMeta, "RECONCILE_TYPE5_OA_RA", "Собственно ОА",
                            counts.oaRa(), true, false, applyRequested
                    );
                    appendLeafBranch(
                            audit, baseMeta, "RECONCILE_TYPE5_OA_RC", "Изменения к ОА",
                            counts.oaRc(), false, false, applyRequested
                    );
                }
        );

        appendGroup(
                audit,
                baseMeta,
                "RECONCILE_TYPE5_OA_OTHER",
                "ОА прочие",
                safeTotal(counts.otherRa()) + safeTotal(counts.otherRc()),
                () -> {
                    appendLeafBranch(
                            audit, baseMeta, "RECONCILE_TYPE5_OA_OTHER_RA", "Собственно ОА прочие",
                            counts.otherRa(), true, false, applyRequested
                    );
                    appendLeafBranch(
                            audit, baseMeta, "RECONCILE_TYPE5_OA_OTHER_RC", "Изменения к ОА прочие",
                            counts.otherRc(), false, false, applyRequested
                    );
                }
        );

        BranchDetail orphan = counts.orphanRc();
        if (orphan != null && (safeTotal(orphan) > 0
                || (orphan.counts() != null && (orphan.counts().categoryNew() > 0
                || orphan.counts().categoryChanged() > 0))
                || (orphan.errors() != null && orphan.errors().hasErrors()))) {
            appendLeafBranch(
                    audit, baseMeta, "RECONCILE_TYPE5_RC_ORPHAN", "Изменения без определённой базы",
                    orphan, false, true, applyRequested
            );
        }
    }

    /**
     * Совместимость с юнит-тестами каркаса (§9.3.8.1): dry-run, без apply-флага.
     *
     * @param audit   контекст
     * @param auditId ревизия
     * @param execKey исполнение
     * @param counts  счётчики (без детальных списков допустимы через {@link BranchDetail#ofCounts})
     */
    public static void appendScaffold(
            AuditExecutionContext audit,
            long auditId,
            long execKey,
            TreeCounts counts
    ) {
        appendScaffold(audit, auditId, execKey, counts, false);
    }

    private static int safeTotal(BranchDetail detail) {
        return detail == null || detail.counts() == null ? 0 : detail.counts().total();
    }

    private static void appendGroup(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String title,
            int total,
            Runnable children
    ) {
        String spanId = audit.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.SHEET,
                codePrefix + "_START",
                "<P><b>" + escape(title) + "</b>"
                        + (total > 0 ? ": <font color=\"" + HTML_CRIMSON + "\">" + total + "</font>" : "")
                        + "</P>",
                withMeta(baseMeta, Map.of("branch", title, "total", String.valueOf(total)),
                        "START", "BLUE", "BOLD")
        );
        try {
            audit.inSpan(spanId, children);
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    codePrefix + "_END",
                    "<P>" + escape(title) + " — конец</P>",
                    withMeta(baseMeta, Map.of("branch", title), "END", "BLUE", "NORMAL")
            );
        }
    }

    private static void appendLeafBranch(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String title,
            BranchDetail detail,
            boolean reportsNotChanges,
            boolean unresolvedOnly,
            boolean applyRequested
    ) {
        BranchCounts counts = detail == null || detail.counts() == null
                ? BranchCounts.empty()
                : detail.counts();
        int total = counts.total();
        int neu = counts.categoryNew();
        int changed = counts.categoryChanged();
        String spanId = audit.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.SHEET,
                codePrefix + "_START",
                "<P><b>" + escape(title) + "</b>"
                        + (total > 0 ? ": <font color=\"" + HTML_CRIMSON + "\">" + total + "</font>" : "")
                        + "</P>",
                withMeta(baseMeta, Map.of(
                                "branch", title,
                                "total", String.valueOf(total),
                                "categoryNew", String.valueOf(neu),
                                "categoryChanged", String.valueOf(changed)
                        ),
                        "START", "BLUE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> appendBranchBody(
                    audit,
                    baseMeta,
                    title,
                    codePrefix,
                    total,
                    neu,
                    changed,
                    reportsNotChanges,
                    unresolvedOnly,
                    applyRequested,
                    detail == null ? ListedBlock.empty() : nullSafe(detail.newLines()),
                    detail == null ? ListedBlock.empty() : nullSafe(detail.changedLines()),
                    detail == null || detail.errors() == null
                            ? Type5ReconcileErrorGrouper.ErrorTree.empty()
                            : detail.errors()
            ));
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    codePrefix + "_END",
                    "<P>" + escape(title) + " — конец</P>",
                    withMeta(baseMeta, Map.of("branch", title), "END", "BLUE", "NORMAL")
            );
        }
    }

    private static ListedBlock nullSafe(ListedBlock block) {
        return block == null ? ListedBlock.empty() : block;
    }

    private static void appendBranchBody(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String branch,
            String codePrefix,
            int total,
            int neu,
            int changed,
            boolean reportsNotChanges,
            boolean unresolvedOnly,
            boolean applyRequested,
            ListedBlock newLines,
            ListedBlock changedLines,
            Type5ReconcileErrorGrouper.ErrorTree errors
    ) {
        if (unresolvedOnly) {
            appendPlain(
                    audit,
                    "RECONCILE_TYPE5_TREE_UNRESOLVED",
                    "<P>Строк без NEW/CHANGED (ошибки resolve / неоднозначность): <b><font color=\""
                            + HTML_CRIMSON + "\">" + total + "</font></b>.</P>",
                    withMeta(baseMeta, Map.of("branch", branch, "total", String.valueOf(total)),
                            "INFO", "ORANGE", "NORMAL")
            );
            appendErrorTree(audit, baseMeta, codePrefix, branch, errors);
            return;
        }
        if (neu > 0) {
            String found = reportsNotChanges
                    ? "Найдено отчётов отсутствующих в БД: "
                    : "Найдено изменений отсутствующих в БД: ";
            appendPlain(
                    audit,
                    "RECONCILE_TYPE5_TREE_NEW_COUNT",
                    "<P><b><font color=\"" + HTML_CRIMSON + "\">" + found + neu + "</font></b></P>",
                    withMeta(baseMeta, Map.of("branch", branch, "categoryNew", String.valueOf(neu)),
                            "INFO", "CRIMSON", "BOLD")
            );
            appendReadySpan(audit, baseMeta, codePrefix + "_NEW_READY", branch, applyRequested, newLines);
        } else {
            String empty = reportsNotChanges
                    ? "Не найдены отчёты отсутствующие в БД."
                    : "Не найдены изменения отсутствующие в БД.";
            appendPlain(
                    audit,
                    "RECONCILE_TYPE5_TREE_NEW_EMPTY",
                    "<P>" + escape(empty) + "</P>",
                    withMeta(baseMeta, Map.of("branch", branch), "INFO", "SILVER", "NORMAL")
            );
        }

        if (changed > 0) {
            String found = reportsNotChanges
                    ? "Найдено отчётов имеющих несоответствия в данных: "
                    : "Найдено изменений имеющих несоответствия в данных: ";
            appendPlain(
                    audit,
                    "RECONCILE_TYPE5_TREE_CHANGED_COUNT",
                    "<P><b><font color=\"" + HTML_CRIMSON + "\">" + found + changed + "</font></b></P>",
                    withMeta(baseMeta, Map.of("branch", branch, "categoryChanged", String.valueOf(changed)),
                            "INFO", "CRIMSON", "BOLD")
            );
            appendReadySpan(audit, baseMeta, codePrefix + "_CHANGED_READY", branch, applyRequested, changedLines);
        } else {
            String empty = reportsNotChanges
                    ? "Не найдены отчёты имеющие несоответствия в данных."
                    : "Не найдены изменения имеющие несоответствия в данных.";
            appendPlain(
                    audit,
                    "RECONCILE_TYPE5_TREE_CHANGED_EMPTY",
                    "<P>" + escape(empty) + "</P>",
                    withMeta(baseMeta, Map.of("branch", branch), "INFO", "SILVER", "NORMAL")
            );
        }

        appendErrorTree(audit, baseMeta, codePrefix, branch, errors);
    }

    /**
     * Ветка «Не участвуют в сверке / ошибки» с группировкой по primary reason (§9.3.8.3).
     */
    private static void appendErrorTree(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String branch,
            Type5ReconcileErrorGrouper.ErrorTree errors
    ) {
        if (errors == null || !errors.hasErrors()) {
            return;
        }
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                codePrefix + "_ERRORS_START",
                "<P><b>Не участвуют в сверке / ошибки</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + errors.totalHits() + "</font></P>",
                withMeta(baseMeta, Map.of(
                                "branch", branch,
                                "errorTotal", String.valueOf(errors.totalHits()),
                                "primaryReason", "AGGREGATE"
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                appendErrorCategory(
                        audit, baseMeta, codePrefix + "_ERR_CSTAP", branch,
                        "отсутствуют стройки",
                        Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP,
                        errors.missingCstap()
                );
                appendErrorCategory(
                        audit, baseMeta, codePrefix + "_ERR_SENDER", branch,
                        "отсутствует отправитель",
                        Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER,
                        errors.missingSender()
                );
                appendErrorCategory(
                        audit, baseMeta, codePrefix + "_ERR_AMBIGUOUS", branch,
                        "неоднозначное сопоставление",
                        Type5ReconcileErrorGrouper.PRIMARY_AMBIGUOUS,
                        errors.ambiguous()
                );
                appendOtherErrors(audit, baseMeta, codePrefix, branch, errors.others(), errors.othersOverflow());
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    codePrefix + "_ERRORS_END",
                    "<P>Ошибки — конец</P>",
                    withMeta(baseMeta, Map.of("branch", branch), "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendErrorCategory(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String branch,
            String title,
            String primaryReason,
            List<Type5ReconcileErrorGrouper.ValueGroup> groups
    ) {
        if (groups == null || groups.isEmpty()) {
            return;
        }
        int hitEstimate = 0;
        for (Type5ReconcileErrorGrouper.ValueGroup g : groups) {
            hitEstimate += g.excelRows().size() + g.suppressedRowCount();
        }
        String spanId = audit.beginSpan(
                AuditLogLevel.WARNING,
                AuditLogScope.SHEET,
                codePrefix + "_START",
                "<P><b>" + escape(title) + "</b>: <font color=\"" + HTML_CRIMSON + "\">"
                        + groups.size() + "</font> знач.</P>",
                withMeta(baseMeta, Map.of(
                                "branch", branch,
                                "primaryReason", primaryReason,
                                "valueCount", String.valueOf(groups.size()),
                                "approxHits", String.valueOf(hitEstimate)
                        ),
                        "START", "ORANGE", "BOLD")
        );
        try {
            audit.inSpan(spanId, () -> {
                for (Type5ReconcileErrorGrouper.ValueGroup group : groups) {
                    String rowsText = formatExcelRows(group.excelRows(), group.suppressedRowCount());
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE5_TREE_ERROR_VALUE",
                            "<P>- «" + escape(group.value()) + "»: " + rowsText + "</P>",
                            withMeta(baseMeta, Map.of(
                                            "branch", branch,
                                            "primaryReason", primaryReason,
                                            "groupValue", group.value() == null ? "" : group.value(),
                                            "reasonCode", group.reasonCodeSample() == null ? "" : group.reasonCodeSample()
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
                    withMeta(baseMeta, Map.of("branch", branch, "primaryReason", primaryReason),
                            "END", "ORANGE", "NORMAL")
            );
        }
    }

    private static void appendOtherErrors(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String branch,
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
                codePrefix + "_ERR_OTHER_START",
                "<P><b>иные ошибки</b>: <font color=\"" + HTML_CRIMSON + "\">" + total + "</font></P>",
                withMeta(baseMeta, Map.of(
                                "branch", branch,
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
                                "RECONCILE_TYPE5_TREE_ERROR_OTHER",
                                "<P>- " + rowPart + " — " + escape(hit.message()) + "</P>",
                                withMeta(baseMeta, Map.of(
                                                "branch", branch,
                                                "primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                                                "reasonCode", hit.reasonCode() == null ? "" : hit.reasonCode(),
                                                "rowIndex", hit.excelRow() == null ? "" : String.valueOf(hit.excelRow())
                                        ),
                                        "WARN", "CRIMSON", "NORMAL")
                        );
                    }
                }
                if (overflow > 0) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE5_TREE_ERROR_OTHER_OVERFLOW",
                            "<P>и ещё " + overflow + " иных ошибок (режим SUMMARY; полный список — в VERBOSE).</P>",
                            withMeta(baseMeta, Map.of(
                                            "branch", branch,
                                            "primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                                            "suppressed", String.valueOf(overflow)
                                    ),
                                    "INFO", "SILVER", "NORMAL")
                    );
                }
            });
        } finally {
            audit.endSpan(
                    spanId,
                    AuditLogLevel.WARNING,
                    AuditLogScope.SHEET,
                    codePrefix + "_ERR_OTHER_END",
                    "<P>иные ошибки — конец</P>",
                    withMeta(baseMeta, Map.of(
                                    "branch", branch,
                                    "primaryReason", Type5ReconcileErrorGrouper.PRIMARY_OTHER
                            ),
                            "END", "ORANGE", "NORMAL")
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

    /**
     * Вложенный span «готово к внесению» (dry-run) или «внесено» (apply) со списком строк.
     */
    private static void appendReadySpan(
            AuditExecutionContext audit,
            Map<String, String> baseMeta,
            String codePrefix,
            String branch,
            boolean applyRequested,
            ListedBlock block
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
                                "branch", branch,
                                "readyMode", applyRequested ? "APPLIED" : "READY",
                                "listed", String.valueOf(listed),
                                "shown", String.valueOf(shown),
                                "suppressed", String.valueOf(block.suppressed())
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
                                "RECONCILE_TYPE5_TREE_LINE",
                                html,
                                withMeta(baseMeta, Map.of(
                                                "branch", branch,
                                                "lineIndex", String.valueOf(i)
                                        ),
                                        "INFO", "NORMAL", "NORMAL")
                        );
                    }
                }
                if (block.suppressed() > 0) {
                    appendPlain(
                            audit,
                            "RECONCILE_TYPE5_TREE_LINE_OVERFLOW",
                            "<P>и ещё " + block.suppressed()
                                    + " (режим SUMMARY; полный список — в VERBOSE).</P>",
                            withMeta(baseMeta, Map.of(
                                            "branch", branch,
                                            "suppressed", String.valueOf(block.suppressed())
                                    ),
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
                    withMeta(baseMeta, Map.of("branch", branch), "END", "SEA_GREEN", "NORMAL")
            );
        }
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
        meta.put("fileType", "5");
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
