package com.femsq.database.dao;

import com.femsq.database.model.RaDir;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_dir} (директории для ревизий).
 */
public interface RaDirDao {

    /**
     * Возвращает директорию по идентификатору.
     */
    Optional<RaDir> findById(int key);

    /**
     * Возвращает все директории.
     */
    List<RaDir> findAll();

    /**
     * Подсчитывает количество записей.
     */
    long count();
}