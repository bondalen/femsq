package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPnBranch;
import java.util.List;
import java.util.Optional;

/**
 * DAO для таблицы {@code ags.cstAgPnBranch}.
 */
public interface CstAgPnBranchDao {

    /**
     * Находит филиал САК по идентификатору.
     */
    Optional<CstAgPnBranch> findById(int cstapbKey);

    /**
     * Возвращает филиалы для САК (с наименованием из {@code og}).
     */
    List<CstAgPnBranch> findByCstAgPn(int cstapKey);

    /**
     * Создаёт запись {@code cstAgPnBranch}.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    CstAgPnBranch create(CstAgPnBranch branch);

    /**
     * Обновляет запись {@code cstAgPnBranch}.
     *
     * @throws DaoException если запись не найдена или при ошибке БД
     */
    CstAgPnBranch update(CstAgPnBranch branch);

    /**
     * Удаляет запись по идентификатору.
     *
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int cstapbKey);
}
