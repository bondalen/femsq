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
     * Возвращает организации с пагинацией и сортировкой.
     *
     * @param page номер страницы (начиная с 0)
     * @param size размер страницы
     * @param sortField поле для сортировки (например, "ogNm")
     * @param sortDirection направление сортировки ("asc" или "desc")
     * @return список организаций для запрошенной страницы
     */
    default List<Og> findAll(int page, int size, String sortField, String sortDirection) {
        return findAll(page, size, sortField, sortDirection, null);
    }

    /**
     * Возвращает организации с пагинацией, сортировкой и фильтром по наименованию.
     *
     * @param page номер страницы (начиная с 0)
     * @param size размер страницы
     * @param sortField поле для сортировки (например, "ogNm")
     * @param sortDirection направление сортировки ("asc" или "desc")
     * @param nameFilter фильтр по части наименования (case-insensitive)
     * @return список организаций для запрошенной страницы
     */
    List<Og> findAll(int page, int size, String sortField, String sortDirection, String nameFilter);

    /**
     * Подсчитывает общее количество организаций.
     *
     * @return общее количество записей
     */
    default long count() {
        return count(null);
    }

    /**
     * Подсчитывает количество организаций с учетом фильтра по наименованию.
     *
     * @param nameFilter фильтр по части наименования (case-insensitive)
     * @return количество записей, удовлетворяющих фильтру
     */
    long count(String nameFilter);

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
