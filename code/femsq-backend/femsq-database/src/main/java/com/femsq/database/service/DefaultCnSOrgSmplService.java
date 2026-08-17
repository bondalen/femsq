package com.femsq.database.service;

import com.femsq.database.dao.CnSDao;
import com.femsq.database.dao.CnSOrgDao;
import com.femsq.database.dao.CnSOrgSmplDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnSOrgIdLookup;
import com.femsq.database.model.CnSOrgSmpl;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CnSOrgSmplService} с каскадным удалением org.
 */
public class DefaultCnSOrgSmplService implements CnSOrgSmplService {

    private static final Logger log = Logger.getLogger(DefaultCnSOrgSmplService.class.getName());

    private final CnSOrgSmplDao smplDao;
    private final CnSOrgDao orgDao;
    private final CnSDao cnSDao;

    public DefaultCnSOrgSmplService(CnSOrgSmplDao smplDao, CnSOrgDao orgDao, CnSDao cnSDao) {
        this.smplDao = Objects.requireNonNull(smplDao, "smplDao");
        this.orgDao = Objects.requireNonNull(orgDao, "orgDao");
        this.cnSDao = Objects.requireNonNull(cnSDao, "cnSDao");
    }

    @Override
    public List<CnSOrgSmpl> getForCnS(int cnSKey) {
        requireSide(cnSKey);
        return smplDao.findByCnSKey(cnSKey);
    }

    @Override
    public List<CnSOrgSmpl> getForCn(int cnKey) {
        return smplDao.findByCnKey(cnKey);
    }

    @Override
    public Optional<CnSOrgSmpl> getById(int csosKey) {
        return smplDao.findById(csosKey);
    }

    @Override
    public List<CnSOrgIdLookup> getOrgIdLookups() {
        return smplDao.findOrgIdLookups();
    }

    @Override
    public CnSOrgSmpl create(CnSOrgSmpl smpl) {
        Objects.requireNonNull(smpl, "smpl");
        if (smpl.csosKey() != null) {
            throw new IllegalArgumentException("Новый smpl не должен содержать идентификатор");
        }
        requireSide(smpl.csosCnS());
        try {
            return smplDao.create(smpl);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create smpl for cn_s={0}", smpl.csosCnS());
            throw exception;
        }
    }

    @Override
    public CnSOrgSmpl update(CnSOrgSmpl smpl) {
        Objects.requireNonNull(smpl, "smpl");
        if (smpl.csosKey() == null) {
            throw new IllegalArgumentException("Для обновления smpl нужен идентификатор");
        }
        requireSide(smpl.csosCnS());
        try {
            return smplDao.update(smpl);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update smpl {0}", smpl.csosKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int csosKey) {
        orgDao.deleteByCsosKey(csosKey);
        try {
            return smplDao.deleteById(csosKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete smpl {0}", csosKey);
            throw exception;
        }
    }

    private void requireSide(int cnSKey) {
        if (cnSDao.findById(cnSKey).isEmpty()) {
            throw new IllegalArgumentException("Сторона cn_s_key=" + cnSKey + " не найдена");
        }
    }
}
