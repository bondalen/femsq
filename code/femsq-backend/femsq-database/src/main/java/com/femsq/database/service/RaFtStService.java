package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSt;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с типами источников {@code ags.ra_ft_st}.
 */
public interface RaFtStService {

    /**
     * Возвращает все типы источников.
     *
     * @return неизменяемый список типов источников
     */
    List<RaFtSt> getAll();

    /**
     * Ищет тип источника по идентификатору.
     *
     * @param stKey первичный ключ типа источника
     * @return тип источника, если найден
     */
    Optional<RaFtSt> getById(int stKey);

    /**
     * Создает новый тип источника после валидации бизнес-правил.
     *
     * @param raFtSt тип источника без идентификатора
     * @return созданный тип источника
     * @throws DaoException при ошибке сохранения
     */
    RaFtSt create(RaFtSt raFtSt);

    /**
     * Обновляет существующий тип источника.
     *
     * @param raFtSt тип источника с идентификатором
     * @return обновленный тип источника
     */
    RaFtSt update(RaFtSt raFtSt);

    /**
     * Удаляет тип источника.
     *
     * @param stKey идентификатор типа источника
     * @return {@code true}, если запись удалена
     */
    boolean delete(int stKey);
}
