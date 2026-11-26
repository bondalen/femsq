package com.femsq.database.ipglog;

/**
 * Коды событий spine лога загрузки годовой ИП (C2 §3.5.4).
 *
 * <p>Суффиксы {@code _START} / {@code _END} / {@code _CLOSE} управляют отображением блока
 * (значок «+/−», закрывающая строка на уровне заголовка), как у «Хода ревизии».
 */
public final class ImpIpgLoadLogCodes {

    public static final String IPG_LOAD_START = "IPG_LOAD_START";
    public static final String IPG_LOAD_END = "IPG_LOAD_END";
    public static final String IPG_LOAD_ERROR = "IPG_LOAD_ERROR";

    public static final String FILE_RESOLVE_OK = "FILE_RESOLVE_OK";
    public static final String FILE_MISSING = "FILE_MISSING";
    public static final String WORKBOOK_OPEN = "WORKBOOK_OPEN";
    public static final String WORKBOOK_CLOSE = "WORKBOOK_CLOSE";

    public static final String PARSE_START = "PARSE_START";
    public static final String PARSE_SHEET = "PARSE_SHEET";
    public static final String PARSE_STATS = "PARSE_STATS";
    public static final String PARSE_STAGING_WRITTEN = "PARSE_STAGING_WRITTEN";
    public static final String PARSE_END = "PARSE_END";

    public static final String RECONCILE_START = "RECONCILE_START";
    public static final String RECONCILE_ROW_OPEN = "RECONCILE_ROW_OPEN";
    public static final String RECONCILE_STATS = "RECONCILE_STATS";
    public static final String RECONCILE_END = "RECONCILE_END";

    public static final String GATE_START = "GATE_START";
    public static final String GATE_SOFT_OPEN = "GATE_SOFT_OPEN";
    public static final String GATE_OK = "GATE_OK";
    public static final String GATE_END = "GATE_END";

    public static final String STI_INHERIT_START = "STI_INHERIT_START";
    public static final String STI_INHERIT_STATS = "STI_INHERIT_STATS";
    public static final String STI_INHERIT_HOLE = "STI_INHERIT_HOLE";
    public static final String STI_INHERIT_END = "STI_INHERIT_END";

    public static final String SH_RESOLVE_START = "SH_RESOLVE_START";
    public static final String SH_RESOLVE_STATS = "SH_RESOLVE_STATS";
    public static final String SH_RESOLVE_END = "SH_RESOLVE_END";

    public static final String APPLY_START = "APPLY_START";
    public static final String APPLY_ROW_ERR = "APPLY_ROW_ERR";
    public static final String APPLY_SKIP_ALREADY = "APPLY_SKIP_ALREADY";
    public static final String APPLY_STATS = "APPLY_STATS";
    public static final String APPLY_END = "APPLY_END";

    /** R-MONEY-AGG (ADR 012): ось Sm Ttl=Wrk+Equ+Oth. */
    public static final String AGG_OK = "AGG_OK";
    public static final String AGG_QUANTUM_FIX = "AGG_QUANTUM_FIX";
    public static final String AGG_AUTHOR_FIX = "AGG_AUTHOR_FIX";
    public static final String AGG_STRUCT = "AGG_STRUCT";
    public static final String AGG_BLOCK = "AGG_BLOCK";

    private ImpIpgLoadLogCodes() {
    }
}
