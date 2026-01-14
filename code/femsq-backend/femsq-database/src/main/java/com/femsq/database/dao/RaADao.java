package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaA;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_a} (ревизии).
 */
public interface RaADao {

    /**
     * Возвращает ревизию по идентификатору.
     */
    Optional<RaA> findById(long adtKey);

    /**
     * Возвращает все ревизии.
     */
    List<RaA> findAll();

    /**
     * Подсчитывает количество записей.
     */
    long count();

    /**
     * Создает новую ревизию.
     *
     * @param raA данные новой ревизии без идентификатора
     * @return созданная ревизия с присвоенным идентификатором
     * @throws DaoException при ошибке сохранения
     */
    RaA create(RaA raA);

    /**
     * Обновляет существующую ревизию.
     *
     * @param raA обновленные данные с заполненным идентификатором
     * @return обновленная ревизия
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    RaA update(RaA raA);

    /**
     * Удаляет ревизию по идентификатору.
     *
     * @param adtKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(long adtKey);
}