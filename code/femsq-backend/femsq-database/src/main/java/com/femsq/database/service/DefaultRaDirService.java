package com.femsq.database.service;

import com.femsq.database.dao.RaDirDao;
import com.femsq.database.model.RaDir;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link RaDirService}.
 */
public class DefaultRaDirService implements RaDirService {

    private final RaDirDao raDirDao;

    public DefaultRaDirService(RaDirDao raDirDao) {
        this.raDirDao = Objects.requireNonNull(raDirDao, "raDirDao");
    }

    @Override
    public List<RaDir> getAll() {
        return raDirDao.findAll();
    }
}