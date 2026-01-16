package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSt;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_ft_st} (типы источников).
 */
public interface RaFtStDao {

    /**
     * Возвращает тип источника по идентификатору.
     */
    Optional<RaFtSt> findById(int stKey);

    /**
     * Возвращает все типы источников.
     */
    List<RaFtSt> findAll();

    /**
     * Подсчитывает количество записей.
     */
    long count();

    /**
     * Создает новый тип источника.
     *
     * @param raFtSt данные нового типа источника без идентификатора
     * @return созданный тип источника с присвоенным идентификатором
     * @throws DaoException при ошибке сохранения
     */
    RaFtSt create(RaFtSt raFtSt);

    /**
     * Обновляет существующий тип источника.
     *
     * @param raFtSt обновленные данные с заполненным идентификатором
     * @return обновленный тип источника
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    RaFtSt update(RaFtSt raFtSt);

    /**
     * Удаляет тип источника по идентификатору.
     *
     * @param stKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int stKey);
}
