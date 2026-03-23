package com.femsq.database.service;

import com.femsq.database.model.RaExecution;
import java.util.Optional;

/**
 * Сервис работы с выполнением ревизий ({@code ags.ra_execution}).
 */
public interface RaExecutionService {

    /**
     * Создаёт запись о старте ревизии.
     */
    RaExecution startExecution(int auditId, boolean addRa);

    /**
     * Помечает запуск как успешный.
     */
    void completeExecution(int execKey);

    /**
     * Помечает запуск как завершившийся ошибкой.
     */
    void failExecution(int execKey, String errorMessage);

    /**
     * Возвращает последний статус выполнения по ревизии.
     */
    Optional<RaExecution> getLatestByAuditId(int auditId);
}
