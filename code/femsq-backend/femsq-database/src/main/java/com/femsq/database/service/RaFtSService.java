package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtS;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с источниками/листами {@code ags.ra_ft_s}.
 */
public interface RaFtSService {

    /**
     * Возвращает все источники/листы.
     *
     * @return неизменяемый список источников
     */
    List<RaFtS> getAll();

    /**
     * Ищет источник/лист по идентификатору.
     *
     * @param ftSKey первичный ключ источника
     * @return источник, если найден
     */
    Optional<RaFtS> getById(int ftSKey);

    /**
     * Возвращает источники/листы для указанного типа файла.
     *
     * @param fileType тип файла (соответствует ra_f.af_type: 1-6)
     * @return список источников для типа файла, отсортированный по ft_s_num
     */
    List<RaFtS> getByFileType(int fileType);

    /**
     * Возвращает источники/листы для указанного типа источника.
     *
     * @param sheetType тип источника (FK → ra_ft_st.st_key)
     * @return список источников для типа источника
     */
    List<RaFtS> getBySheetType(int sheetType);

    /**
     * Создает новый источник/лист после валидации бизнес-правил.
     *
     * @param raFtS источник без идентификатора
     * @return созданный источник
     * @throws DaoException при ошибке сохранения
     */
    RaFtS create(RaFtS raFtS);

    /**
     * Обновляет существующий источник/лист.
     *
     * @param raFtS источник с идентификатором
     * @return обновленный источник
     */
    RaFtS update(RaFtS raFtS);

    /**
     * Удаляет источник/лист.
     *
     * @param ftSKey идентификатор источника
     * @return {@code true}, если запись удалена
     */
    boolean delete(int ftSKey);
}
