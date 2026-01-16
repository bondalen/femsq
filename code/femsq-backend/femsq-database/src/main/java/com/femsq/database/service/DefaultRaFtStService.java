package com.femsq.database.service;

import com.femsq.database.dao.RaFtStDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSt;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaFtStService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultRaFtStService implements RaFtStService {

    private static final Logger log = Logger.getLogger(DefaultRaFtStService.class.getName());

    private final RaFtStDao raFtStDao;

    public DefaultRaFtStService(RaFtStDao raFtStDao) {
        this.raFtStDao = Objects.requireNonNull(raFtStDao, "raFtStDao");
    }

    @Override
    public List<RaFtSt> getAll() {
        return raFtStDao.findAll();
    }

    @Override
    public Optional<RaFtSt> getById(int stKey) {
        return raFtStDao.findById(stKey);
    }

    @Override
    public RaFtSt create(RaFtSt raFtSt) {
        validateNewFileSourceType(raFtSt);
        try {
            return raFtStDao.create(raFtSt);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create file source type {0}", raFtSt.stName());
            throw exception;
        }
    }

    @Override
    public RaFtSt update(RaFtSt raFtSt) {
        validateExistingFileSourceType(raFtSt);
        try {
            return raFtStDao.update(raFtSt);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update file source type {0}", raFtSt.stKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int stKey) {
        try {
            return raFtStDao.deleteById(stKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete file source type {0}", stKey);
            throw exception;
        }
    }

    private void validateNewFileSourceType(RaFtSt raFtSt) {
        Objects.requireNonNull(raFtSt, "raFtSt");
        if (raFtSt.stKey() != null) {
            throw new IllegalArgumentException("Новый тип источника не должен содержать идентификатор");
        }
        validateCommonFields(raFtSt);
    }

    private void validateExistingFileSourceType(RaFtSt raFtSt) {
        Objects.requireNonNull(raFtSt, "raFtSt");
        if (raFtSt.stKey() == null) {
            throw new IllegalArgumentException("Для обновления типа источника требуется идентификатор");
        }
        validateCommonFields(raFtSt);
    }

    private void validateCommonFields(RaFtSt raFtSt) {
        if (isBlank(raFtSt.stName())) {
            throw new IllegalArgumentException("Название типа источника обязательно");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
