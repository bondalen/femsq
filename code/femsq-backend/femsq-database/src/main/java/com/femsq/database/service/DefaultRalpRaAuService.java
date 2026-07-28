package com.femsq.database.service;

import com.femsq.database.dao.RalpRaAuDao;
import com.femsq.database.dao.RalpRaDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RalpRaAu;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RalpRaAuService} с проверкой существования заголовка и статуса 0..3.
 */
public class DefaultRalpRaAuService implements RalpRaAuService {

    private static final Logger log = Logger.getLogger(DefaultRalpRaAuService.class.getName());

    private final RalpRaAuDao ralpRaAuDao;
    private final RalpRaDao ralpRaDao;

    public DefaultRalpRaAuService(RalpRaAuDao ralpRaAuDao, RalpRaDao ralpRaDao) {
        this.ralpRaAuDao = Objects.requireNonNull(ralpRaAuDao, "ralpRaAuDao");
        this.ralpRaDao = Objects.requireNonNull(ralpRaDao, "ralpRaDao");
    }

    @Override
    public Optional<RalpRaAu> getById(int ralpraKey) {
        return ralpRaAuDao.findById(ralpraKey);
    }

    @Override
    public List<RalpRaAu> getForRa(int ralprKey) {
        if (ralpRaDao.findById(ralprKey).isEmpty()) {
            throw new IllegalArgumentException("Отчёт аренды " + ralprKey + " не найден");
        }
        return ralpRaAuDao.findByRa(ralprKey);
    }

    @Override
    public RalpRaAu create(RalpRaAu row) {
        validateNew(row);
        requireRaExists(row.ralpraRa());
        try {
            return ralpRaAuDao.create(row);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create ralpRaAu for ra={0}", row.ralpraRa());
            throw exception;
        }
    }

    @Override
    public RalpRaAu update(RalpRaAu row) {
        validateExisting(row);
        requireRaExists(row.ralpraRa());
        try {
            return ralpRaAuDao.update(row);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update ralpRaAu {0}", row.ralpraKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ralpraKey) {
        try {
            return ralpRaAuDao.deleteById(ralpraKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete ralpRaAu {0}", ralpraKey);
            throw exception;
        }
    }

    private void validateNew(RalpRaAu row) {
        Objects.requireNonNull(row, "row");
        if (row.ralpraKey() != null) {
            throw new IllegalArgumentException("Новая строка Au не должна содержать идентификатор");
        }
        validateCommon(row);
    }

    private void validateExisting(RalpRaAu row) {
        Objects.requireNonNull(row, "row");
        if (row.ralpraKey() == null) {
            throw new IllegalArgumentException("Для обновления строки Au требуется идентификатор");
        }
        validateCommon(row);
    }

    private void validateCommon(RalpRaAu row) {
        if (row.ralpraRa() == null) {
            throw new IllegalArgumentException("Ссылка на отчёт аренды (ralpraRa) обязательна");
        }
        if (row.ralpraStatus() < 0 || row.ralpraStatus() > 3) {
            throw new IllegalArgumentException("Статус Au должен быть в диапазоне 0..3");
        }
    }

    private void requireRaExists(int ralprKey) {
        if (ralpRaDao.findById(ralprKey).isEmpty()) {
            throw new IllegalArgumentException("Отчёт аренды " + ralprKey + " не найден");
        }
    }
}
