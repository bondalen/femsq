package com.femsq.database.dao;

import com.femsq.database.model.RaExecution;
import java.util.Optional;

/**
 * DAO для таблицы {@code ags.ra_execution}.
 */
public interface RaExecutionDao {

    /**
     * Создаёт запись о старте выполнения ревизии.
     */
    RaExecution createRunning(int auditId, boolean addRa);

    /**
     * Завершает выполнение как успешное.
     */
    void markCompleted(int execKey);

    /**
     * Завершает выполнение с ошибкой.
     */
    void markFailed(int execKey, String errorMessage);

    /**
     * Возвращает последнюю запись выполнения по ревизии.
     */
    Optional<RaExecution> findLatestByAuditId(int auditId);
}
