package com.femsq.database.service;

import com.femsq.database.dao.RaFtDao;
import com.femsq.database.model.RaFt;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link RaFtService} для работы со справочником типов файлов.
 * Простая реализация только для чтения (lookup).
 */
public class DefaultRaFtService implements RaFtService {

    private static final Logger log = Logger.getLogger(DefaultRaFtService.class.getName());

    private final RaFtDao raFtDao;

    public DefaultRaFtService(RaFtDao raFtDao) {
        this.raFtDao = Objects.requireNonNull(raFtDao, "raFtDao");
    }

    @Override
    public Optional<RaFt> getById(int ftKey) {
        log.info(() -> "Getting file type by id: " + ftKey);
        return raFtDao.findById(ftKey);
    }

    @Override
    public List<RaFt> getAll() {
        log.info("Getting all file types");
        return raFtDao.findAll();
    }

    @Override
    public long count() {
        return raFtDao.count();
    }
}
