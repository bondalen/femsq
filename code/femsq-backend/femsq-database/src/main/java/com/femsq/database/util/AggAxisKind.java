package com.femsq.database.util;

/**
 * Класс расхождения по оси агрегации (ADR 012 / R-MONEY-AGG).
 */
public enum AggAxisKind {
    /** Сходимость после round. */
    OK,
    /** Квант/ulp: автоfix Ttl авторитет, δ → Oth. */
    QUANTUM_FIX,
    /** Ошибка автора: части → пересчёт Ttl. */
    AUTHOR_FIX,
    /** Грубый брак: строку не писать без override. */
    BLOCK,
    /** Нет разбивки при ненулевом Ttl (или наоборот) — не выдумывать части. */
    STRUCT
}
