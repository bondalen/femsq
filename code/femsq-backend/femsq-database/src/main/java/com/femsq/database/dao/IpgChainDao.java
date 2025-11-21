package com.femsq.database.dao;

import com.femsq.database.model.IpgChain;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ipgCh} (цепочки инвестиционных программ).
 */
public interface IpgChainDao {

    /**
     * Возвращает цепочку по идентификатору.
     */
    Optional<IpgChain> findById(int chainKey);

    /**
     * Возвращает все цепочки без пагинации.
     */
    List<IpgChain> findAll();

    /**
     * Возвращает цепочки с пагинацией, сортировкой и простыми фильтрами.
     *
     * @param page          номер страницы (0-based)
     * @param size          размер страницы
     * @param sortField     поле сортировки
     * @param sortDirection направление сортировки (ASC/DESC)
     * @param nameFilter    фильтр по наименованию (LIKE %value%)
     * @param yearFilter    фильтр по году (точное совпадение)
     */
    List<IpgChain> findAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter);

    /**
     * Подсчитывает количество записей с учетом фильтров.
     */
    long count(String nameFilter, Integer yearFilter);
}
