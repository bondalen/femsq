package com.femsq.database.service;

import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;

/** Сервис для связей инвестиционных цепочек ({@code ags.ipgChRl}, C2 §2.4.3). */
public interface IpgChainRelationService {

    List<IpgChainRelation> getByChain(int chainKey);

    List<IpgChainRelation> getByChains(Collection<Integer> chainKeys);

    List<IpgChainRelation> getAll();

    /** Добавляет ИП в цепь; forbid дубль (chain, ipg). */
    IpgChainRelation add(int chainKey, int investmentProgramKey, Integer planGroupKey);

    /** Обновляет ИП и/или группу планов у связи. */
    IpgChainRelation update(int relationKey, int investmentProgramKey, Integer planGroupKey);

    /** Удаляет членство. */
    boolean remove(int relationKey);
}
