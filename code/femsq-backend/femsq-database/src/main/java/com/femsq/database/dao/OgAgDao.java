package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.OgAg;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags_test.ogAg}.
 */
public interface OgAgDao {

    /**
     * Находит агентскую организацию по идентификатору.
     *
     * @param ogAgKey первичный ключ записи
     * @return {@link Optional} с найденной записью
     */
    Optional<OgAg> findById(int ogAgKey);

    /**
     * Находит агентские организации по идентификатору базовой организации.
     *
     * @param organizationKey идентификатор записи {@code ags_test.og}
     * @return список агентских организаций
     */
    List<OgAg> findByOrganization(int organizationKey);

    /**
     * Возвращает все агентские организации.
     *
     * @return неизменяемый список агентских организаций
     */
    List<OgAg> findAll();

    /**
     * Создает новую агентскую организацию.
     *
     * @param agent данные новой записи
     * @return созданная запись с присвоенным идентификатором
     * @throws DaoException при ошибке доступа к БД
     */
    OgAg create(OgAg agent);

    /**
     * Обновляет существующую запись агентской организации.
     *
     * @param agent обновленные данные с заполненным идентификатором
     * @return обновленная запись
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    OgAg update(OgAg agent);

    /**
     * Удаляет запись агентской организации по идентификатору.
     *
     * @param ogAgKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int ogAgKey);
}
