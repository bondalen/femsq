package com.femsq.database.service;

import com.femsq.database.model.RaSheetConf;
import java.util.List;

/**
 * Сервис получения конфигурации листов Excel.
 */
public interface RaSheetConfService {

    /**
     * Возвращает конфигурации листов для типа файла.
     */
    List<RaSheetConf> getByFileType(int fileType);
}
