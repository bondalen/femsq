package com.femsq.database.service;

import com.femsq.database.dao.CnDao;
import com.femsq.database.model.Cn;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link CnService}.
 */
public class DefaultCnService implements CnService {

    private static final Logger log = Logger.getLogger(DefaultCnService.class.getName());

    private final CnDao cnDao;

    public DefaultCnService(CnDao cnDao) {
        this.cnDao = Objects.requireNonNull(cnDao, "cnDao");
    }

    @Override
    public Optional<Cn> getById(int cnKey) {
        log.fine(() -> "CnService.getById cnKey=" + cnKey);
        return cnDao.findById(cnKey);
    }

    @Override
    public Cn update(Cn cn) {
        Objects.requireNonNull(cn, "cn");
        log.info(() -> "CnService.update cnKey=" + cn.cnKey());
        return cnDao.update(cn);
    }
}
