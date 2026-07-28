package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.CstAgPnCode;
import com.femsq.database.model.CstAgPnSiteLookup;
import java.util.List;
import java.util.Optional;

/**
 * DAO для таблицы {@code ags.cstAgPn}.
 */
public interface CstAgPnDao {

    /**
     * Находит САК по идентификатору.
     */
    Optional<CstAgPn> findById(int cstapKey);

    /**
     * Возвращает САК для агента на стройке, упорядоченные по коду.
     */
    List<CstAgPn> findByCstAg(int cstaKey);

    /**
     * Список САК с ключом стройки для формы поиска по коду (как Access {@code cstAgPn}).
     *
     * @param codeFilter подстрока {@code cstapIpgPnN} (без {@code %}); {@code null}/пусто — все
     */
    List<CstAgPnCode> findCodes(String codeFilter);

    /**
     * Lookup САК стройки для combo {@code ra_cac}.
     *
     * @param cstKey идентификатор стройки
     */
    List<CstAgPnSiteLookup> findSiteLookups(int cstKey);

    /**
     * Создаёт запись {@code cstAgPn}.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    CstAgPn create(CstAgPn point);

    /**
     * Обновляет запись {@code cstAgPn}.
     *
     * @throws DaoException если запись не найдена или при ошибке БД
     */
    CstAgPn update(CstAgPn point);

    /**
     * Удаляет запись по идентификатору.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int cstapKey);
}
