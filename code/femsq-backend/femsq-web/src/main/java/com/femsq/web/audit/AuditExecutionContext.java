package com.femsq.web.audit;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * Контекст выполнения ревизии (первичный аналог ra_a в VBA).
 *
 * На этом этапе содержит только минимально необходимую информацию для
 * оркестровки и накопления лога в структурированном виде.
 */
public class AuditExecutionContext {

    /**
     * Визуальный контракт отступов (px на уровень вложенности).
     */
    private static final int INDENT_STEP_PX = 16;
    private static final String STYLE_BLOCK = """
            <style>
              .femsq-auditlog details {
                margin: 0;
                border-left: 1px solid rgba(120, 139, 166, 0.45);
                margin-left: 2px;
              }
              .femsq-auditlog summary { list-style: none; }
              .femsq-auditlog summary::-webkit-details-marker { display: none; }
              .femsq-auditlog summary::marker { content: ""; }

              .femsq-auditlog .row { margin: 0; padding: 2px 8px; }
              .femsq-auditlog .summary { padding: 3px 8px; border-radius: 8px; cursor: pointer; user-select: none; }
              .femsq-auditlog .badge { display: inline-block; font-size: 11px; line-height: 16px; padding: 0 6px; border-radius: 999px; margin-right: 8px; vertical-align: baseline; }

              .femsq-auditlog .lvl-info { color: #c9d1d9; }
              .femsq-auditlog .lvl-success { color: #1f7a3f; background: #0f2a1a; border-left: 3px solid #2ea043; }
              .femsq-auditlog .lvl-warning { color: #f2cc60; background: #2a200f; border-left: 3px solid #d29922; }
              .femsq-auditlog .lvl-error { color: #ffb4b4; background: #2a1414; border-left: 3px solid #f85149; }
              .femsq-auditlog .lvl-summary { color: #b7d7ff; background: #0f1f2a; border-left: 3px solid #58a6ff; }

              .femsq-auditlog .phase-start { font-weight: 650; }
              .femsq-auditlog .phase-end { font-weight: 650; opacity: 0.95; }

              .femsq-auditlog .badge-start { background: rgba(88,166,255,0.14); color: #b7d7ff; border: 1px solid rgba(88,166,255,0.35); }
              .femsq-auditlog .badge-end { background: rgba(46,160,67,0.12); color: #98e19a; border: 1px solid rgba(46,160,67,0.35); }
              .femsq-auditlog .badge-info { background: rgba(201,209,217,0.08); color: #c9d1d9; border: 1px solid rgba(201,209,217,0.18); }
            </style>
            """;

    private final long auditId;
    private Long directoryId;
    private String directoryPath;
    private Long executionKey;
    private Integer year;
    private Boolean addRa;
    private Integer auditType;

    /**
     * Записи лога в естественном хронологическом порядке (старые → новые).
     * HTML-представление для adt_results собирается из этих записей
     * отдельным методом, который при необходимости может менять порядок
     * (например, новые события сверху).
     */
    private final List<AuditLogEntry> entries = new ArrayList<>();

    private Instant startedAt;
    private Instant lastUpdatedAt;

    private final AtomicLong spanSeq = new AtomicLong(0);
    private final List<String> spanStack = new ArrayList<>();
    private Consumer<AuditExecutionContext> onEntryAppended;

    public AuditExecutionContext(long auditId) {
        this.auditId = auditId;
    }

    public long getAuditId() {
        return auditId;
    }

    public Long getDirectoryId() {
        return directoryId;
    }

    public void setDirectoryId(Long directoryId) {
        this.directoryId = directoryId;
    }

    public String getDirectoryPath() {
        return directoryPath;
    }

    public void setDirectoryPath(String directoryPath) {
        this.directoryPath = directoryPath;
    }

    public Long getExecutionKey() {
        return executionKey;
    }

    public void setExecutionKey(Long executionKey) {
        this.executionKey = executionKey;
    }

    public Integer getYear() {
        return year;
    }

    public void setYear(Integer year) {
        this.year = year;
    }

    public Boolean getAddRa() {
        return addRa;
    }

    public void setAddRa(Boolean addRa) {
        this.addRa = addRa;
    }

    public Integer getAuditType() {
        return auditType;
    }

    public void setAuditType(Integer auditType) {
        this.auditType = auditType;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(Instant startedAt) {
        this.startedAt = startedAt;
    }

    public Instant getLastUpdatedAt() {
        return lastUpdatedAt;
    }

    public void setLastUpdatedAt(Instant lastUpdatedAt) {
        this.lastUpdatedAt = lastUpdatedAt;
    }

    public List<AuditLogEntry> getEntries() {
        return Collections.unmodifiableList(entries);
    }

    public void appendEntry(AuditLogEntry entry) {
        if (entry != null) {
            AuditLogEntry normalized = normalizeParentSpan(entry);
            entries.add(normalized);
            lastUpdatedAt = normalized.getTimestamp();
            if (onEntryAppended != null) {
                onEntryAppended.accept(this);
            }
        }
    }

    public void setOnEntryAppended(Consumer<AuditExecutionContext> onEntryAppended) {
        this.onEntryAppended = onEntryAppended;
    }

    private AuditLogEntry normalizeParentSpan(AuditLogEntry entry) {
        // Если запись добавлена "старыми" вызовами (appendEntry(new AuditLogEntry(...)))
        // внутри активного span, у неё нет parentSpanId и она окажется на верхнем уровне.
        // Автоматически привязываем такие leaf-события к текущему span.
        String current = currentSpanId();
        if (current == null || current.isBlank()) {
            return entry;
        }
        if (entry.getSpanId() != null && !entry.getSpanId().isBlank()) {
            return entry;
        }
        if (entry.getParentSpanId() != null && !entry.getParentSpanId().isBlank()) {
            return entry;
        }
        return new AuditLogEntry(
                entry.getTimestamp(),
                entry.getLevel(),
                entry.getScope(),
                null,
                current,
                entry.getCode(),
                entry.getMessageHtml(),
                entry.getMeta()
        );
    }

    public void append(AuditLogLevel level, AuditLogScope scope, String code, String messageHtml, Map<String, String> meta) {
        String parentSpanId = currentSpanId();
        appendEntry(new AuditLogEntry(Instant.now(), level, scope, null, parentSpanId, code, messageHtml, meta));
    }

    public String beginSpan(AuditLogLevel level, AuditLogScope scope, String code, String messageHtml, Map<String, String> meta) {
        String spanId = nextSpanId();
        String parentSpanId = currentSpanId();
        appendEntry(new AuditLogEntry(Instant.now(), level, scope, spanId, parentSpanId, code, messageHtml, meta));
        spanStack.add(spanId);
        return spanId;
    }

    public void endSpan(String spanId, AuditLogLevel level, AuditLogScope scope, String code, String messageHtml, Map<String, String> meta) {
        if (spanId == null) {
            append(level, scope, code, messageHtml, meta);
            return;
        }
        String parentSpanId = spanId;
        appendEntry(new AuditLogEntry(Instant.now(), level, scope, null, parentSpanId, code, messageHtml, meta));
        popSpan(spanId);
    }

    public void inSpan(String spanId, Runnable runnable) {
        if (spanId == null) {
            runnable.run();
            return;
        }
        spanStack.add(spanId);
        try {
            runnable.run();
        } finally {
            popSpan(spanId);
        }
    }

    public <T> T inSpan(String spanId, Supplier<T> supplier) {
        if (spanId == null) {
            return supplier.get();
        }
        spanStack.add(spanId);
        try {
            return supplier.get();
        } finally {
            popSpan(spanId);
        }
    }

    private String nextSpanId() {
        return "s" + spanSeq.incrementAndGet();
    }

    private String currentSpanId() {
        return spanStack.isEmpty() ? null : spanStack.get(spanStack.size() - 1);
    }

    private void popSpan(String expected) {
        if (spanStack.isEmpty()) {
            return;
        }
        int lastIdx = spanStack.size() - 1;
        if (expected.equals(spanStack.get(lastIdx))) {
            spanStack.remove(lastIdx);
            return;
        }
        // fallback: remove nearest occurrence from the end to keep state consistent
        for (int i = spanStack.size() - 1; i >= 0; i--) {
            if (expected.equals(spanStack.get(i))) {
                spanStack.remove(i);
                return;
            }
        }
    }

    /**
     * Формирует HTML-документ для сохранения в adt_results.
     *
     * Contract: прямой хронологический порядок внутри блоков (старые → новые),
     * чтобы "ход ревизии" читался как последовательность выполнения.
     */
    public String buildHtmlLog() {
        // Построение дерева span-ов для сворачивания/разворачивания (<details>/<summary>).
        Map<String, SpanNode> spans = new HashMap<>();
        for (AuditLogEntry entry : entries) {
            if (entry.getSpanId() != null && !entry.getSpanId().isBlank()) {
                spans.put(entry.getSpanId(), new SpanNode(entry.getSpanId(), entry));
            }
        }

        RootNode root = new RootNode();
        for (AuditLogEntry entry : entries) {
            if (entry.getSpanId() != null && !entry.getSpanId().isBlank()) {
                SpanNode node = spans.get(entry.getSpanId());
                attachNode(root, spans, entry.getParentSpanId(), node);
                continue;
            }
            attachLeaf(root, spans, entry.getParentSpanId(), entry);
        }

        root.computeAggLevels();

        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"femsq-auditlog\">").append(STYLE_BLOCK);
        for (Node child : root.children) {
            sb.append(render(child, 0));
        }
        sb.append("</div>");
        return sb.toString();
    }

    private void attachNode(RootNode root, Map<String, SpanNode> spans, String parentSpanId, SpanNode node) {
        if (node == null) {
            return;
        }
        if (parentSpanId == null || parentSpanId.isBlank()) {
            root.children.add(node);
            return;
        }
        SpanNode parent = spans.get(parentSpanId);
        if (parent == null) {
            root.children.add(node);
            return;
        }
        parent.children.add(node);
    }

    private void attachLeaf(RootNode root, Map<String, SpanNode> spans, String parentSpanId, AuditLogEntry entry) {
        if (entry == null) {
            return;
        }
        if (parentSpanId == null || parentSpanId.isBlank()) {
            root.children.add(new LeafNode(entry));
            return;
        }
        SpanNode parent = spans.get(parentSpanId);
        if (parent == null) {
            root.children.add(new LeafNode(entry));
            return;
        }
        parent.children.add(new LeafNode(entry));
    }

    private String render(Node node, int depth) {
        int indentPx = Math.max(0, depth) * INDENT_STEP_PX;
        if (node instanceof LeafNode leaf) {
            AuditLogEntry e = leaf.entry;
            String messageHtml = localizeMessageHtml(e.getMessageHtml());
            return "<div class=\"row " + levelClass(e.getLevel()) + "\" style=\"padding-left:" + indentPx + "px\">" + messageHtml + "</div>";
        }
        SpanNode span = (SpanNode) node;
        AuditLogEntry anchor = span.anchor;
        boolean openDefault = isOpenByDefault(anchor);
        boolean open = openDefault || span.containsWarningOrError;

        String summary = phaseBadge(anchor) + normalizeSummaryHtml(localizeMessageHtml(anchor.getMessageHtml()));
        String summaryClass = "summary " + levelClass(anchor.getLevel()) + " " + phaseClass(anchor);
        StringBuilder sb = new StringBuilder();
        sb.append("<details");
        if (open) {
            sb.append(" open");
        }
        sb.append(" style=\"padding-left:").append(indentPx).append("px\">");
        sb.append("<summary class=\"").append(summaryClass).append("\">").append(summary).append("</summary>");

        for (Node child : span.children) {
            int childDepth = depth + 1;
            if (child instanceof LeafNode leaf && isClosingLine(leaf.entry)) {
                childDepth = depth;
            }
            sb.append(render(child, childDepth));
        }
        sb.append("</details>");
        return sb.toString();
    }

    private boolean isClosingLine(AuditLogEntry entry) {
        if (entry == null || entry.getCode() == null) {
            return false;
        }
        return entry.getCode().endsWith("_END") || entry.getCode().endsWith("_CLOSE");
    }

    private boolean isOpenByDefault(AuditLogEntry anchor) {
        if (anchor == null) {
            return true;
        }
        AuditLogScope scope = anchor.getScope();
        // Contract: AUDIT and FILE are open by default.
        return scope == AuditLogScope.AUDIT || scope == AuditLogScope.FILE;
    }

    private String levelClass(AuditLogLevel level) {
        if (level == null) {
            return "lvl-info";
        }
        return switch (level) {
            case INFO -> "lvl-info";
            case SUCCESS -> "lvl-success";
            case WARNING -> "lvl-warning";
            case ERROR -> "lvl-error";
            case SUMMARY -> "lvl-summary";
        };
    }

    private String phaseClass(AuditLogEntry entry) {
        if (entry == null || entry.getCode() == null) {
            return "";
        }
        if (entry.getCode().endsWith("_START")) {
            return "phase-start";
        }
        if (entry.getCode().endsWith("_END")) {
            return "phase-end";
        }
        return "";
    }

    private String phaseBadge(AuditLogEntry entry) {
        if (entry == null || entry.getCode() == null) {
            return "<span class=\"badge badge-info\">INFO</span>";
        }
        if (entry.getCode().endsWith("_START")) {
            return "<span class=\"badge badge-start\">START</span>";
        }
        if (entry.getCode().endsWith("_END")) {
            return "<span class=\"badge badge-end\">END</span>";
        }
        return "<span class=\"badge badge-info\">" + escape(localizeCode(entry.getCode())) + "</span>";
    }

    private String escape(String value) {
        return value == null ? "" : value.replace("<", "&lt;").replace(">", "&gt;");
    }

    private String normalizeSummaryHtml(String html) {
        if (html == null) {
            return "";
        }
        String trimmed = html.trim();
        if (trimmed.startsWith("<P>") && trimmed.endsWith("</P>")) {
            return trimmed.substring(3, trimmed.length() - 4);
        }
        return trimmed;
    }

    private String localizeCode(String code) {
        if (code == null || code.isBlank()) {
            return "СОБЫТИЕ";
        }
        return switch (code) {
            case "WORKBOOK_OPEN" -> "КНИГА";
            case "SHEET_FOUND" -> "ЛИСТ";
            case "STAGING_ROW_INSERTED" -> "STAGING";
            case "STAGING_STATS" -> "СТАТИСТИКА";
            case "FILE_FS_FOUND" -> "ФАЙЛ";
            case "DIR_FS_EXISTS" -> "ПАПКА";
            default -> "СОБЫТИЕ";
        };
    }

    private String localizeMessageHtml(String html) {
        if (html == null || html.isBlank()) {
            return html;
        }
        String out = html;
        out = out.replace("Reconcile start:", "Начало сверки:");
        out = out.replace("<b>Reconcile</b>:", "<b>Сверка</b>:");
        out = out.replace("counters:", "показатели:");
        out = out.replace("Duration:", "Длительность:");
        out = out.replace("duration=", "длительность=");
        out = out.replace("affectedRows=", "измененоСтрок=");
        out = out.replace("applied=", "применено=");
        out = out.replace("execKey=", "ключВыполнения=");
        out = out.replace("Stage 1 (AllAgents)", "Этап 1 (Все агенты)");
        out = out.replace("Stage 2 (AllAgents): no-op, дополнительные FK/derived вычисления не требуются",
                "Этап 2 (Все агенты): пропуск, дополнительные вычисления внешних ключей/производных не требуются");
        out = out.replace("Staging start:", "Начало загрузки в staging:");
        out = out.replace("Staging end:", "Завершение загрузки в staging:");
        out = out.replace("table=", "таблица=");
        out = out.replace("sheet=", "лист=");
        out = out.replace("inserted=", "добавлено=");
        out = out.replace("updated=", "обновлено=");
        out = out.replace("unchanged=", "безИзменений=");
        out = out.replace("errors=", "ошибок=");
        out = out.replace("dryRun=", "сухойПрогон=");
        out = out.replace("applyRequested=", "применениеЗапрошено=");
        out = out.replace("applyBlocked=", "применениеЗаблокировано=");
        out = out.replace("type=", "тип=");
        out = out.replace("sourceRows=", "строкВИсточнике=");
        out = out.replace("rowRange=", "диапазонСтрок=");
        out = out.replace("skippedNullRow=", "пропущеноПустыхСтрок=");
        out = out.replace("skippedNoBusinessData=", "пропущеноБезБизнесДанных=");
        out = out.replace("skippedMissingRequired=", "пропущеноБезОбязательныхПолей=");
        out = out.replace("rowsWithTruncation=", "строкСУсечением=");
        out = out.replace("truncatedFields=", "усечённыхПолей=");
        out = out.replace("signStats=", "статистикаПоТипам=");
        out = out.replace("таблица=ags.ra_stg_ra", "таблица=staging РА");
        out = out.replace("таблица=ags.ra_stg_cn_prdoc", "таблица=staging CN_PrDoc");
        out = out.replace("таблица=ags.ra_stg_ralp", "таблица=staging RALP");
        out = out.replace("таблица=ags.ra_stg_ralp_sm", "таблица=staging RALP_SM");
        out = out.replace("таблица=ags.ra_stg_agfee", "таблица=staging AgFee");

        // Reconcile counters: переводим служебные ключи в пользовательские подписи.
        out = replaceKey(out, "rcRowsConsidered", "строкИзмененийРассмотрено");
        out = replaceKey(out, "rcParseInvalid", "ошибокПарсингаИзменений");
        out = replaceKey(out, "rcMissingBaseRa", "измененийБезБазовойЗаписи");
        out = replaceKey(out, "rcCategoryNEW", "категорияНовые");
        out = replaceKey(out, "rcCategoryUNCHANGED", "категорияБезИзменений");
        out = replaceKey(out, "rcCategoryCHANGED", "категорияИзменённые");
        out = replaceKey(out, "rcApplyDeltaNew", "кПрименениюНовых");
        out = replaceKey(out, "rcApplyDeltaChanged", "кПрименениюИзменённых");
        out = replaceKey(out, "marker_raStepAlreadyDone", "маркерШагRAУжеВыполнен");
        out = replaceKey(out, "marker_rcStepAlreadyDone", "маркерШагИзмененийУжеВыполнен");
        out = replaceKey(out, "deleteEnabled", "удалениеВключено");
        return out;
    }

    private String replaceKey(String text, String key, String localized) {
        if (text == null || text.isBlank()) {
            return text;
        }
        return text.replace(key + "=", localized + "=");
    }

    private sealed interface Node permits RootNode, SpanNode, LeafNode {
    }

    private static final class RootNode implements Node {
        private final List<Node> children = new ArrayList<>();
        private boolean containsWarningOrError;

        private void computeAggLevels() {
            boolean any = false;
            for (Node child : children) {
                if (child instanceof SpanNode s) {
                    s.computeAggLevels();
                    any = any || s.containsWarningOrError;
                } else if (child instanceof LeafNode l) {
                    any = any || isWarningOrError(l.entry.getLevel());
                }
            }
            containsWarningOrError = any;
        }
    }

    private static final class SpanNode implements Node {
        private final String spanId;
        private final AuditLogEntry anchor;
        private final List<Node> children = new ArrayList<>();
        private boolean containsWarningOrError;

        private SpanNode(String spanId, AuditLogEntry anchor) {
            this.spanId = spanId;
            this.anchor = anchor;
        }

        private void computeAggLevels() {
            boolean any = isWarningOrError(anchor != null ? anchor.getLevel() : null);
            for (Node child : children) {
                if (child instanceof SpanNode s) {
                    s.computeAggLevels();
                    any = any || s.containsWarningOrError;
                } else if (child instanceof LeafNode l) {
                    any = any || isWarningOrError(l.entry.getLevel());
                }
            }
            containsWarningOrError = any;
        }
    }

    private static final class LeafNode implements Node {
        private final AuditLogEntry entry;

        private LeafNode(AuditLogEntry entry) {
            this.entry = entry;
        }
    }

    private static boolean isWarningOrError(AuditLogLevel level) {
        return level == AuditLogLevel.WARNING || level == AuditLogLevel.ERROR;
    }
}
