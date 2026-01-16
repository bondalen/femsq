package com.femsq.database.dao;

import com.femsq.database.model.RaFt;
import java.util.List;
import java.util.Optional;

/**
 * DAO интерфейс для работы со справочником типов файлов {@code ags.ra_ft}.
 * Предназначен для lookup операций в UI (выпадающие списки).
 */
public interface RaFtDao {

    /**
     * Находит тип файла по идентификатору.
     *
     * @param ftKey идентификатор типа файла
     * @return Optional с типом файла или пустой Optional
     */
    Optional<RaFt> findById(int ftKey);

    /**
     * Возвращает все типы файлов.
     *
     * @return список всех типов файлов, отсортированный по ft_key
     */
    List<RaFt> findAll();

    /**
     * Возвращает количество типов файлов в справочнике.
     *
     * @return количество записей
     */
    long count();
}
