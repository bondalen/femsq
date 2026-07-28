package com.femsq.database.service;

import com.femsq.database.model.RalpRa;
import java.util.Optional;

/**
 * Сервис заголовка {@code ags.ralpRa}.
 */
public interface RalpRaService {

    /**
     * Возвращает отчёт по ключу.
     *
     * @param ralprKey PK
     * @return запись или empty
     */
    Optional<RalpRa> getById(int ralprKey);

    /**
     * Создаёт отчёт.
     *
     * @param report данные
     * @return созданная запись
     */
    RalpRa create(RalpRa report);

    /**
     * Обновляет отчёт.
     *
     * @param report данные с PK
     * @return обновлённая запись
     */
    RalpRa update(RalpRa report);

    /**
     * Удаляет отчёт (запрещено при наличии Au).
     *
     * @param ralprKey PK
     * @return true, если удалён
     */
    boolean delete(int ralprKey);
}
