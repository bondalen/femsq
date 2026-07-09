package com.femsq.web.audit.staging;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Настройки Stage 1 (Excel → staging).
 *
 * <p>Префикс: {@code audit.staging}.</p>
 */
@ConfigurationProperties(prefix = "audit.staging")
public class AuditStagingProperties {

    private StagingLogLevel defaultLogLevel = StagingLogLevel.SUMMARY;

    /**
     * @return уровень лога по умолчанию, если в ревизии {@code adt_staging_log_level IS NULL}
     */
    public StagingLogLevel getDefaultLogLevel() {
        return defaultLogLevel;
    }

    public void setDefaultLogLevel(StagingLogLevel defaultLogLevel) {
        this.defaultLogLevel = defaultLogLevel != null ? defaultLogLevel : StagingLogLevel.SUMMARY;
    }
}
