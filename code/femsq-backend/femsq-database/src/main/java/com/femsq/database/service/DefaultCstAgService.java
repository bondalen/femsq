package com.femsq.database.service;

import com.femsq.database.dao.CstAgDao;
import com.femsq.database.dao.CstDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAg;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CstAgService} с проверкой существования стройки.
 */
public class DefaultCstAgService implements CstAgService {

    private static final Logger log = Logger.getLogger(DefaultCstAgService.class.getName());
    private static final int DEFAULT_INVESTOR = 7;

    private final CstAgDao cstAgDao;
    private final CstDao cstDao;

    public DefaultCstAgService(CstAgDao cstAgDao, CstDao cstDao) {
        this.cstAgDao = Objects.requireNonNull(cstAgDao, "cstAgDao");
        this.cstDao = Objects.requireNonNull(cstDao, "cstDao");
    }

    @Override
    public List<CstAg> getForCst(int cstKey) {
        requireCstExists(cstKey);
        return cstAgDao.findByCst(cstKey);
    }

    @Override
    public Optional<CstAg> getById(int cstaKey) {
        return cstAgDao.findById(cstaKey);
    }

    @Override
    public CstAg create(CstAg agent) {
        validateNew(agent);
        requireCstExists(agent.cstaCst());
        CstAg toCreate = agent.cstaInvestor() == null
                ? new CstAg(null, agent.cstaAg(), agent.cstaCst(), agent.cstaOidOld(), DEFAULT_INVESTOR, null)
                : agent;
        try {
            return cstAgDao.create(toCreate);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create cstAg for cst={0}", agent.cstaCst());
            throw exception;
        }
    }

    @Override
    public CstAg update(CstAg agent) {
        validateExisting(agent);
        requireCstExists(agent.cstaCst());
        try {
            return cstAgDao.update(agent);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update cstAg {0}", agent.cstaKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cstaKey) {
        try {
            return cstAgDao.deleteById(cstaKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete cstAg {0}", cstaKey);
            throw exception;
        }
    }

    private void validateNew(CstAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.cstaKey() != null) {
            throw new IllegalArgumentException("Новый агент стройки не должен содержать идентификатор");
        }
        validateCommon(agent);
    }

    private void validateExisting(CstAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.cstaKey() == null) {
            throw new IllegalArgumentException("Для обновления агента стройки требуется идентификатор");
        }
        validateCommon(agent);
    }

    private void validateCommon(CstAg agent) {
        if (agent.cstaAg() == null) {
            throw new IllegalArgumentException("Не указан агент (cstaAg)");
        }
        if (agent.cstaCst() == null) {
            throw new IllegalArgumentException("Не указана стройка (cstaCst)");
        }
    }

    private void requireCstExists(int cstKey) {
        if (cstDao.findById(cstKey).isEmpty()) {
            throw new IllegalArgumentException("Стройка " + cstKey + " не найдена");
        }
    }
}
