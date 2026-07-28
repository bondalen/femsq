package com.femsq.database.service;

import com.femsq.database.model.RalpRaCstListEntry;
import java.util.List;

/**
 * Сервис списка отчётов аренды стройки (Access {@code ralpRaCst}).
 */
public interface RalpRaCstListService {

    /**
     * Возвращает перечень для стройки.
     *
     * @param cstKey ключ стройки
     * @return список
     */
    List<RalpRaCstListEntry> getForCst(int cstKey);
}
