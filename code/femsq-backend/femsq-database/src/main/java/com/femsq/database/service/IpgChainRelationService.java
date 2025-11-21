package com.femsq.database.service;

import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;

/** Сервис для связей инвестиционных цепочек. */
public interface IpgChainRelationService {

    List<IpgChainRelation> getByChain(int chainKey);

    List<IpgChainRelation> getByChains(Collection<Integer> chainKeys);

    List<IpgChainRelation> getAll();
}
