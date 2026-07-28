package com.femsq.database.service;

import com.femsq.database.dao.CstAgDao;
import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.CstAgPnCode;
import com.femsq.database.model.CstAgPnSiteLookup;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CstAgPnService} с проверкой существования {@code cstAg}.
 */
public class DefaultCstAgPnService implements CstAgPnService {

    private static final Logger log = Logger.getLogger(DefaultCstAgPnService.class.getName());

    private final CstAgPnDao cstAgPnDao;
    private final CstAgDao cstAgDao;

    public DefaultCstAgPnService(CstAgPnDao cstAgPnDao, CstAgDao cstAgDao) {
        this.cstAgPnDao = Objects.requireNonNull(cstAgPnDao, "cstAgPnDao");
        this.cstAgDao = Objects.requireNonNull(cstAgDao, "cstAgDao");
    }

    @Override
    public List<CstAgPn> getForCstAg(int cstaKey) {
        requireCstAgExists(cstaKey);
        return cstAgPnDao.findByCstAg(cstaKey);
    }

    @Override
    public Optional<CstAgPn> getById(int cstapKey) {
        return cstAgPnDao.findById(cstapKey);
    }

    @Override
    public List<CstAgPnCode> getCodes(String codeFilter) {
        return cstAgPnDao.findCodes(codeFilter);
    }

    @Override
    public List<CstAgPnSiteLookup> getSiteLookups(int cstKey) {
        return cstAgPnDao.findSiteLookups(cstKey);
    }

    @Override
    public CstAgPn create(CstAgPn point) {
        validateNew(point);
        requireCstAgExists(point.cstapCsta());
        try {
            return cstAgPnDao.create(point);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create cstAgPn for csta={0}", point.cstapCsta());
            throw exception;
        }
    }

    @Override
    public CstAgPn update(CstAgPn point) {
        validateExisting(point);
        requireCstAgExists(point.cstapCsta());
        try {
            return cstAgPnDao.update(point);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update cstAgPn {0}", point.cstapKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cstapKey) {
        try {
            return cstAgPnDao.deleteById(cstapKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete cstAgPn {0}", cstapKey);
            throw exception;
        }
    }

    private void validateNew(CstAgPn point) {
        Objects.requireNonNull(point, "point");
        if (point.cstapKey() != null) {
            throw new IllegalArgumentException("Новый САК не должен содержать идентификатор");
        }
        validateCommon(point);
    }

    private void validateExisting(CstAgPn point) {
        Objects.requireNonNull(point, "point");
        if (point.cstapKey() == null) {
            throw new IllegalArgumentException("Для обновления САК требуется идентификатор");
        }
        validateCommon(point);
    }

    private void validateCommon(CstAgPn point) {
        if (point.cstapCsta() == null) {
            throw new IllegalArgumentException("Не указан агент стройки (cstapCsta)");
        }
        if (point.cstapIpgPnN() == null || point.cstapIpgPnN().trim().isEmpty()) {
            throw new IllegalArgumentException("Код пункта ИП / САК обязателен");
        }
    }

    private void requireCstAgExists(int cstaKey) {
        if (cstAgDao.findById(cstaKey).isEmpty()) {
            throw new IllegalArgumentException("Агент стройки " + cstaKey + " не найден");
        }
    }
}
