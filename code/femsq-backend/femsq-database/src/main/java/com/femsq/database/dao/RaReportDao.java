package com.femsq.database.dao;

import com.femsq.database.model.RaReport;
import java.util.Optional;

/**
 * DAO таблицы {@code ags.ra}.
 */
public interface RaReportDao {

    /**
     * Находит отчёт по ключу.
     */
    Optional<RaReport> findById(int raKey);

    /**
     * Создаёт отчёт ({@code ra_created} выставляет СУБД).
     */
    RaReport create(RaReport report);

    /**
     * Обновляет отчёт.
     */
    RaReport update(RaReport report);

    /**
     * Удаляет отчёт по ключу (суммы должны быть удалены заранее).
     */
    boolean deleteById(int raKey);

    /**
     * @return {@code true}, если у отчёта есть строки {@code ags.ra_change}
     */
    boolean hasChanges(int raKey);
}
