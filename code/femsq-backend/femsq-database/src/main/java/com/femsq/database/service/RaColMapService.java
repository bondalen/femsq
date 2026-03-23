package com.femsq.database.service;

import com.femsq.database.model.RaColMap;
import java.util.List;

/**
 * Сервис получения маппинга колонок.
 */
public interface RaColMapService {

    /**
     * Возвращает маппинг колонок для конфигурации листа.
     */
    List<RaColMap> getBySheetConfKey(int sheetConfKey);
}
