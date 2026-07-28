package com.femsq.database.dao;

import com.femsq.database.model.RalpRa;
import java.util.Optional;

/**
 * DAO заголовка {@code ags.ralpRa}.
 */
public interface RalpRaDao {

    /**
     * Находит отчёт по ключу.
     *
     * @param ralprKey PK
     * @return запись или empty
     */
    Optional<RalpRa> findById(int ralprKey);

    /**
     * Создаёт отчёт (без computed {@code ralprY}/{@code ralprM}).
     *
     * @param report данные без PK
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
     * Удаляет отчёт по ключу.
     *
     * @param ralprKey PK
     * @return true, если удалена строка
     */
    boolean deleteById(int ralprKey);

    /**
     * Проверяет наличие дочерних строк {@code ralpRaAu}.
     *
     * @param ralprKey PK заголовка
     * @return true, если есть Au
     */
    boolean hasAus(int ralprKey);
}
