package com.femsq.database.service;

import com.femsq.database.dao.CstDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Cst;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CstService} с базовой валидацией.
 */
public class DefaultCstService implements CstService {

    private static final Logger log = Logger.getLogger(DefaultCstService.class.getName());

    private final CstDao cstDao;

    public DefaultCstService(CstDao cstDao) {
        this.cstDao = Objects.requireNonNull(cstDao, "cstDao");
    }

    @Override
    public List<Cst> getAll() {
        return cstDao.findAll();
    }

    @Override
    public Optional<Cst> getById(int cstKey) {
        return cstDao.findById(cstKey);
    }

    @Override
    public Cst create(Cst site) {
        validateNew(site);
        try {
            return cstDao.create(site);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create construction site {0}", site.cstName());
            throw exception;
        }
    }

    @Override
    public Cst update(Cst site) {
        validateExisting(site);
        try {
            return cstDao.update(site);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update construction site {0}", site.cstKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cstKey) {
        try {
            return cstDao.deleteById(cstKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete construction site {0}", cstKey);
            throw exception;
        }
    }

    private void validateNew(Cst site) {
        Objects.requireNonNull(site, "site");
        if (site.cstKey() != null) {
            throw new IllegalArgumentException("Новая стройка не должна содержать идентификатор");
        }
        validateCommon(site);
    }

    private void validateExisting(Cst site) {
        Objects.requireNonNull(site, "site");
        if (site.cstKey() == null) {
            throw new IllegalArgumentException("Для обновления стройки требуется идентификатор");
        }
        validateCommon(site);
    }

    private void validateCommon(Cst site) {
        if (site.cstName() == null || site.cstName().trim().isEmpty()) {
            throw new IllegalArgumentException("Наименование стройки обязательно");
        }
    }
}
