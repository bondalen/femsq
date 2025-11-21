package com.femsq.database.service;

import com.femsq.database.model.IpgChain;
import java.util.List;
import java.util.Optional;

/** Сервисный слой для цепочек инвестиционных программ. */
public interface IpgChainService {

    Optional<IpgChain> getById(int chainKey);

    List<IpgChain> getAll();

    List<IpgChain> getAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter);

    long count(String nameFilter, Integer yearFilter);
}
