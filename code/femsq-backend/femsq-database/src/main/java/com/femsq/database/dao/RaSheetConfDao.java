package com.femsq.database.dao;

import com.femsq.database.model.RaSheetConf;
import java.util.List;

/**
 * DAO для таблицы {@code ags.ra_sheet_conf}.
 */
public interface RaSheetConfDao {

    /**
     * Возвращает конфигурации листов по типу файла.
     */
    List<RaSheetConf> findByFileType(int fileType);
}
