package com.femsq.database.service;

import com.femsq.database.dao.RalpRaCstListDao;
import com.femsq.database.model.RalpRaCstListEntry;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link RalpRaCstListService}.
 */
public class DefaultRalpRaCstListService implements RalpRaCstListService {

    private final RalpRaCstListDao ralpRaCstListDao;

    public DefaultRalpRaCstListService(RalpRaCstListDao ralpRaCstListDao) {
        this.ralpRaCstListDao = Objects.requireNonNull(ralpRaCstListDao, "ralpRaCstListDao");
    }

    @Override
    public List<RalpRaCstListEntry> getForCst(int cstKey) {
        return ralpRaCstListDao.findByCst(cstKey);
    }
}
