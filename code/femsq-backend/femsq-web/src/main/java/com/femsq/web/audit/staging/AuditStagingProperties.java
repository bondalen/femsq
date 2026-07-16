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

    private Type5 type5 = new Type5();

    /**
     * @return уровень лога по умолчанию, если в ревизии {@code adt_staging_log_level IS NULL}
     */
    public StagingLogLevel getDefaultLogLevel() {
        return defaultLogLevel;
    }

    public void setDefaultLogLevel(StagingLogLevel defaultLogLevel) {
        this.defaultLogLevel = defaultLogLevel != null ? defaultLogLevel : StagingLogLevel.SUMMARY;
    }

    /**
     * @return настройки Stage 1 для type=5 (отчёты агентов)
     */
    public Type5 getType5() {
        return type5;
    }

    public void setType5(Type5 type5) {
        this.type5 = type5 != null ? type5 : new Type5();
    }

    /**
     * Подмножество настроек для файлов type=5.
     */
    public static class Type5 {

        /**
         * Regex маркера в «№ ОА» для нижней границы диапазона и (позже) OTHER.
         * По умолчанию семь цифр кода стройки.
         */
        private String raNumRegex = Type5SignFilterClassifier.DEFAULT_RA_NUM_REGEX;

        /**
         * @return regex для поиска маркера в номере ОА
         */
        public String getRaNumRegex() {
            return raNumRegex;
        }

        public void setRaNumRegex(String raNumRegex) {
            this.raNumRegex = (raNumRegex == null || raNumRegex.isBlank())
                    ? Type5SignFilterClassifier.DEFAULT_RA_NUM_REGEX
                    : raNumRegex.trim();
        }
    }
}
