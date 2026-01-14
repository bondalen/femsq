package com.femsq.database.service;

import com.femsq.database.model.RaAt;
import java.util.List;

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
}