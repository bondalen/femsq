package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAg;
import java.util.List;
import java.util.Optional;

/**
 * DAO для таблицы {@code ags.cstAg}.
 */
public interface CstAgDao {

    /**
     * Находит агента на стройке по идентификатору.
     */
    Optional<CstAg> findById(int cstaKey);

    /**
     * Возвращает агентов стройки (с подписью из {@code ogAgCs}).
     */
    List<CstAg> findByCst(int cstKey);

    /**
     * Создаёт запись {@code cstAg}.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    CstAg create(CstAg agent);

    /**
     * Обновляет запись {@code cstAg}.
     *
     * @throws DaoException если запись не найдена или при ошибке БД
     */
    CstAg update(CstAg agent);

    /**
     * Удаляет запись по идентификатору.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int cstaKey);
}
