package com.femsq.database.util;

import java.math.BigDecimal;

/**
 * Результат согласования оси Ttl / Wrk / Equ / Oth (или 212 / 195 / 172 / 187).
 *
 * @param kind      класс (OK / QUANTUM_FIX / AUTHOR_FIX / BLOCK / STRUCT)
 * @param ttl       итог после обработки (может быть null)
 * @param wrk       СМР / 195
 * @param equ       оборудование / 172
 * @param oth       прочие / 187
 * @param deltaBefore δ = ttl−parts до fix (после round), знак как у Ttl−parts
 * @param logCode   код для ImpIpg лога ({@code AGG_*})
 */
public record AggAxisResult(
        AggAxisKind kind,
        BigDecimal ttl,
        BigDecimal wrk,
        BigDecimal equ,
        BigDecimal oth,
        BigDecimal deltaBefore,
        String logCode
) {
    public static final String CODE_OK = "AGG_OK";
    public static final String CODE_QUANTUM = "AGG_QUANTUM_FIX";
    public static final String CODE_AUTHOR = "AGG_AUTHOR_FIX";
    public static final String CODE_BLOCK = "AGG_BLOCK";
    public static final String CODE_STRUCT = "AGG_STRUCT";

    /** Можно ли писать строку в домен (не BLOCK). */
    public boolean writable() {
        return kind != AggAxisKind.BLOCK;
    }
}
