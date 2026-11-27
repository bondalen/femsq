package com.femsq.database.dao;

import com.femsq.database.model.ImpIpgLoadMonf;
import java.util.List;
import java.util.Optional;

/**
 * DAO {@code ags.impIpgLoadMonf} (C2 §6.4).
 */
public interface ImpIpgLoadMonfDao {

    /**
     * Строки Monf сессии загрузки.
     */
    List<ImpIpgLoadMonf> findByLoad(int loadKey);

    /**
     * Все Monf текущей ИП (через join load).
     */
    List<ImpIpgLoadMonf> findByIpg(int ipgKey);

    /**
     * По ключу.
     */
    Optional<ImpIpgLoadMonf> findByKey(int iilmKey);

    /**
     * Создать строку Monf.
     */
    ImpIpgLoadMonf insert(
            int loadKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note);

    /**
     * Обновить метаданные / привязку.
     */
    ImpIpgLoadMonf update(
            int iilmKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note);

    /**
     * Удалить строку.
     */
    boolean delete(int iilmKey);

    /**
     * Сохранить HTML-лог разбора/применения в {@code iilmResults}.
     */
    void updateResults(int iilmKey, String html);
}
