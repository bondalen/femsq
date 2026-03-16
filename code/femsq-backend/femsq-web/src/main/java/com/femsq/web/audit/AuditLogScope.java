package com.femsq.web.audit;

/**
 * Область (контекст) записи лога.
 */
public enum AuditLogScope {
    AUDIT,
    DIRECTORY,
    FILE,
    SHEET,
    SUMMARY
}
