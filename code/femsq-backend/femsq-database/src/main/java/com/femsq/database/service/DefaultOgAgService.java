package com.femsq.database.service;

import com.femsq.database.dao.OgAgDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import com.femsq.database.model.OgAg;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link OgAgService} с проверками на существование базовой организации.
 */
public class DefaultOgAgService implements OgAgService {

    private static final Logger log = Logger.getLogger(DefaultOgAgService.class.getName());

    private final OgAgDao ogAgDao;
    private final OgDao ogDao;

    public DefaultOgAgService(OgAgDao ogAgDao, OgDao ogDao) {
        this.ogAgDao = Objects.requireNonNull(ogAgDao, "ogAgDao");
        this.ogDao = Objects.requireNonNull(ogDao, "ogDao");
    }

    @Override
    public List<OgAg> getAll() {
        return ogAgDao.findAll();
    }

    @Override
    public List<OgAg> getForOrganization(int ogKey) {
        requireOrganizationExists(ogKey);
        return ogAgDao.findByOrganization(ogKey);
    }

    @Override
    public Optional<OgAg> getById(int ogAgKey) {
        return ogAgDao.findById(ogAgKey);
    }

    @Override
    public OgAg create(OgAg agent) {
        validateNewAgent(agent);
        requireOrganizationExists(agent.organizationKey());
        try {
            return ogAgDao.create(agent);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create ogAg for organization {0}", agent.organizationKey());
            throw exception;
        }
    }

    @Override
    public OgAg update(OgAg agent) {
        validateExistingAgent(agent);
        requireOrganizationExists(agent.organizationKey());
        try {
            return ogAgDao.update(agent);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update ogAg {0}", agent.ogAgKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ogAgKey) {
        try {
            return ogAgDao.deleteById(ogAgKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete ogAg {0}", ogAgKey);
            throw exception;
        }
    }

    private void validateNewAgent(OgAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.ogAgKey() != null) {
            throw new IllegalArgumentException("Новый агент не должен иметь идентификатор");
        }
        validateCommon(agent);
    }

    private void validateExistingAgent(OgAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.ogAgKey() == null) {
            throw new IllegalArgumentException("Для обновления агентской организации требуется идентификатор");
        }
        validateCommon(agent);
    }

    private void validateCommon(OgAg agent) {
        if (isBlank(agent.code())) {
            throw new IllegalArgumentException("Код агентской организации обязателен");
        }
        if (agent.organizationKey() == null) {
            throw new IllegalArgumentException("Не указан идентификатор организации");
        }
    }

    private void requireOrganizationExists(int ogKey) {
        Optional<Og> organization = ogDao.findById(ogKey);
        if (organization.isEmpty()) {
            throw new IllegalArgumentException("Организация " + ogKey + " не найдена");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
