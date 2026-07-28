package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Cst;
import java.util.List;
import java.util.Optional;

/**
 * DAO для таблицы {@code ags.cst}.
 */
public interface CstDao {

    /**
     * Находит стройку по идентификатору.
     */
    Optional<Cst> findById(int cstKey);

    /**
     * Возвращает все стройки, упорядоченные по имени.
     */
    List<Cst> findAll();

    /**
     * Создаёт стройку.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    Cst create(Cst site);

    /**
     * Обновляет стройку.
     *
     * @throws DaoException если запись не найдена или при ошибке БД
     */
    Cst update(Cst site);

    /**
     * Удаляет стройку по идентификатору.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int cstKey);
}
