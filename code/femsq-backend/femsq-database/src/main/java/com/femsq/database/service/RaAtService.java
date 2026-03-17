package com.femsq.database.service;

import com.femsq.database.model.RaAt;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с типами ревизий {@code ags.ra_at}.
 */
public interface RaAtService {

    /**
     * Возвращает все доступные типы ревизий.
     *
     * @return неизменяемый список типов ревизий
     */
    List<RaAt> getAll();

    /**
     * Возвращает тип ревизии по идентификатору.
     *
     * @param atKey идентификатор типа ревизии
     * @return Optional с типом ревизии или пустой Optional, если не найден
     */
    Optional<RaAt> getById(int atKey);
}