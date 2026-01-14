package com.femsq.database.dao;

import com.femsq.database.model.RaAt;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_at} (типы ревизий).
 */
public interface RaAtDao {

    /**
     * Возвращает тип ревизии по идентификатору.
     */
    Optional<RaAt> findById(int atKey);

    /**
     * Возвращает все типы ревизий.
     */
    List<RaAt> findAll();

    /**
     * Подсчитывает количество записей.
     */
    long count();
}