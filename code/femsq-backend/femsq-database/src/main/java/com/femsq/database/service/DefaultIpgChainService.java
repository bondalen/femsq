package com.femsq.database.service;

import com.femsq.database.dao.IpgChainDao;
import com.femsq.database.dao.IpgChainRelationDao;
import com.femsq.database.model.IpgChain;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/** Реализация {@link IpgChainService} на основе DAO. */
public class DefaultIpgChainService implements IpgChainService {

    private static final Logger log = Logger.getLogger(DefaultIpgChainService.class.getName());

    private final IpgChainDao ipgChainDao;
    private final IpgChainRelationDao relationDao;

    public DefaultIpgChainService(IpgChainDao ipgChainDao, IpgChainRelationDao relationDao) {
        this.ipgChainDao = Objects.requireNonNull(ipgChainDao, "ipgChainDao");
        this.relationDao = Objects.requireNonNull(relationDao, "relationDao");
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
    public List<IpgChain> getAll(
            int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter) {
        return ipgChainDao.findAll(page, size, sortField, sortDirection, nameFilter, yearFilter);
    }

    @Override
    public long count(String nameFilter, Integer yearFilter) {
        return ipgChainDao.count(nameFilter, yearFilter);
    }

    @Override
    public IpgChain create(String name) {
        log.info(() -> "create ipgCh name=" + name);
        return ipgChainDao.insert(name);
    }

    @Override
    public IpgChain update(int chainKey, String name) {
        if (ipgChainDao.findById(chainKey).isEmpty()) {
            throw new IllegalArgumentException("Цепочка не найдена: " + chainKey);
        }
        return ipgChainDao.update(chainKey, name);
    }

    @Override
    public boolean delete(int chainKey) {
        if (ipgChainDao.findById(chainKey).isEmpty()) {
            return false;
        }
        int removed = relationDao.deleteByChain(chainKey);
        log.info(() -> "delete ipgCh " + chainKey + ": cleared relations=" + removed);
        return ipgChainDao.delete(chainKey);
    }
}
