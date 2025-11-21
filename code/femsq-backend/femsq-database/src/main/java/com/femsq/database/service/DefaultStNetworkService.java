package com.femsq.database.service;

import com.femsq.database.dao.StNetworkDao;
import com.femsq.database.model.StNetwork;
import java.util.List;
import java.util.Objects;

/** Реализация {@link StNetworkService}. */
public class DefaultStNetworkService implements StNetworkService {

    private final StNetworkDao stNetworkDao;

    public DefaultStNetworkService(StNetworkDao stNetworkDao) {
        this.stNetworkDao = Objects.requireNonNull(stNetworkDao, "stNetworkDao");
    }

    @Override
    public List<StNetwork> getAll() {
        return stNetworkDao.findAllOrdered();
    }
}
