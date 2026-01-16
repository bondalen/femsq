package com.femsq.database.service;

import com.femsq.database.dao.RaFtSDao;
import com.femsq.database.dao.RaFtSnDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSn;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaFtSnService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultRaFtSnService implements RaFtSnService {

    private static final Logger log = Logger.getLogger(DefaultRaFtSnService.class.getName());

    private final RaFtSnDao raFtSnDao;
    private final RaFtSDao raFtSDao;

    public DefaultRaFtSnService(RaFtSnDao raFtSnDao, RaFtSDao raFtSDao) {
        this.raFtSnDao = Objects.requireNonNull(raFtSnDao, "raFtSnDao");
        this.raFtSDao = Objects.requireNonNull(raFtSDao, "raFtSDao");
    }

    @Override
    public List<RaFtSn> getAll() {
        return raFtSnDao.findAll();
    }

    @Override
    public Optional<RaFtSn> getById(int ftsnKey) {
        return raFtSnDao.findById(ftsnKey);
    }

    @Override
    public List<RaFtSn> getByFtS(int ftSKey) {
        return raFtSnDao.findByFtS(ftSKey);
    }

    @Override
    public RaFtSn create(RaFtSn raFtSn) {
        validateNewFileSourceName(raFtSn);
        try {
            return raFtSnDao.create(raFtSn);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create file source name {0}", raFtSn.ftsnName());
            throw exception;
        }
    }

    @Override
    public RaFtSn update(RaFtSn raFtSn) {
        validateExistingFileSourceName(raFtSn);
        try {
            return raFtSnDao.update(raFtSn);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update file source name {0}", raFtSn.ftsnKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ftsnKey) {
        try {
            return raFtSnDao.deleteById(ftsnKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete file source name {0}", ftsnKey);
            throw exception;
        }
    }

    private void validateNewFileSourceName(RaFtSn raFtSn) {
        Objects.requireNonNull(raFtSn, "raFtSn");
        if (raFtSn.ftsnKey() != null) {
            throw new IllegalArgumentException("Новое имя источника не должно содержать идентификатор");
        }
        validateCommonFields(raFtSn);
        
        // Проверка существования источника/листа
        if (raFtSDao.findById(raFtSn.ftsnFtS()).isEmpty()) {
            throw new IllegalArgumentException("Источник с идентификатором " + raFtSn.ftsnFtS() + " не найден");
        }
    }

    private void validateExistingFileSourceName(RaFtSn raFtSn) {
        Objects.requireNonNull(raFtSn, "raFtSn");
        if (raFtSn.ftsnKey() == null) {
            throw new IllegalArgumentException("Для обновления имени источника требуется идентификатор");
        }
        validateCommonFields(raFtSn);
        
        // Проверка существования источника/листа
        if (raFtSDao.findById(raFtSn.ftsnFtS()).isEmpty()) {
            throw new IllegalArgumentException("Источник с идентификатором " + raFtSn.ftsnFtS() + " не найден");
        }
    }

    private void validateCommonFields(RaFtSn raFtSn) {
        if (isBlank(raFtSn.ftsnName())) {
            throw new IllegalArgumentException("Имя источника обязательно");
        }
        if (raFtSn.ftsnFtS() == null) {
            throw new IllegalArgumentException("Идентификатор источника/листа обязателен");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
