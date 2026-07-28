package com.femsq.database.service;

import com.femsq.database.model.RalpRaAuStatusLookup;
import java.util.List;

/**
 * Lookup статусов {@code ralpRaAu} (константы; таблицы в SQL Server нет).
 */
public interface RalpRaAuStatusService {

    /**
     * Возвращает все статусы 0..3.
     *
     * @return неизменяемый список
     */
    List<RalpRaAuStatusLookup> getLookups();
}
