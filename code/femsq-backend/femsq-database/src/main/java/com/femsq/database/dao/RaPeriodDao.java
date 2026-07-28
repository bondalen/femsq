package com.femsq.database.dao;

import com.femsq.database.model.RaPeriodLookup;
import java.util.List;

/**
 * DAO lookup периодов {@code ags.ra_period}.
 */
public interface RaPeriodDao {

    /**
     * Все периоды, новые сверху.
     */
    List<RaPeriodLookup> findAllLookups();
}
