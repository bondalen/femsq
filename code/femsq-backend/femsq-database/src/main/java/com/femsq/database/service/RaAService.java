package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaA;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с ревизиями {@code ags.ra_a}.
 */
public interface RaAService {

    /**
     * Возвращает все ревизии.
     *
     * @return неизменяемый список ревизий
     */
    List<RaA> getAll();

    /**
     * Ищет ревизию по идентификатору.
     *
     * @param adtKey первичный ключ ревизии
     * @return ревизия, если найдена
     */
    Optional<RaA> getById(long adtKey);

    /**
     * Создает новую ревизию после валидации бизнес-правил.
     *
     * @param raA ревизия без идентификатора
     * @return созданная ревизия
     * @throws DaoException при ошибке сохранения
     */
    RaA create(RaA raA);

    /**
     * Обновляет существующую ревизию.
     *
     * @param raA ревизия с идентификатором
     * @return обновленная ревизия
     */
    RaA update(RaA raA);

    /**
     * Удаляет ревизию.
     *
     * @param adtKey идентификатор ревизии
     * @return {@code true}, если запись удалена
     */
    boolean delete(long adtKey);
}