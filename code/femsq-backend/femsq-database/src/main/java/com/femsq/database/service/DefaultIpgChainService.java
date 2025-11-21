package com.femsq.database.service;

import com.femsq.database.dao.IpgChainDao;
import com.femsq.database.model.IpgChain;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/** Реализация {@link IpgChainService} на основе {@link IpgChainDao}. */
public class DefaultIpgChainService implements IpgChainService {

    private final IpgChainDao ipgChainDao;

    public DefaultIpgChainService(IpgChainDao ipgChainDao) {
        this.ipgChainDao = Objects.requireNonNull(ipgChainDao, "ipgChainDao");
    }

    @Override
    public Optional<IpgChain> getById(int chainKey) {
        return ipgChainDao.findById(chainKey);
    }

    @Override
    public List<IpgChain> getAll() {
        return ipgChainDao.findAll();
    }

    @Override
    public List<IpgChain> getAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter) {
        return ipgChainDao.findAll(page, size, sortField, sortDirection, nameFilter, yearFilter);
    }

    @Override
    public long count(String nameFilter, Integer yearFilter) {
        return ipgChainDao.count(nameFilter, yearFilter);
    }
}
