package com.femsq.web.audit.mapping;

import com.femsq.database.model.RaColMap;
import com.femsq.database.model.RaSheetConf;
import java.util.List;

/**
 * Репозиторий конфигурации маппинга Excel-колонок для audit-процессоров.
 */
public interface AuditColumnMappingRepository {

    /**
     * Возвращает конфигурации листов для типа файла.
     */
    List<RaSheetConf> getSheetConfigs(int fileType);

    /**
     * Возвращает маппинг колонок для конфигурации листа.
     */
    List<RaColMap> getColumnMappings(int sheetConfKey);
}
