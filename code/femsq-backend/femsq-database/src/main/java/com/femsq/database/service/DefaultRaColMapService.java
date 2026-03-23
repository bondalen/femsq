package com.femsq.database.service;

import com.femsq.database.dao.RaColMapDao;
import com.femsq.database.model.RaColMap;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link RaColMapService}.
 */
public class DefaultRaColMapService implements RaColMapService {

    private final RaColMapDao raColMapDao;

    public DefaultRaColMapService(RaColMapDao raColMapDao) {
        this.raColMapDao = Objects.requireNonNull(raColMapDao, "raColMapDao");
    }

    @Override
    public List<RaColMap> getBySheetConfKey(int sheetConfKey) {
        return raColMapDao.findBySheetConfKey(sheetConfKey);
    }
}
