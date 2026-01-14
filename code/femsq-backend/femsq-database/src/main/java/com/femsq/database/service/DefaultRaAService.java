package com.femsq.database.service;

import com.femsq.database.dao.RaADao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaA;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaAService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultRaAService implements RaAService {

    private static final Logger log = Logger.getLogger(DefaultRaAService.class.getName());

    private final RaADao raADao;

    public DefaultRaAService(RaADao raADao) {
        this.raADao = Objects.requireNonNull(raADao, "raADao");
    }

    @Override
    public List<RaA> getAll() {
        return raADao.findAll();
    }

    @Override
    public Optional<RaA> getById(long adtKey) {
        return raADao.findById(adtKey);
    }

    @Override
    public RaA create(RaA raA) {
        validateNewAudit(raA);
        try {
            return raADao.create(raA);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create audit {0}", raA.adtName());
            throw exception;
        }
    }

    @Override
    public RaA update(RaA raA) {
        validateExistingAudit(raA);
        try {
            return raADao.update(raA);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update audit {0}", raA.adtKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(long adtKey) {
        try {
            return raADao.deleteById(adtKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete audit {0}", adtKey);
            throw exception;
        }
    }

    private void validateNewAudit(RaA raA) {
        Objects.requireNonNull(raA, "raA");
        if (raA.adtKey() != null) {
            throw new IllegalArgumentException("Новая ревизия не должна содержать идентификатор");
        }
        validateCommonFields(raA);
    }

    private void validateExistingAudit(RaA raA) {
        Objects.requireNonNull(raA, "raA");
        if (raA.adtKey() == null) {
            throw new IllegalArgumentException("Для обновления ревизии требуется идентификатор");
        }
        validateCommonFields(raA);
    }

    private void validateCommonFields(RaA raA) {
        if (isBlank(raA.adtName())) {
            throw new IllegalArgumentException("Название ревизии обязательно");
        }
        if (raA.adtDir() == null) {
            throw new IllegalArgumentException("Директория обязательна");
        }
        if (raA.adtType() == null) {
            throw new IllegalArgumentException("Тип ревизии обязателен");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}