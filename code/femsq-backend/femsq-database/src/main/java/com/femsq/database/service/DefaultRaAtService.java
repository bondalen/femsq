package com.femsq.database.service;

import com.femsq.database.dao.RaAtDao;
import com.femsq.database.model.RaAt;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * Реализация {@link RaAtService}.
 */
public class DefaultRaAtService implements RaAtService {

    private final RaAtDao raAtDao;

    public DefaultRaAtService(RaAtDao raAtDao) {
        this.raAtDao = Objects.requireNonNull(raAtDao, "raAtDao");
    }

    @Override
    public List<RaAt> getAll() {
        return raAtDao.findAll();
    }

    @Override
    public Optional<RaAt> getById(int atKey) {
        return raAtDao.findById(atKey);
    }
}