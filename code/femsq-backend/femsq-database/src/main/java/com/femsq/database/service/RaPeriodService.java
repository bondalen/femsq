package com.femsq.database.service;

import com.femsq.database.model.RaPeriodLookup;
import java.util.List;

/**
 * Сервис lookup периодов {@code ags.ra_period}.
 */
public interface RaPeriodService {

    List<RaPeriodLookup> getLookups();
}
