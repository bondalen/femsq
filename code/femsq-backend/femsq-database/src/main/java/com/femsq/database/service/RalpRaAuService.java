package com.femsq.database.service;

import com.femsq.database.model.RalpRaAu;
import java.util.List;
import java.util.Optional;

/**
 * Сервис строк {@code ags.ralpRaAu}.
 */
public interface RalpRaAuService {

    /**
     * Возвращает строку по ключу.
     *
     * @param ralpraKey PK
     * @return запись или empty
     */
    Optional<RalpRaAu> getById(int ralpraKey);

    /**
     * Возвращает строки для отчёта.
     *
     * @param ralprKey FK заголовка
     * @return список
     */
    List<RalpRaAu> getForRa(int ralprKey);

    /**
     * Создаёт строку Au.
     *
     * @param row данные
     * @return созданная запись
     */
    RalpRaAu create(RalpRaAu row);

    /**
     * Обновляет строку Au.
     *
     * @param row данные с PK
     * @return обновлённая запись
     */
    RalpRaAu update(RalpRaAu row);

    /**
     * Удаляет строку Au.
     *
     * @param ralpraKey PK
     * @return true, если удалена
     */
    boolean delete(int ralpraKey);
}
