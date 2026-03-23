package com.femsq.database.model;

import java.time.LocalDateTime;

/**
 * Представляет запуск ревизии (таблица {@code ags.ra_execution}).
 *
 * @param execKey      идентификатор запуска
 * @param execAdtKey   идентификатор ревизии
 * @param execStatus   статус выполнения (RUNNING/COMPLETED/FAILED)
 * @param execAddRa    флаг добавления РА
 * @param execStarted  дата и время старта
 * @param execFinished дата и время завершения
 * @param execError    текст ошибки (если есть)
 */
public record RaExecution(
        Integer execKey,
        Integer execAdtKey,
        String execStatus,
        Boolean execAddRa,
        LocalDateTime execStarted,
        LocalDateTime execFinished,
        String execError
) {
}
