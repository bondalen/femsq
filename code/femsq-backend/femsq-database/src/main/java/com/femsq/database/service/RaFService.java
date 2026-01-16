package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaF;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с файлами ревизий {@code ags.ra_f}.
 */
public interface RaFService {

    /**
     * Возвращает все файлы.
     *
     * @return неизменяемый список файлов
     */
    List<RaF> getAll();

    /**
     * Ищет файл по идентификатору.
     *
     * @param afKey первичный ключ файла
     * @return файл, если найден
     */
    Optional<RaF> getById(long afKey);

    /**
     * Возвращает файлы для указанной ревизии.
     *
     * @param adtKey идентификатор ревизии
     * @return список файлов для ревизии
     */
    List<RaF> getByAuditId(long adtKey);

    /**
     * Возвращает файлы для указанной директории.
     *
     * @param dirKey идентификатор директории
     * @return список файлов для директории
     */
    List<RaF> getByDirId(int dirKey);

    /**
     * Возвращает файлы для указанного типа файла.
     *
     * @param fileType тип файла (1-6)
     * @return список файлов указанного типа
     */
    List<RaF> getByFileType(int fileType);

    /**
     * Создает новый файл после валидации бизнес-правил.
     *
     * @param raF файл без идентификатора
     * @return созданный файл
     * @throws DaoException при ошибке сохранения
     */
    RaF create(RaF raF);

    /**
     * Обновляет существующий файл.
     *
     * @param raF файл с идентификатором
     * @return обновленный файл
     */
    RaF update(RaF raF);

    /**
     * Удаляет файл.
     *
     * @param afKey идентификатор файла
     * @return {@code true}, если запись удалена
     */
    boolean delete(long afKey);
}
