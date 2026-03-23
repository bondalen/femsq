package com.femsq.web.audit.staging;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditFile;

/**
 * Generic-сервис Stage 1: загрузка данных Excel в staging-таблицы.
 */
public interface AuditStagingService {

    /**
     * Загружает строки из Excel-файла в staging-таблицы согласно конфигурации.
     *
     * @return количество вставленных строк
     */
    int loadToStaging(AuditExecutionContext context, AuditFile file);
}
