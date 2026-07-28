package com.femsq.database.service;

import com.femsq.database.dao.CstRaListDao;
import com.femsq.database.model.CstRaListEntry;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * Реализация {@link CstRaListService}.
 */
public class DefaultCstRaListService implements CstRaListService {

    private static final Logger log = Logger.getLogger(DefaultCstRaListService.class.getName());

    private final CstRaListDao cstRaListDao;

    public DefaultCstRaListService(CstRaListDao cstRaListDao) {
        this.cstRaListDao = Objects.requireNonNull(cstRaListDao, "cstRaListDao");
    }

    @Override
    public List<CstRaListEntry> getForCst(int cstKey) {
        log.fine(() -> "getForCst cstKey=" + cstKey);
        return cstRaListDao.findByCst(cstKey);
    }
}
