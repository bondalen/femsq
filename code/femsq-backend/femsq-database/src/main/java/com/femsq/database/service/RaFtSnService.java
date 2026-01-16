package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSn;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с именами источников {@code ags.ra_ft_sn}.
 */
public interface RaFtSnService {

    /**
     * Возвращает все имена источников.
     *
     * @return неизменяемый список имен источников
     */
    List<RaFtSn> getAll();

    /**
     * Ищет имя источника по идентификатору.
     *
     * @param ftsnKey первичный ключ имени источника
     * @return имя источника, если найдено
     */
    Optional<RaFtSn> getById(int ftsnKey);

    /**
     * Возвращает имена источников для указанного источника/листа.
     *
     * @param ftSKey идентификатор источника/листа (FK → ra_ft_s.ft_s_key)
     * @return список имен для источника
     */
    List<RaFtSn> getByFtS(int ftSKey);

    /**
     * Создает новое имя источника после валидации бизнес-правил.
     *
     * @param raFtSn имя источника без идентификатора
     * @return созданное имя источника
     * @throws DaoException при ошибке сохранения
     */
    RaFtSn create(RaFtSn raFtSn);

    /**
     * Обновляет существующее имя источника.
     *
     * @param raFtSn имя источника с идентификатором
     * @return обновленное имя источника
     */
    RaFtSn update(RaFtSn raFtSn);

    /**
     * Удаляет имя источника.
     *
     * @param ftsnKey идентификатор имени источника
     * @return {@code true}, если запись удалена
     */
    boolean delete(int ftsnKey);
}
