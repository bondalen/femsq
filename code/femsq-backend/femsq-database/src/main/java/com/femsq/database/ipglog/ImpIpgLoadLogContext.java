package com.femsq.database.ipglog;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Контекст структурированного лога загрузки годовой ИП (C2 §3.5.4).
 *
 * <p>Тонкая копия модели {@code AuditExecutionContext} (femsq-web) без зависимости от web-модуля:
 * записи → дерево span-ов → HTML с {@code <details>}/{@code <summary>} и классами
 * {@code .femsq-auditlog} / {@code lvl-*} / {@code badge}, совместимыми с frontend
 * {@code audit-log.css} / {@code audit-log-surface}.
 *
 * <p>Не потокобезопасен: один контекст — одна операция (parse / reconcile / apply).
 * Накопительный лог по сессии получается слиянием через {@link #buildHtmlLog(String)}.
 */
public class ImpIpgLoadLogContext {

    /** Отступ вложенности (px на уровень) — как в «Ходе ревизии». */
    private static final int INDENT_STEP_PX = 16;

    /** Предохранитель размера накопленного HTML тела (символов). */
    static final int MAX_PREVIOUS_BODY_CHARS = 1_000_000;

    private static final String ROOT_OPEN = "<div class=\"femsq-auditlog\">";
    private static final String ROOT_CLOSE = "</div>";

    /** Минимальный набор стилей (цвета/плотность — во frontend {@code audit-log.css}). */
    static final String STYLE_BLOCK = """
            <style>
              .femsq-auditlog details {
                margin: 0;
                border-left: 1px solid rgba(120, 139, 166, 0.35);
                margin-left: 1px;
              }
              .femsq-auditlog summary { list-style: none; }
              .femsq-auditlog summary::-webkit-details-marker { display: none; }
              .femsq-auditlog summary::marker { content: ""; }
              .femsq-auditlog .row { margin: 0; padding: 0 4px; line-height: 1.15; }
              .femsq-auditlog .summary { padding: 0 4px; border-radius: 4px; cursor: pointer; user-select: none; line-height: 1.15; }
              .femsq-auditlog p, .femsq-auditlog P { margin: 0; padding: 0; line-height: 1.15; }
              .femsq-auditlog .badge { display: inline-block; font-size: 10px; line-height: 12px; padding: 0 4px; border-radius: 999px; margin-right: 4px; vertical-align: baseline; }
              .femsq-auditlog details > summary .badge-start {
                font-size: 0;
                min-width: 1.1em;
                text-align: center;
              }
              .femsq-auditlog details > summary .badge-start::before {
                content: "+";
                font-size: 10px;
                line-height: 12px;
              }
              .femsq-auditlog details[open] > summary .badge-start::before {
                content: "\u2212";
              }
              .femsq-auditlog .phase-start { font-weight: 650; }
              .femsq-auditlog .phase-end { font-weight: 650; opacity: 0.95; }
            </style>
            """;

    private static final String HTML_PREFIX = ROOT_OPEN + STYLE_BLOCK;

    private final long loadKey;
    private final List<ImpIpgLoadLogEntry> entries = new ArrayList<>();
    private final AtomicLong spanSeq = new AtomicLong(0);
    private final List<String> spanStack = new ArrayList<>();

    /**
     * @param loadKey ключ сессии {@code impIpgLoad} (для диагностики)
     */
    public ImpIpgLoadLogContext(long loadKey) {
        this.loadKey = loadKey;
    }

    public long getLoadKey() {
        return loadKey;
    }

    /** Записи в хронологическом порядке (только чтение). */
    public List<ImpIpgLoadLogEntry> getEntries() {
        return Collections.unmodifiableList(entries);
    }

    /** {@code true}, если есть хотя бы одна запись уровня ERROR. */
    public boolean hasErrors() {
        return entries.stream().anyMatch(e -> e.level() == ImpIpgLoadLogLevel.ERROR);
    }

    /** Экранирует текст для вставки в HTML-сообщение. */
    public static String esc(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    /**
     * Добавляет листовую запись в текущий span (или в корень).
     */
    public void append(
            ImpIpgLoadLogLevel level,
            ImpIpgLoadLogScope scope,
            String code,
            String messageHtml,
            Map<String, String> meta) {
        entries.add(new ImpIpgLoadLogEntry(
                Instant.now(), level, scope, null, currentSpanId(), code, messageHtml, meta));
    }

    /** Краткая форма {@link #append} без метаданных. */
    public void append(
            ImpIpgLoadLogLevel level, ImpIpgLoadLogScope scope, String code, String messageHtml) {
        append(level, scope, code, messageHtml, null);
    }

    /**
     * Открывает вложенный блок и делает его текущим.
     *
     * @return идентификатор span-а для {@link #endSpan}
     */
    public String beginSpan(
            ImpIpgLoadLogLevel level,
            ImpIpgLoadLogScope scope,
            String code,
            String messageHtml,
            Map<String, String> meta) {
        String spanId = "s" + spanSeq.incrementAndGet();
        entries.add(new ImpIpgLoadLogEntry(
                Instant.now(), level, scope, spanId, currentSpanId(), code, messageHtml, meta));
        spanStack.add(spanId);
        return spanId;
    }

    /** Краткая форма {@link #beginSpan} без метаданных. */
    public String beginSpan(
            ImpIpgLoadLogLevel level, ImpIpgLoadLogScope scope, String code, String messageHtml) {
        return beginSpan(level, scope, code, messageHtml, null);
    }

    /**
     * Закрывает блок: добавляет закрывающую строку (код {@code *_END}/{@code *_CLOSE}) внутрь него.
     * При {@code spanId == null} ведёт себя как {@link #append}.
     */
    public void endSpan(
            String spanId,
            ImpIpgLoadLogLevel level,
            ImpIpgLoadLogScope scope,
            String code,
            String messageHtml,
            Map<String, String> meta) {
        if (spanId == null) {
            append(level, scope, code, messageHtml, meta);
            return;
        }
        entries.add(new ImpIpgLoadLogEntry(
                Instant.now(), level, scope, null, spanId, code, messageHtml, meta));
        popSpan(spanId);
    }

    /** Краткая форма {@link #endSpan} без метаданных. */
    public void endSpan(
            String spanId,
            ImpIpgLoadLogLevel level,
            ImpIpgLoadLogScope scope,
            String code,
            String messageHtml) {
        endSpan(spanId, level, scope, code, messageHtml, null);
    }

    private String currentSpanId() {
        return spanStack.isEmpty() ? null : spanStack.get(spanStack.size() - 1);
    }

    private void popSpan(String expected) {
        for (int i = spanStack.size() - 1; i >= 0; i--) {
            if (expected.equals(spanStack.get(i))) {
                spanStack.remove(i);
                return;
            }
        }
    }

    /**
     * HTML только этой операции (прямой хронологический порядок).
     */
    public String buildHtmlLog() {
        return buildHtmlLog(null);
    }

    /**
     * Накопительный HTML: тело ранее сохранённого лога сессии + записи текущей операции.
     *
     * @param previousHtml {@code iilResults} из БД или null
     */
    public String buildHtmlLog(String previousHtml) {
        String previousBody = extractBody(previousHtml);
        StringBuilder sb = new StringBuilder(HTML_PREFIX);
        if (previousBody.length() > MAX_PREVIOUS_BODY_CHARS) {
            sb.append("<div class=\"row lvl-warning\">")
                    .append("Ранее накопленный лог усечён (превышен предел размера)</div>");
        } else {
            sb.append(previousBody);
        }
        sb.append(renderBody()).append(ROOT_CLOSE);
        return sb.toString();
    }

    /**
     * Извлекает тело ранее собранного лога (после {@code </style>} и до закрывающего {@code </div>}).
     * Устойчиво к изменению набора стилей между версиями.
     */
    static String extractBody(String html) {
        if (html == null || html.isBlank() || !html.startsWith(ROOT_OPEN) || !html.endsWith(ROOT_CLOSE)) {
            return "";
        }
        int styleEnd = html.indexOf("</style>");
        if (styleEnd < 0) {
            return "";
        }
        int start = styleEnd + "</style>".length();
        while (start < html.length() && (html.charAt(start) == '\n' || html.charAt(start) == '\r')) {
            start++;
        }
        int end = html.length() - ROOT_CLOSE.length();
        return start >= end ? "" : html.substring(start, end);
    }

    private String renderBody() {
        Map<String, SpanNode> spans = new HashMap<>();
        for (ImpIpgLoadLogEntry entry : entries) {
            if (entry.spanId() != null && !entry.spanId().isBlank()) {
                spans.put(entry.spanId(), new SpanNode(entry));
            }
        }
        RootNode root = new RootNode();
        for (ImpIpgLoadLogEntry entry : entries) {
            if (entry.spanId() != null && !entry.spanId().isBlank()) {
                attach(root, spans, entry.parentSpanId(), spans.get(entry.spanId()));
            } else {
                attach(root, spans, entry.parentSpanId(), new LeafNode(entry));
            }
        }
        for (Node child : root.children) {
            if (child instanceof SpanNode s) {
                s.computeAggLevels();
            }
        }
        StringBuilder sb = new StringBuilder();
        for (Node child : root.children) {
            sb.append(render(child, 0));
        }
        return sb.toString();
    }

    private static void attach(RootNode root, Map<String, SpanNode> spans, String parentSpanId, Node node) {
        if (node == null) {
            return;
        }
        SpanNode parent = (parentSpanId == null || parentSpanId.isBlank()) ? null : spans.get(parentSpanId);
        if (parent == null) {
            root.children.add(node);
        } else {
            parent.children.add(node);
        }
    }

    private String render(Node node, int depth) {
        int indentPx = Math.max(0, depth) * INDENT_STEP_PX;
        if (node instanceof LeafNode leaf) {
            ImpIpgLoadLogEntry e = leaf.entry;
            return "<div class=\"row " + levelClass(e.level()) + "\" style=\"padding-left:" + indentPx + "px\">"
                    + nullToEmpty(e.messageHtml()) + "</div>";
        }
        SpanNode span = (SpanNode) node;
        ImpIpgLoadLogEntry anchor = span.anchor;
        boolean open = isOpenByDefault(anchor) || span.containsWarningOrError;
        String summary = phaseBadge(anchor) + nullToEmpty(anchor.messageHtml()).trim();
        String summaryClass = "summary " + levelClass(anchor.level()) + " " + phaseClass(anchor);
        StringBuilder sb = new StringBuilder("<details");
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

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static boolean isClosingLine(ImpIpgLoadLogEntry entry) {
        String code = entry == null ? null : entry.code();
        return code != null
                && (code.endsWith("_END") || code.endsWith("_CLOSE") || "IPG_LOAD_ERROR".equals(code));
    }

    /** LOAD и FILE раскрыты по умолчанию (как AUDIT/FILE у ревизий). */
    private static boolean isOpenByDefault(ImpIpgLoadLogEntry anchor) {
        if (anchor == null) {
            return true;
        }
        return anchor.scope() == ImpIpgLoadLogScope.LOAD || anchor.scope() == ImpIpgLoadLogScope.FILE;
    }

    private static String levelClass(ImpIpgLoadLogLevel level) {
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

    private static String phaseClass(ImpIpgLoadLogEntry entry) {
        String code = entry == null ? null : entry.code();
        if (code == null) {
            return "";
        }
        if (code.endsWith("_START")) {
            return "phase-start";
        }
        if (code.endsWith("_END")) {
            return "phase-end";
        }
        return "";
    }

    private static String phaseBadge(ImpIpgLoadLogEntry entry) {
        String code = entry == null ? null : entry.code();
        if (code == null) {
            return "<span class=\"badge badge-info\">INFO</span>";
        }
        if (code.endsWith("_START")) {
            return "<span class=\"badge badge-start\">+</span>";
        }
        if (code.endsWith("_END")) {
            return "<span class=\"badge badge-end\">END</span>";
        }
        return "<span class=\"badge badge-info\">" + esc(localizeCode(code)) + "</span>";
    }

    private static String localizeCode(String code) {
        return switch (code) {
            case "WORKBOOK_OPEN" -> "КНИГА";
            case "PARSE_START" -> "РАЗБОР";
            case "RECONCILE_START" -> "СВЕРКА";
            case "GATE_START" -> "ГЕЙТ";
            case "STI_INHERIT_START" -> "STI";
            case "SH_RESOLVE_START" -> "SH";
            case "APPLY_START" -> "ПРИМЕНЕНИЕ";
            default -> "СОБЫТИЕ";
        };
    }

    private sealed interface Node permits RootNode, SpanNode, LeafNode {
    }

    private static final class RootNode implements Node {
        private final List<Node> children = new ArrayList<>();
    }

    private static final class SpanNode implements Node {
        private final ImpIpgLoadLogEntry anchor;
        private final List<Node> children = new ArrayList<>();
        private boolean containsWarningOrError;

        private SpanNode(ImpIpgLoadLogEntry anchor) {
            this.anchor = anchor;
        }

        private void computeAggLevels() {
            boolean any = isWarningOrError(anchor.level());
            for (Node child : children) {
                if (child instanceof SpanNode s) {
                    s.computeAggLevels();
                    any = any || s.containsWarningOrError;
                } else if (child instanceof LeafNode l) {
                    any = any || isWarningOrError(l.entry.level());
                }
            }
            containsWarningOrError = any;
        }
    }

    private static final class LeafNode implements Node {
        private final ImpIpgLoadLogEntry entry;

        private LeafNode(ImpIpgLoadLogEntry entry) {
            this.entry = entry;
        }
    }

    private static boolean isWarningOrError(ImpIpgLoadLogLevel level) {
        return level == ImpIpgLoadLogLevel.WARNING || level == ImpIpgLoadLogLevel.ERROR;
    }
}
