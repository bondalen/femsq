package com.femsq.database.dao;

import com.femsq.database.model.OgAgCs;
import java.util.List;

/**
 * DAO для представления {@code ags.ogAgCs} (lookup combo агентов).
 */
public interface OgAgCsDao {

    /**
     * Возвращает все записи lookup, упорядоченные по подписи.
     */
    List<OgAgCs> findAll();
}
