package com.femsq.database.dao;

import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * DAO для связей цепочек инвестиционных программ ({@code ags.ipgChRl}).
 */
public interface IpgChainRelationDao {

    /** Возвращает связь по идентификатору. */
    Optional<IpgChainRelation> findById(int relationKey);

    /** Возвращает все связи конкретной цепочки. */
    List<IpgChainRelation> findByChain(int chainKey);

    /**
     * Возвращает связи для множества цепочек. Используется для пакетной загрузки (DataLoader).
     */
    List<IpgChainRelation> findByChains(Collection<Integer> chainKeys);

    /** Возвращает все связи без фильтров. */
    List<IpgChainRelation> findAll();
}
