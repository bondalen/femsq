package com.femsq.database.service;

import com.femsq.database.model.ImpIpgLoadMonf;
import java.util.List;
import java.util.Optional;

/**
 * Сервис помесячных Excel-агентов {@code ags.impIpgLoadMonf} (C2 §6.4).
 */
public interface ImpIpgLoadMonfService {

    /**
     * Строки Monf сессии загрузки.
     */
    List<ImpIpgLoadMonf> listByLoad(int loadKey);

    /**
     * Все Monf текущей ИП.
     */
    List<ImpIpgLoadMonf> listByIpg(int ipgKey);

    /**
     * По ключу.
     */
    Optional<ImpIpgLoadMonf> get(int iilmKey);

    /**
     * Создать строку Monf.
     */
    ImpIpgLoadMonf create(
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
     * Сохранить HTML-лог в {@code iilmResults}.
     */
    void updateResults(int iilmKey, String html);
}
