package com.femsq.database.service;

import com.femsq.database.dao.OgAgCsDao;
import com.femsq.database.model.OgAgCs;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link OgAgCsService}.
 */
public class DefaultOgAgCsService implements OgAgCsService {

    private final OgAgCsDao ogAgCsDao;

    public DefaultOgAgCsService(OgAgCsDao ogAgCsDao) {
        this.ogAgCsDao = Objects.requireNonNull(ogAgCsDao, "ogAgCsDao");
    }

    @Override
    public List<OgAgCs> getAll() {
        return ogAgCsDao.findAll();
    }
}
