package com.femsq.database.service;

import com.femsq.database.dao.CnSOrgDao;
import com.femsq.database.dao.CnSOrgSmplDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnSOrg;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CnSOrgService}.
 */
public class DefaultCnSOrgService implements CnSOrgService {

    private static final Logger log = Logger.getLogger(DefaultCnSOrgService.class.getName());

    private final CnSOrgDao orgDao;
    private final CnSOrgSmplDao smplDao;

    public DefaultCnSOrgService(CnSOrgDao orgDao, CnSOrgSmplDao smplDao) {
        this.orgDao = Objects.requireNonNull(orgDao, "orgDao");
        this.smplDao = Objects.requireNonNull(smplDao, "smplDao");
    }

    @Override
    public List<CnSOrg> getForSmpl(int csosKey) {
        requireSmpl(csosKey);
        return orgDao.findByCsosKey(csosKey);
    }

    @Override
    public List<CnSOrg> getForCn(int cnKey) {
        return orgDao.findByCnKey(cnKey);
    }

    @Override
    public Optional<CnSOrg> getById(int cnSOrgKey) {
        return orgDao.findById(cnSOrgKey);
    }

    @Override
    public CnSOrg create(CnSOrg org) {
        Objects.requireNonNull(org, "org");
        if (org.cnSOrgKey() != null) {
            throw new IllegalArgumentException("Новый cn_s_org не должен содержать идентификатор");
        }
        requireSmpl(org.csoCnSOrgSmpl());
        try {
            return orgDao.create(org);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create cn_s_org for smpl={0}", org.csoCnSOrgSmpl());
            throw exception;
        }
    }

    @Override
    public CnSOrg update(CnSOrg org) {
        Objects.requireNonNull(org, "org");
        if (org.cnSOrgKey() == null) {
            throw new IllegalArgumentException("Для обновления cn_s_org нужен идентификатор");
        }
        requireSmpl(org.csoCnSOrgSmpl());
        try {
            return orgDao.update(org);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update cn_s_org {0}", org.cnSOrgKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cnSOrgKey) {
        try {
            return orgDao.deleteById(cnSOrgKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete cn_s_org {0}", cnSOrgKey);
            throw exception;
        }
    }

    private void requireSmpl(int csosKey) {
        if (smplDao.findById(csosKey).isEmpty()) {
            throw new IllegalArgumentException("smpl csosKey=" + csosKey + " не найден");
        }
    }
}
