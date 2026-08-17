package com.femsq.database.service;

import com.femsq.database.dao.CnDao;
import com.femsq.database.dao.CnSDao;
import com.femsq.database.dao.CnSOrgDao;
import com.femsq.database.dao.CnSOrgSmplDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnS;
import com.femsq.database.model.CnSOrgSmpl;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CnSService} с каскадным удалением.
 */
public class DefaultCnSService implements CnSService {

    private static final Logger log = Logger.getLogger(DefaultCnSService.class.getName());

    private final CnSDao cnSDao;
    private final CnSOrgSmplDao smplDao;
    private final CnSOrgDao orgDao;
    private final CnDao cnDao;

    public DefaultCnSService(CnSDao cnSDao, CnSOrgSmplDao smplDao, CnSOrgDao orgDao, CnDao cnDao) {
        this.cnSDao = Objects.requireNonNull(cnSDao, "cnSDao");
        this.smplDao = Objects.requireNonNull(smplDao, "smplDao");
        this.orgDao = Objects.requireNonNull(orgDao, "orgDao");
        this.cnDao = Objects.requireNonNull(cnDao, "cnDao");
    }

    @Override
    public List<CnS> getForCn(int cnKey) {
        requireCn(cnKey);
        return cnSDao.findByCnKey(cnKey);
    }

    @Override
    public Optional<CnS> getById(int cnSKey) {
        return cnSDao.findById(cnSKey);
    }

    @Override
    public CnS create(CnS side) {
        Objects.requireNonNull(side, "side");
        if (side.cnSKey() != null) {
            throw new IllegalArgumentException("Новая сторона не должна содержать идентификатор");
        }
        if (side.cnSType() != 1 && side.cnSType() != 2) {
            throw new IllegalArgumentException("cn_s_type должен быть 1 (заказчик) или 2 (исполнитель)");
        }
        requireCn(side.cnKey());
        boolean typeExists = cnSDao.findByCnKey(side.cnKey()).stream()
                .anyMatch(existing -> existing.cnSType() == side.cnSType());
        if (typeExists) {
            throw new IllegalArgumentException(
                    "У договора cn_key=" + side.cnKey() + " уже есть сторона типа " + side.cnSType());
        }
        try {
            return cnSDao.create(side);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create cn_s for cn={0}", side.cnKey());
            throw exception;
        }
    }

    @Override
    public CnS update(CnS side) {
        Objects.requireNonNull(side, "side");
        if (side.cnSKey() == null) {
            throw new IllegalArgumentException("Для обновления стороны нужен идентификатор");
        }
        if (side.cnSType() != 1 && side.cnSType() != 2) {
            throw new IllegalArgumentException("cn_s_type должен быть 1 (заказчик) или 2 (исполнитель)");
        }
        requireCn(side.cnKey());
        boolean conflict = cnSDao.findByCnKey(side.cnKey()).stream()
                .anyMatch(existing -> existing.cnSType() == side.cnSType()
                        && !Objects.equals(existing.cnSKey(), side.cnSKey()));
        if (conflict) {
            throw new IllegalArgumentException(
                    "У договора cn_key=" + side.cnKey() + " уже есть сторона типа " + side.cnSType());
        }
        try {
            return cnSDao.update(side);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update cn_s {0}", side.cnSKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int cnSKey) {
        List<CnSOrgSmpl> smpls = smplDao.findByCnSKey(cnSKey);
        for (CnSOrgSmpl smpl : smpls) {
            orgDao.deleteByCsosKey(smpl.csosKey());
            smplDao.deleteById(smpl.csosKey());
        }
        try {
            return cnSDao.deleteById(cnSKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete cn_s {0}", cnSKey);
            throw exception;
        }
    }

    private void requireCn(int cnKey) {
        if (cnDao.findById(cnKey).isEmpty()) {
            throw new IllegalArgumentException("Договор cn_key=" + cnKey + " не найден");
        }
    }
}
