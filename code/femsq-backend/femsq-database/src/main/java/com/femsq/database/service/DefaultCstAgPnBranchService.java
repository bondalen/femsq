package com.femsq.database.service;

import com.femsq.database.dao.CstAgPnBranchDao;
import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPnBranch;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CstAgPnBranchService} с проверкой САК и организации-филиала.
 */
public class DefaultCstAgPnBranchService implements CstAgPnBranchService {

    private static final Logger log = Logger.getLogger(DefaultCstAgPnBranchService.class.getName());

    private final CstAgPnBranchDao cstAgPnBranchDao;
    private final CstAgPnDao cstAgPnDao;
    private final OgDao ogDao;

    public DefaultCstAgPnBranchService(CstAgPnBranchDao cstAgPnBranchDao, CstAgPnDao cstAgPnDao, OgDao ogDao) {
        this.cstAgPnBranchDao = Objects.requireNonNull(cstAgPnBranchDao, "cstAgPnBranchDao");
        this.cstAgPnDao = Objects.requireNonNull(cstAgPnDao, "cstAgPnDao");
        this.ogDao = Objects.requireNonNull(ogDao, "ogDao");
    }

    @Override
    public List<CstAgPnBranch> getForCstAgPn(int cstapKey) {
        requireCstAgPnExists(cstapKey);
        return cstAgPnBranchDao.findByCstAgPn(cstapKey);
    }

    @Override
    public Optional<CstAgPnBranch> getById(int cstapbKey) {
        return cstAgPnBranchDao.findById(cstapbKey);
    }

    @Override
    public CstAgPnBranch create(CstAgPnBranch branch) {
        validateNew(branch);
        requireCstAgPnExists(branch.cstapbCstAgPn());
        requireOgExists(branch.cstapbBranch());
        try {
            return cstAgPnBranchDao.create(branch);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create cstAgPnBranch for cstap={0}", branch.cstapbCstAgPn());
            throw exception;
        }
    }

    @Override
    public CstAgPnBranch update(CstAgPnBranch branch) {
        validateExisting(branch);
        requireCstAgPnExists(branch.cstapbCstAgPn());
        requireOgExists(branch.cstapbBranch());
        try {
            return cstAgPnBranchDao.update(branch);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update cstAgPnBranch {0}", branch.cstapbKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cstapbKey) {
        try {
            return cstAgPnBranchDao.deleteById(cstapbKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete cstAgPnBranch {0}", cstapbKey);
            throw exception;
        }
    }

    private void validateNew(CstAgPnBranch branch) {
        Objects.requireNonNull(branch, "branch");
        if (branch.cstapbKey() != null) {
            throw new IllegalArgumentException("Новый филиал САК не должен содержать идентификатор");
        }
        validateCommon(branch);
    }

    private void validateExisting(CstAgPnBranch branch) {
        Objects.requireNonNull(branch, "branch");
        if (branch.cstapbKey() == null) {
            throw new IllegalArgumentException("Для обновления филиала САК требуется идентификатор");
        }
        validateCommon(branch);
    }

    private void validateCommon(CstAgPnBranch branch) {
        if (branch.cstapbCstAgPn() == null) {
            throw new IllegalArgumentException("Не указан САК (cstapbCstAgPn)");
        }
        if (branch.cstapbBranch() == null) {
            throw new IllegalArgumentException("Не указан филиал (cstapbBranch)");
        }
    }

    private void requireCstAgPnExists(int cstapKey) {
        if (cstAgPnDao.findById(cstapKey).isEmpty()) {
            throw new IllegalArgumentException("САК " + cstapKey + " не найден");
        }
    }

    private void requireOgExists(int ogKey) {
        if (ogDao.findById(ogKey).isEmpty()) {
            throw new IllegalArgumentException("Организация-филиал " + ogKey + " не найдена");
        }
    }
}
