package com.femsq.database.service;

import com.femsq.database.model.IpgChain;
import java.util.List;
import java.util.Optional;

/** Сервисный слой для цепочек инвестиционных программ (C2 §2.4.3). */
public interface IpgChainService {

    Optional<IpgChain> getById(int chainKey);

    List<IpgChain> getAll();

    List<IpgChain> getAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter);

    long count(String nameFilter, Integer yearFilter);

    /**
     * Создаёт шапку {@code ags.ipgCh} (только имя).
     * stNet / late ИП / год — computed от {@code ipgChRl}.
     */
    IpgChain create(String name);

    /** Обновляет наименование цепочки. */
    IpgChain update(int chainKey, String name);

    /**
     * Удаляет цепочку вместе с членством {@code ipgChRl} (без mastering / {@code ipgChRl_2606}).
     */
    boolean delete(int chainKey);
}
