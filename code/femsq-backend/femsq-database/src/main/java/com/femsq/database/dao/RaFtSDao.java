package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtS;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_ft_s} (источники/листы).
 */
public interface RaFtSDao {

    /**
     * Возвращает источник/лист по идентификатору.
     */
    Optional<RaFtS> findById(int ftSKey);

    /**
     * Возвращает все источники/листы.
     */
    List<RaFtS> findAll();

    /**
     * Возвращает источники/листы для указанного типа файла.
     *
     * @param fileType тип файла (соответствует ra_f.af_type: 1-6)
     * @return список источников для типа файла, отсортированный по ft_s_num
     */
    List<RaFtS> findByFileType(int fileType);

    /**
     * Возвращает источники/листы для указанного типа источника.
     *
     * @param sheetType тип источника (FK → ra_ft_st.st_key)
     * @return список источников для типа источника
     */
    List<RaFtS> findBySheetType(int sheetType);

    /**
     * Подсчитывает количество записей.
     */
    long count();

    /**
     * Создает новый источник/лист.
     *
     * @param raFtS данные нового источника без идентификатора
     * @return созданный источник с присвоенным идентификатором
     * @throws DaoException при ошибке сохранения
     */
    RaFtS create(RaFtS raFtS);

    /**
     * Обновляет существующий источник/лист.
     *
     * @param raFtS обновленные данные с заполненным идентификатором
     * @return обновленный источник
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    RaFtS update(RaFtS raFtS);

    /**
     * Удаляет источник/лист по идентификатору.
     *
     * @param ftSKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int ftSKey);
}
