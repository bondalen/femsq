package com.femsq.database.dao;

import com.femsq.database.model.RaSumm;
import java.util.List;
import java.util.Optional;

/**
 * DAO таблицы {@code ags.ra_summ}.
 */
public interface RaSummDao {

    /**
     * Находит версию сумм по ключу.
     */
    Optional<RaSumm> findById(int rasKey);

    /**
     * Версии сумм отчёта, новые сверху.
     */
    List<RaSumm> findByRa(int raKey);

    /**
     * Создаёт версию сумм.
     */
    RaSumm create(RaSumm summ);

    /**
     * Обновляет версию сумм.
     */
    RaSumm update(RaSumm summ);

    /**
     * Удаляет одну версию сумм.
     */
    boolean deleteById(int rasKey);

    /**
     * Удаляет все версии сумм отчёта.
     *
     * @return число удалённых строк
     */
    int deleteByRa(int raKey);
}
