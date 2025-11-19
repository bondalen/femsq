package com.femsq.database.service;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.util.List;
import java.util.Optional;

/**
 * Сервисный слой для работы с организациями {@code ags_test.og}.
 */
public interface OgService {

    /**
     * Возвращает все доступные организации.
     *
     * @return неизменяемый список организаций
     */
    List<Og> getAll();

    /**
     * Возвращает организации с пагинацией и сортировкой.
     *
     * @param page номер страницы (начиная с 0)
     * @param size размер страницы
     * @param sortField поле для сортировки (например, "ogNm")
     * @param sortDirection направление сортировки ("asc" или "desc")
     * @return список организаций для запрошенной страницы
     */
    default List<Og> getAll(int page, int size, String sortField, String sortDirection) {
        return getAll(page, size, sortField, sortDirection, null);
    }

    /**
     * Возвращает организации с пагинацией, сортировкой и фильтром по наименованию.
     *
     * @param page номер страницы (начиная с 0)
     * @param size размер страницы
     * @param sortField поле для сортировки
     * @param sortDirection направление сортировки ("asc" или "desc")
     * @param nameFilter фильтр по части наименования (case-insensitive)
     * @return список организаций для запрошенной страницы
     */
    List<Og> getAll(int page, int size, String sortField, String sortDirection, String nameFilter);

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
     * Ищет организацию по идентификатору.
     *
     * @param ogKey первичный ключ организации
     * @return организация, если найдена
     */
    Optional<Og> getById(int ogKey);

    /**
     * Создает новую организацию после валидации бизнес-правил.
     *
     * @param organization организация без идентификатора
     * @return созданная организация
     * @throws DaoException при ошибке сохранения
     */
    Og create(Og organization);

    /**
     * Обновляет существующую организацию.
     *
     * @param organization организация с идентификатором
     * @return обновленная организация
     */
    Og update(Og organization);

    /**
     * Удаляет организацию и каскадные данные.
     *
     * @param ogKey идентификатор организации
     * @return {@code true}, если запись удалена
     */
    boolean delete(int ogKey);
}
