package com.femsq.database.service;

import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.RaReportDao;
import com.femsq.database.dao.RaSummDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaReport;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaReportService} с проверками САК и блокировкой удаления при наличии изменений.
 */
public class DefaultRaReportService implements RaReportService {

    private static final Logger log = Logger.getLogger(DefaultRaReportService.class.getName());

    private final RaReportDao raReportDao;
    private final RaSummDao raSummDao;
    private final CstAgPnDao cstAgPnDao;

    public DefaultRaReportService(RaReportDao raReportDao, RaSummDao raSummDao, CstAgPnDao cstAgPnDao) {
        this.raReportDao = Objects.requireNonNull(raReportDao, "raReportDao");
        this.raSummDao = Objects.requireNonNull(raSummDao, "raSummDao");
        this.cstAgPnDao = Objects.requireNonNull(cstAgPnDao, "cstAgPnDao");
    }

    @Override
    public Optional<RaReport> getById(int raKey) {
        return raReportDao.findById(raKey);
    }

    @Override
    public RaReport create(RaReport report) {
        validateNew(report);
        requireCacExists(report.raCac());
        try {
            return raReportDao.create(report);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create ra for cac={0}", report.raCac());
            throw exception;
        }
    }

    @Override
    public RaReport update(RaReport report) {
        validateExisting(report);
        requireCacExists(report.raCac());
        try {
            return raReportDao.update(report);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update ra {0}", report.raKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int raKey) {
        if (raReportDao.hasChanges(raKey)) {
            throw new IllegalArgumentException(
                    "Нельзя удалить отчёт " + raKey + ": есть связанные изменения (ags.ra_change)");
        }
        try {
            raSummDao.deleteByRa(raKey);
            return raReportDao.deleteById(raKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete ra {0}", raKey);
            throw exception;
        }
    }

    private void validateNew(RaReport report) {
        Objects.requireNonNull(report, "report");
        if (report.raKey() != null) {
            throw new IllegalArgumentException("Новый отчёт не должен содержать идентификатор");
        }
        validateCommon(report);
    }

    private void validateExisting(RaReport report) {
        Objects.requireNonNull(report, "report");
        if (report.raKey() == null) {
            throw new IllegalArgumentException("Для обновления отчёта требуется идентификатор");
        }
        validateCommon(report);
    }

    private void validateCommon(RaReport report) {
        if (report.raNum() == null || report.raNum().trim().isEmpty()) {
            throw new IllegalArgumentException("Номер отчёта обязателен");
        }
        if (report.raCac() == null) {
            throw new IllegalArgumentException("САК (ra_cac) обязателен");
        }
        if (report.raType() == null || report.raType().trim().isEmpty()) {
            throw new IllegalArgumentException("Тип отчёта обязателен");
        }
        if (report.raPeriod() == null) {
            throw new IllegalArgumentException("Период отчёта обязателен");
        }
        if (report.raOrgSender() == null) {
            throw new IllegalArgumentException("Отправитель обязателен");
        }
    }

    private void requireCacExists(int cstapKey) {
        if (cstAgPnDao.findById(cstapKey).isEmpty()) {
            throw new IllegalArgumentException("САК " + cstapKey + " не найден");
        }
    }
}
