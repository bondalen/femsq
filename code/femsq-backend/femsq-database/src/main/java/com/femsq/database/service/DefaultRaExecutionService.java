package com.femsq.database.service;

import com.femsq.database.dao.RaExecutionDao;
import com.femsq.database.model.RaExecution;
import java.util.Objects;
import java.util.Optional;

/**
 * Реализация {@link RaExecutionService} на базе DAO.
 */
public class DefaultRaExecutionService implements RaExecutionService {

    private final RaExecutionDao raExecutionDao;

    public DefaultRaExecutionService(RaExecutionDao raExecutionDao) {
        this.raExecutionDao = Objects.requireNonNull(raExecutionDao, "raExecutionDao");
    }

    @Override
    public RaExecution startExecution(int auditId, boolean addRa) {
        return raExecutionDao.createRunning(auditId, addRa);
    }

    @Override
    public void completeExecution(int execKey) {
        raExecutionDao.markCompleted(execKey);
    }

    @Override
    public void failExecution(int execKey, String errorMessage) {
        raExecutionDao.markFailed(execKey, errorMessage);
    }

    @Override
    public Optional<RaExecution> getLatestByAuditId(int auditId) {
        return raExecutionDao.findLatestByAuditId(auditId);
    }
}
