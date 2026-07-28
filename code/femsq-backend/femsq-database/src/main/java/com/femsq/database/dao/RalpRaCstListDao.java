package com.femsq.database.dao;

import com.femsq.database.model.RalpRaCstListEntry;
import java.util.List;

/**
 * Перечень отчётов аренды стройки (эквивалент Access {@code ralpRaCst}).
 */
public interface RalpRaCstListDao {

    /**
     * Возвращает строки списка для стройки.
     *
     * @param cstKey ключ стройки
     * @return неизменяемый список
     */
    List<RalpRaCstListEntry> findByCst(int cstKey);
}
