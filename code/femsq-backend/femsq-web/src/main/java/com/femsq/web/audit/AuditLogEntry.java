package com.femsq.web.audit;

import java.time.Instant;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * Одна запись лога выполнения ревизии.
 *
 * На этом этапе хранит минимальный набор данных, достаточный
 * для формирования HTML-представления в поле adt_results.
 */
public class AuditLogEntry {

    private final Instant timestamp;
    private final AuditLogLevel level;
    private final AuditLogScope scope;
    /**
     * Идентификатор span (блока), к которому относится запись.
     * Если значение задано, то запись является "якорем" span и может использоваться
     * для построения вложенности при рендеринге HTML.
     */
    private final String spanId;
    /**
     * Родительский span (вложенность). Может быть null для корневых событий.
     */
    private final String parentSpanId;
    private final String code;
    private final String messageHtml;
    private final Map<String, String> meta;

    public AuditLogEntry(Instant timestamp,
                         AuditLogLevel level,
                         AuditLogScope scope,
                         String code,
                         String messageHtml,
                         Map<String, String> meta) {
        this(timestamp, level, scope, null, null, code, messageHtml, meta);
    }

    public AuditLogEntry(Instant timestamp,
                         AuditLogLevel level,
                         AuditLogScope scope,
                         String spanId,
                         String parentSpanId,
                         String code,
                         String messageHtml,
                         Map<String, String> meta) {
        this.timestamp = timestamp;
        this.level = level;
        this.scope = scope;
        this.spanId = spanId;
        this.parentSpanId = parentSpanId;
        this.code = code;
        this.messageHtml = messageHtml == null ? "" : messageHtml;
        this.meta = meta == null ? Collections.emptyMap() : Collections.unmodifiableMap(new HashMap<>(meta));
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public AuditLogLevel getLevel() {
        return level;
    }

    public AuditLogScope getScope() {
        return scope;
    }

    public String getSpanId() {
        return spanId;
    }

    public String getParentSpanId() {
        return parentSpanId;
    }

    public String getCode() {
        return code;
    }

    public String getMessageHtml() {
        return messageHtml;
    }

    public Map<String, String> getMeta() {
        return meta;
    }
}
