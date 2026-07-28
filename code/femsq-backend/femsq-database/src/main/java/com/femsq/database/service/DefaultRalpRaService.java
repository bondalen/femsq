package com.femsq.database.service;

import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.RalpRaDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RalpRa;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RalpRaService}: проверка САК; удаление блокируется при наличии Au.
 */
public class DefaultRalpRaService implements RalpRaService {

    private static final Logger log = Logger.getLogger(DefaultRalpRaService.class.getName());

    private final RalpRaDao ralpRaDao;
    private final CstAgPnDao cstAgPnDao;

    public DefaultRalpRaService(RalpRaDao ralpRaDao, CstAgPnDao cstAgPnDao) {
        this.ralpRaDao = Objects.requireNonNull(ralpRaDao, "ralpRaDao");
        this.cstAgPnDao = Objects.requireNonNull(cstAgPnDao, "cstAgPnDao");
    }

    @Override
    public Optional<RalpRa> getById(int ralprKey) {
        return ralpRaDao.findById(ralprKey);
    }

    @Override
    public RalpRa create(RalpRa report) {
        validateNew(report);
        requireCacExists(report.ralprCstAgPn());
        try {
            return ralpRaDao.create(report);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create ralpRa for cstAgPn={0}", report.ralprCstAgPn());
            throw exception;
        }
    }

    @Override
    public RalpRa update(RalpRa report) {
        validateExisting(report);
        requireCacExists(report.ralprCstAgPn());
        try {
            return ralpRaDao.update(report);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update ralpRa {0}", report.ralprKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ralprKey) {
        if (ralpRaDao.hasAus(ralprKey)) {
            throw new IllegalArgumentException(
                    "Нельзя удалить отчёт аренды " + ralprKey + ": есть строки рассмотрения (ags.ralpRaAu). "
                            + "Сначала удалите их.");
        }
        try {
            return ralpRaDao.deleteById(ralprKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete ralpRa {0}", ralprKey);
            throw exception;
        }
    }

    private void validateNew(RalpRa report) {
        Objects.requireNonNull(report, "report");
        if (report.ralprKey() != null) {
            throw new IllegalArgumentException("Новый отчёт аренды не должен содержать идентификатор");
        }
        validateCommon(report);
    }

    private void validateExisting(RalpRa report) {
        Objects.requireNonNull(report, "report");
        if (report.ralprKey() == null) {
            throw new IllegalArgumentException("Для обновления отчёта аренды требуется идентификатор");
        }
        validateCommon(report);
    }

    private void validateCommon(RalpRa report) {
        if (report.ralprNum() == null || report.ralprNum().trim().isEmpty()) {
            throw new IllegalArgumentException("Номер отчёта аренды обязателен");
        }
        if (report.ralprDate() == null) {
            throw new IllegalArgumentException("Дата отчёта аренды обязательна");
        }
        if (report.ralprCstAgPn() == null) {
            throw new IllegalArgumentException("САК (ralprCstAgPn) обязателен");
        }
        if (report.ralprOgSender() == null) {
            throw new IllegalArgumentException("Отправитель обязателен");
        }
    }

    private void requireCacExists(int cstapKey) {
        if (cstAgPnDao.findById(cstapKey).isEmpty()) {
            throw new IllegalArgumentException("САК " + cstapKey + " не найден");
        }
    }
}
