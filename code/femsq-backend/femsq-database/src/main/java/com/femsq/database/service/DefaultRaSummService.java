package com.femsq.database.service;

import com.femsq.database.dao.RaReportDao;
import com.femsq.database.dao.RaSummDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaSumm;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaSummService}.
 */
public class DefaultRaSummService implements RaSummService {

    private static final Logger log = Logger.getLogger(DefaultRaSummService.class.getName());

    private final RaSummDao raSummDao;
    private final RaReportDao raReportDao;

    public DefaultRaSummService(RaSummDao raSummDao, RaReportDao raReportDao) {
        this.raSummDao = Objects.requireNonNull(raSummDao, "raSummDao");
        this.raReportDao = Objects.requireNonNull(raReportDao, "raReportDao");
    }

    @Override
    public Optional<RaSumm> getById(int rasKey) {
        return raSummDao.findById(rasKey);
    }

    @Override
    public List<RaSumm> getForRa(int raKey) {
        requireRaExists(raKey);
        return raSummDao.findByRa(raKey);
    }

    @Override
    public RaSumm create(RaSumm summ) {
        validateNew(summ);
        requireRaExists(summ.rasRa());
        try {
            return raSummDao.create(summ);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create ra_summ for ra={0}", summ.rasRa());
            throw exception;
        }
    }

    @Override
    public RaSumm update(RaSumm summ) {
        validateExisting(summ);
        requireRaExists(summ.rasRa());
        try {
            return raSummDao.update(summ);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update ra_summ {0}", summ.rasKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int rasKey) {
        try {
            return raSummDao.deleteById(rasKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete ra_summ {0}", rasKey);
            throw exception;
        }
    }

    private void validateNew(RaSumm summ) {
        Objects.requireNonNull(summ, "summ");
        if (summ.rasKey() != null) {
            throw new IllegalArgumentException("Новая версия сумм не должна содержать идентификатор");
        }
        if (summ.rasRa() == null) {
            throw new IllegalArgumentException("Ключ отчёта (ras_ra) обязателен");
        }
    }

    private void validateExisting(RaSumm summ) {
        Objects.requireNonNull(summ, "summ");
        if (summ.rasKey() == null) {
            throw new IllegalArgumentException("Для обновления сумм требуется идентификатор");
        }
        if (summ.rasRa() == null) {
            throw new IllegalArgumentException("Ключ отчёта (ras_ra) обязателен");
        }
    }

    private void requireRaExists(int raKey) {
        if (raReportDao.findById(raKey).isEmpty()) {
            throw new IllegalArgumentException("Отчёт " + raKey + " не найден");
        }
    }
}
