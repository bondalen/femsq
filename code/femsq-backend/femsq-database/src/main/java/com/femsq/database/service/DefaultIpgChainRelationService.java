package com.femsq.database.service;

import com.femsq.database.dao.IpgChainDao;
import com.femsq.database.dao.IpgChainRelationDao;
import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;

/** Реализация {@link IpgChainRelationService}. */
public class DefaultIpgChainRelationService implements IpgChainRelationService {

    private static final Logger log = Logger.getLogger(DefaultIpgChainRelationService.class.getName());

    private final IpgChainRelationDao relationDao;
    private final IpgChainDao chainDao;

    public DefaultIpgChainRelationService(IpgChainRelationDao relationDao, IpgChainDao chainDao) {
        this.relationDao = Objects.requireNonNull(relationDao, "relationDao");
        this.chainDao = Objects.requireNonNull(chainDao, "chainDao");
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

    @Override
    public IpgChainRelation add(int chainKey, int investmentProgramKey, Integer planGroupKey) {
        if (chainDao.findById(chainKey).isEmpty()) {
            throw new IllegalArgumentException("Цепочка не найдена: " + chainKey);
        }
        relationDao.findByChainAndIpg(chainKey, investmentProgramKey).ifPresent(existing -> {
            throw new IllegalArgumentException(
                    "ИП " + investmentProgramKey + " уже в цепочке " + chainKey
                            + " (ipgcrKey=" + existing.relationKey() + ")");
        });
        log.info(() -> "addIpgToChain chain=" + chainKey + " ipg=" + investmentProgramKey);
        return relationDao.insert(chainKey, investmentProgramKey, planGroupKey);
    }

    @Override
    public IpgChainRelation update(int relationKey, int investmentProgramKey, Integer planGroupKey) {
        IpgChainRelation current = relationDao.findById(relationKey)
                .orElseThrow(() -> new IllegalArgumentException("Связь не найдена: " + relationKey));
        if (current.investmentProgramKey() != investmentProgramKey) {
            relationDao.findByChainAndIpg(current.chainKey(), investmentProgramKey).ifPresent(existing -> {
                if (existing.relationKey() != relationKey) {
                    throw new IllegalArgumentException(
                            "ИП " + investmentProgramKey + " уже в цепочке " + current.chainKey());
                }
            });
        }
        return relationDao.update(relationKey, investmentProgramKey, planGroupKey);
    }

    @Override
    public boolean remove(int relationKey) {
        return relationDao.delete(relationKey);
    }
}
