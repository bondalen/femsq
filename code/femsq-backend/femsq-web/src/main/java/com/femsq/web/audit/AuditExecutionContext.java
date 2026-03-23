package com.femsq.web.audit;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Контекст выполнения ревизии (первичный аналог ra_a в VBA).
 *
 * На этом этапе содержит только минимально необходимую информацию для
 * оркестровки и накопления лога в структурированном виде.
 */
public class AuditExecutionContext {

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
            entries.add(entry);
            lastUpdatedAt = entry.getTimestamp();
        }
    }

    /**
     * Формирует HTML-документ для сохранения в adt_results.
     *
     * На первом этапе используется простой конкат: сообщения берутся
     * в обратном порядке (новые сверху), чтобы пользователь сразу видел
     * последние события длительной ревизии.
     */
    public String buildHtmlLog() {
        StringBuilder sb = new StringBuilder();
        for (int i = entries.size() - 1; i >= 0; i--) {
            sb.append(entries.get(i).getMessageHtml());
        }
        return sb.toString();
    }
}
