package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaF;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_f} (файлы для проверки).
 */
public interface RaFDao {

    /**
     * Возвращает файл по идентификатору.
     */
    Optional<RaF> findById(long afKey);

    /**
     * Возвращает все файлы.
     */
    List<RaF> findAll();

    /**
     * Возвращает файлы для указанной ревизии.
     *
     * @param adtKey идентификатор ревизии
     * @return список файлов для ревизии
     */
    List<RaF> findByAuditId(long adtKey);

    /**
     * Возвращает файлы для указанной директории.
     *
     * @param dirKey идентификатор директории
     * @return список файлов для директории
     */
    List<RaF> findByDirId(int dirKey);

    /**
     * Возвращает файлы для указанного типа файла.
     *
     * @param fileType тип файла (1-6)
     * @return список файлов указанного типа
     */
    List<RaF> findByFileType(int fileType);

    /**
     * Подсчитывает количество записей.
     */
    long count();

    /**
     * Создает новый файл.
     *
     * @param raF данные нового файла без идентификатора
     * @return созданный файл с присвоенным идентификатором
     * @throws DaoException при ошибке сохранения
     */
    RaF create(RaF raF);

    /**
     * Обновляет существующий файл.
     *
     * @param raF обновленные данные с заполненным идентификатором
     * @return обновленный файл
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    RaF update(RaF raF);

    /**
     * Удаляет файл по идентификатору.
     *
     * @param afKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(long afKey);
}
