package com.femsq.reports.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Конфигурационные свойства модуля отчётов.
 * 
 * <p>Настройки загружаются из application.yml с префиксом {@code reports}.
 * 
 * <p>Пример конфигурации:
 * <pre>{@code
 * reports:
 *   external:
 *     enabled: true
 *     path: ./reports
 *     scan-interval: 60000
 *   embedded:
 *     enabled: true
 *     path: classpath:reports/embedded
 *   compilation:
 *     cache-enabled: true
 *     cache-directory: ./reports/cache
 *     recompile-on-change: true
 *   generation:
 *     timeout: 300000
 *     max-concurrent: 5
 *     temp-directory: ./temp/reports
 * }</pre>
 * 
 * <p>Бин создаётся через {@link org.springframework.boot.context.properties.EnableConfigurationProperties}
 * в {@link ReportsConfiguration}, поэтому {@code @Component} не требуется.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@ConfigurationProperties(prefix = "reports")
public class ReportsProperties {

    /**
     * Настройки внешних отчётов (из файловой системы).
     */
    private External external = new External();

    /**
     * Настройки встроенных отчётов (из classpath).
     */
    private Embedded embedded = new Embedded();

    /**
     * Настройки компиляции отчётов.
     */
    private Compilation compilation = new Compilation();

    /**
     * Настройки генерации отчётов.
     */
    private Generation generation = new Generation();

    // Getters and Setters

    public External getExternal() {
        return external;
    }

    public void setExternal(External external) {
        this.external = external;
    }

    public Embedded getEmbedded() {
        return embedded;
    }

    public void setEmbedded(Embedded embedded) {
        this.embedded = embedded;
    }

    public Compilation getCompilation() {
        return compilation;
    }

    public void setCompilation(Compilation compilation) {
        this.compilation = compilation;
    }

    public Generation getGeneration() {
        return generation;
    }

    public void setGeneration(Generation generation) {
        this.generation = generation;
    }

    /**
     * Настройки внешних отчётов.
     */
    public static class External {
        /**
         * Включить ли сканирование внешних отчётов.
         */
        private boolean enabled = true;

        /**
         * Путь к директории с внешними отчётами.
         * По умолчанию: {@code ./reports}
         */
        private String path = "./reports";

        /**
         * Интервал сканирования в миллисекундах.
         * По умолчанию: 300000 (5 минут)
         * 
         * <p>Увеличен до 5 минут для снижения нагрузки на файловую систему
         * при малом количестве отчётов. Hot-reload всё ещё работает корректно,
         * так как изменения обнаруживаются при следующем сканировании.
         */
        private long scanInterval = 300000;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getPath() {
            return path;
        }

        public void setPath(String path) {
            this.path = path;
        }

        /**
         * Получить путь как Path объект.
         * 
         * @return Path к директории с внешними отчётами
         */
        public Path getPathAsPath() {
            return Paths.get(path);
        }

        public long getScanInterval() {
            return scanInterval;
        }

        public void setScanInterval(long scanInterval) {
            this.scanInterval = scanInterval;
        }
    }

    /**
     * Настройки встроенных отчётов.
     */
    public static class Embedded {
        /**
         * Включить ли использование встроенных отчётов.
         */
        private boolean enabled = true;

        /**
         * Путь к встроенным отчётам в classpath.
         * По умолчанию: {@code classpath:reports/embedded}
         */
        private String path = "classpath:reports/embedded";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getPath() {
            return path;
        }

        public void setPath(String path) {
            this.path = path;
        }
    }

    /**
     * Настройки компиляции отчётов.
     */
    public static class Compilation {
        /**
         * Включить ли кэширование скомпилированных отчётов.
         */
        private boolean cacheEnabled = true;

        /**
         * Директория для кэша скомпилированных отчётов (.jasper файлы).
         * По умолчанию: {@code ./reports/cache}
         */
        private String cacheDirectory = "./reports/cache";

        /**
         * Перекомпилировать ли отчёты при изменении JRXML файлов.
         */
        private boolean recompileOnChange = true;

        public boolean isCacheEnabled() {
            return cacheEnabled;
        }

        public void setCacheEnabled(boolean cacheEnabled) {
            this.cacheEnabled = cacheEnabled;
        }

        public String getCacheDirectory() {
            return cacheDirectory;
        }

        public void setCacheDirectory(String cacheDirectory) {
            this.cacheDirectory = cacheDirectory;
        }

        /**
         * Получить путь к директории кэша как Path объект.
         * 
         * @return Path к директории кэша
         */
        public Path getCacheDirectoryAsPath() {
            return Paths.get(cacheDirectory);
        }

        public boolean isRecompileOnChange() {
            return recompileOnChange;
        }

        public void setRecompileOnChange(boolean recompileOnChange) {
            this.recompileOnChange = recompileOnChange;
        }
    }

    /**
     * Настройки генерации отчётов.
     */
    public static class Generation {
        /**
         * Таймаут генерации отчёта в миллисекундах.
         * По умолчанию: 300000 (5 минут)
         */
        private long timeout = 300000;

        /**
         * Максимальное количество одновременных генераций.
         * По умолчанию: 5
         */
        private int maxConcurrent = 5;

        /**
         * Директория для временных файлов при генерации.
         * По умолчанию: {@code ./temp/reports}
         */
        private String tempDirectory = "./temp/reports";

        public long getTimeout() {
            return timeout;
        }

        public void setTimeout(long timeout) {
            this.timeout = timeout;
        }

        public int getMaxConcurrent() {
            return maxConcurrent;
        }

        public void setMaxConcurrent(int maxConcurrent) {
            this.maxConcurrent = maxConcurrent;
        }

        public String getTempDirectory() {
            return tempDirectory;
        }

        public void setTempDirectory(String tempDirectory) {
            this.tempDirectory = tempDirectory;
        }

        /**
         * Получить путь к директории временных файлов как Path объект.
         * 
         * @return Path к директории временных файлов
         */
        public Path getTempDirectoryAsPath() {
            return Paths.get(tempDirectory);
        }
    }
}
