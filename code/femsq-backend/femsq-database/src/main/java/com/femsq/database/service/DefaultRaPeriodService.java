package com.femsq.database.service;

import com.femsq.database.dao.RaPeriodDao;
import com.femsq.database.model.RaPeriodLookup;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link RaPeriodService}.
 */
public class DefaultRaPeriodService implements RaPeriodService {

    private final RaPeriodDao raPeriodDao;

    public DefaultRaPeriodService(RaPeriodDao raPeriodDao) {
        this.raPeriodDao = Objects.requireNonNull(raPeriodDao, "raPeriodDao");
    }

    @Override
    public List<RaPeriodLookup> getLookups() {
        return raPeriodDao.findAllLookups();
    }
}
