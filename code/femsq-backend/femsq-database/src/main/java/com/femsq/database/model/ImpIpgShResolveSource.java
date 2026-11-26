package com.femsq.database.model;

/**
 * Источник назначения {@code ipgpSh} (§3.2.3 / notes O1 §5.2).
 */
public enum ImpIpgShResolveSource {
    /** Единственная (или взятая из списка) схема предшествующей ИП. */
    FROM_PREV,
    /**
     * Хвост без однозначного prev: сейчас {@code ipgpSh=2} (Агентская).
     * Имя {@code DEFAULT_4} сохранено в API/GraphQL (источник «default»), значение ключа — не 4.
     */
    DEFAULT_4,
    /** Добор из свободных ключей {@code ipgSh} при N&gt;1 вхождений кода. */
    FREE_POOL
}
