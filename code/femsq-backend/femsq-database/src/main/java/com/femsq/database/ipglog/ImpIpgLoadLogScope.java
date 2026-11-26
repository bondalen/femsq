package com.femsq.database.ipglog;

/**
 * Область (фаза) записи лога загрузки годовой ИП.
 */
public enum ImpIpgLoadLogScope {
    LOAD,
    FILE,
    PARSE,
    RECONCILE,
    GATE,
    STI,
    SH,
    APPLY,
    SUMMARY
}
