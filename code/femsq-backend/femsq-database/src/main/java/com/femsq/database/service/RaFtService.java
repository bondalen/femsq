package com.femsq.database.service;

import com.femsq.database.model.RaFt;
import java.util.List;
import java.util.Optional;

/**
 * Сервис для работы со справочником типов файлов {@code ags.ra_ft}.
 * Предназначен для lookup операций (только чтение).
 */
public interface RaFtService {

    /**
     * Возвращает тип файла по идентификатору.
     *
     * @param ftKey идентификатор типа файла
     * @return Optional с типом файла или пустой Optional
     */
    Optional<RaFt> getById(int ftKey);

    /**
     * Возвращает все типы файлов.
     *
     * @return список всех типов файлов
     */
    List<RaFt> getAll();

    /**
     * Возвращает количество типов файлов.
     *
     * @return количество записей
     */
    long count();
}
