package com.femsq.database.dao;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.util.List;
import java.util.Optional;

/**
 * DAO-интерфейс для работы с таблицей {@code ags_test.og}.
 */
public interface OgDao {

    /**
     * Находит организацию по идентификатору.
     *
     * @param ogKey первичный ключ организации
     * @return {@link Optional} с найденной организацией или пустой Optional, если запись отсутствует
     */
    Optional<Og> findById(int ogKey);

    /**
     * Возвращает все организации.
     *
     * @return неизменяемый список организаций
     */
    List<Og> findAll();

    /**
     * Создает новую организацию.
     *
     * @param organization данные новой организации без идентификатора
     * @return созданная организация с присвоенным идентификатором
     * @throws DaoException при ошибке доступа к БД
     */
    Og create(Og organization);

    /**
     * Обновляет существующую организацию.
     *
     * @param organization обновленные данные с заполненным идентификатором
     * @return обновленная организация
     * @throws DaoException если запись не найдена или при ошибке доступа к БД
     */
    Og update(Og organization);

    /**
     * Удаляет организацию по идентификатору.
     *
     * @param ogKey первичный ключ
     * @return {@code true}, если запись была удалена
     * @throws DaoException при ошибке доступа к БД
     */
    boolean deleteById(int ogKey);
}
