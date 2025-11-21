package com.femsq.database.service;

import com.femsq.database.dao.IpgChainRelationDao;
import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;
import java.util.Objects;

/** Реализация {@link IpgChainRelationService}. */
public class DefaultIpgChainRelationService implements IpgChainRelationService {

    private final IpgChainRelationDao relationDao;

    public DefaultIpgChainRelationService(IpgChainRelationDao relationDao) {
        this.relationDao = Objects.requireNonNull(relationDao, "relationDao");
    }

    @Override
    public List<IpgChainRelation> getByChain(int chainKey) {
        return relationDao.findByChain(chainKey);
    }

    @Override
    public List<IpgChainRelation> getByChains(Collection<Integer> chainKeys) {
        return relationDao.findByChains(chainKeys);
    }

    @Override
    public List<IpgChainRelation> getAll() {
        return relationDao.findAll();
    }
}
