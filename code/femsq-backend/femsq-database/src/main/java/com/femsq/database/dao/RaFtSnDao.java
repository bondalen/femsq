package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSn;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags.ra_ft_sn} (имена источников).
 */
public interface RaFtSnDao {

    /**
     * Возвращает имя источника по идентификатору.
     */
    Optional<RaFtSn> findById(int ftsnKey);

    /**
     * Возвращает все имена источников.
     */
    List<RaFtSn> findAll();

    /**
     * Возвращает имена источников для указанного источника/листа.
     *
     * @param ftSKey идентификатор источника/листа (FK → ra_ft_s.ft_s_key)
     * @return список имен для источника
     */
    List<RaFtSn> findByFtS(int ftSKey);

    /**
     * Подсчитывает количество записей.
     */
    long count();

    /**
     * Создает новое имя источника.
     *
     * @param raFtSn данные нового имени источника без идентификатора
     * @return созданное имя источника с присвоенным идентификатором
     * @throws DaoException при ошибке сохранения
     */
    RaFtSn create(RaFtSn raFtSn);

    /**
     * Обновляет существующее имя источника.
     *
     * @param raFtSn обновленные данные с заполненным идентификатором
     * @return обновленное имя источника
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    RaFtSn update(RaFtSn raFtSn);

    /**
     * Удаляет имя источника по идентификатору.
     *
     * @param ftsnKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int ftsnKey);
}
