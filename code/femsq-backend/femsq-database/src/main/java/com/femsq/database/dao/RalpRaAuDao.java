package com.femsq.database.dao;

import com.femsq.database.model.RalpRaAu;
import java.util.List;
import java.util.Optional;

/**
 * DAO строк {@code ags.ralpRaAu}.
 */
public interface RalpRaAuDao {

    /**
     * Находит строку по ключу.
     *
     * @param ralpraKey PK
     * @return запись или empty
     */
    Optional<RalpRaAu> findById(int ralpraKey);

    /**
     * Возвращает строки рассмотрения для отчёта.
     *
     * @param ralprKey FK → ralpRa
     * @return неизменяемый список
     */
    List<RalpRaAu> findByRa(int ralprKey);

    /**
     * Создаёт строку Au.
     *
     * @param row данные без PK
     * @return созданная запись
     */
    RalpRaAu create(RalpRaAu row);

    /**
     * Обновляет строку Au (без затирания testStartDate/fdKey).
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
    boolean deleteById(int ralpraKey);
}
