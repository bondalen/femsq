package com.femsq.database.ipglog;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;

/**
 * Одна запись структурированного лога загрузки ИП.
 *
 * <p>Запись с {@code spanId != null} открывает вложенный блок ({@code <details>});
 * запись с {@code parentSpanId} — вложена в блок; без обоих — корневая строка.
 *
 * @param timestamp     время события
 * @param level         уровень
 * @param scope         область
 * @param spanId        идентификатор открываемого блока (или null)
 * @param parentSpanId  родительский блок (или null)
 * @param code          код события (spine: IPG_LOAD_START, APPLY_ROW_ERR, …)
 * @param messageHtml   HTML-текст (экранирование — на стороне вызывающего, см. {@link ImpIpgLoadLogContext#esc})
 * @param meta          метаданные (в HTML не выводятся; для диагностики)
 */
public record ImpIpgLoadLogEntry(
        Instant timestamp,
        ImpIpgLoadLogLevel level,
        ImpIpgLoadLogScope scope,
        String spanId,
        String parentSpanId,
        String code,
        String messageHtml,
        Map<String, String> meta) {

    public ImpIpgLoadLogEntry {
        Objects.requireNonNull(timestamp, "timestamp");
        meta = meta == null ? Map.of() : Map.copyOf(meta);
    }
}
