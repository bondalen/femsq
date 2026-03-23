package com.femsq.database.dao;

import com.femsq.database.model.RaColMap;
import java.util.List;

/**
 * DAO для таблицы {@code ags.ra_col_map}.
 */
public interface RaColMapDao {

    /**
     * Возвращает маппинги колонок для заданной конфигурации листа.
     */
    List<RaColMap> findBySheetConfKey(int sheetConfKey);
}
