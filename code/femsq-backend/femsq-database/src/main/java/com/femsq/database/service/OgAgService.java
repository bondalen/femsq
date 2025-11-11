package com.femsq.database.service;

import com.femsq.database.model.OgAg;
import java.util.List;
import java.util.Optional;

/**
 * Сервис для управления агентскими организациями {@code ags_test.ogAg}.
 */
public interface OgAgService {

    /**
     * Возвращает все агентские организации.
     */
    List<OgAg> getAll();

    /**
     * Возвращает агентские организации по идентификатору базовой организации.
     */
    List<OgAg> getForOrganization(int ogKey);

    /**
     * Ищет агентскую организацию по идентификатору.
     */
    Optional<OgAg> getById(int ogAgKey);

    /**
     * Создает новую агентскую организацию.
     */
    OgAg create(OgAg agent);

    /**
     * Обновляет существующую агентскую организацию.
     */
    OgAg update(OgAg agent);

    /**
     * Удаляет агентскую организацию по идентификатору.
     */
    boolean delete(int ogAgKey);
}
