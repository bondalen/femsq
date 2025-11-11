package com.femsq.database.service;

import com.femsq.database.dao.OgDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link OgService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultOgService implements OgService {

    private static final Logger log = Logger.getLogger(DefaultOgService.class.getName());

    private final OgDao ogDao;

    public DefaultOgService(OgDao ogDao) {
        this.ogDao = Objects.requireNonNull(ogDao, "ogDao");
    }

    @Override
    public List<Og> getAll() {
        return ogDao.findAll();
    }

    @Override
    public Optional<Og> getById(int ogKey) {
        return ogDao.findById(ogKey);
    }

    @Override
    public Og create(Og organization) {
        validateNewOrganization(organization);
        try {
            return ogDao.create(organization);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create organization {0}", organization.ogName());
            throw exception;
        }
    }

    @Override
    public Og update(Og organization) {
        validateExistingOrganization(organization);
        try {
            return ogDao.update(organization);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update organization {0}", organization.ogKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ogKey) {
        try {
            return ogDao.deleteById(ogKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete organization {0}", ogKey);
            throw exception;
        }
    }

    private void validateNewOrganization(Og organization) {
        Objects.requireNonNull(organization, "organization");
        if (organization.ogKey() != null) {
            throw new IllegalArgumentException("Новая организация не должна содержать идентификатор");
        }
        validateCommonFields(organization);
    }

    private void validateExistingOrganization(Og organization) {
        Objects.requireNonNull(organization, "organization");
        if (organization.ogKey() == null) {
            throw new IllegalArgumentException("Для обновления организации требуется идентификатор");
        }
        validateCommonFields(organization);
    }

    private void validateCommonFields(Og organization) {
        if (isBlank(organization.ogName())) {
            throw new IllegalArgumentException("Краткое наименование организации обязательно");
        }
        if (isBlank(organization.ogOfficialName())) {
            throw new IllegalArgumentException("Официальное наименование организации обязательно");
        }
        if (isBlank(organization.registrationTaxType())) {
            throw new IllegalArgumentException("Код налогового учета обязателен");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
