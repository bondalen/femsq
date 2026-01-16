package com.femsq.database.service;

import com.femsq.database.model.RaDir;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с директориями ревизий {@code ags.ra_dir}.
 */
public interface RaDirService {

    /**
     * Возвращает все доступные директории.
     *
     * @return неизменяемый список директорий
     */
    List<RaDir> getAll();
    
    /**
     * Возвращает директорию по идентификатору.
     *
     * @param key идентификатор директории
     * @return Optional с директорией или пустой Optional
     */
    Optional<RaDir> getById(int key);
}