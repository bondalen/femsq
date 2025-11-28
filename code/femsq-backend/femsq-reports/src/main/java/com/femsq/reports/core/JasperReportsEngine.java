package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.engine.util.JRSaver;
import net.sf.jasperreports.engine.xml.JRXmlLoader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Движок компиляции и кэширования JasperReports шаблонов.
 * 
 * <p>Обеспечивает:
 * <ul>
 *   <li>Компиляцию JRXML → JasperReport</li>
 *   <li>Кэширование скомпилированных отчётов в памяти и на диске</li>
 *   <li>Поддержку прекомпилированных .jasper файлов</li>
 *   <li>Автоматическую перекомпиляцию при изменении JRXML</li>
 * </ul>
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@Component
public class JasperReportsEngine {

    private static final Logger log = LoggerFactory.getLogger(JasperReportsEngine.class);

    private final ReportsProperties properties;

    /**
     * Кэш скомпилированных отчётов в памяти.
     * Key: путь к JRXML файлу, Value: JasperReport
     */
    private final ConcurrentHashMap<String, JasperReport> memoryCache = new ConcurrentHashMap<>();

    /**
     * Кэш времени последней компиляции.
     * Key: путь к JRXML файлу, Value: timestamp последней компиляции
     */
    private final ConcurrentHashMap<String, Long> compilationTimestamps = new ConcurrentHashMap<>();

    public JasperReportsEngine(ReportsProperties properties) {
        this.properties = properties;
        initializeCacheDirectory();
    }

    /**
     * Инициализирует директорию кэша, если кэширование включено.
     */
    private void initializeCacheDirectory() {
        if (!properties.getCompilation().isCacheEnabled()) {
            return;
        }

        Path cacheDir = properties.getCompilation().getCacheDirectoryAsPath();
        try {
            if (!Files.exists(cacheDir)) {
                Files.createDirectories(cacheDir);
                log.info("Created cache directory: {}", cacheDir);
            }
        } catch (IOException e) {
            log.error("Failed to create cache directory: {}", cacheDir, e);
        }
    }

    /**
     * Компилирует JRXML шаблон в JasperReport.
     * 
     * <p>Приоритет загрузки:
     * <ol>
     *   <li>Проверка кэша в памяти</li>
     *   <li>Загрузка прекомпилированного .jasper файла (если существует и актуален)</li>
     *   <li>Компиляция JRXML → JasperReport</li>
     *   <li>Сохранение в кэш (память и диск, если включено)</li>
     * </ol>
     * 
     * @param jrxmlPath путь к JRXML файлу
     * @return скомпилированный JasperReport
     * @throws JRException если компиляция не удалась
     */
    public JasperReport compileReport(Path jrxmlPath) throws JRException {
        String jrxmlPathString = jrxmlPath.toString();

        // 1. Проверка кэша в памяти
        JasperReport cached = memoryCache.get(jrxmlPathString);
        if (cached != null && !needsRecompilation(jrxmlPath)) {
            log.debug("Using cached report from memory: {}", jrxmlPath);
            return cached;
        }

        // 2. Попытка загрузить прекомпилированный .jasper файл
        Path jasperPath = getJasperPath(jrxmlPath);
        if (Files.exists(jasperPath) && !needsRecompilation(jrxmlPath, jasperPath)) {
            try {
                JasperReport report = loadPrecompiledReport(jasperPath);
                if (report != null) {
                    // Обновляем кэш в памяти
                    memoryCache.put(jrxmlPathString, report);
                    updateCompilationTimestamp(jrxmlPath);
                    log.debug("Loaded precompiled report: {}", jasperPath);
                    return report;
                }
            } catch (Exception e) {
                log.warn("Failed to load precompiled report: {}, will recompile", jasperPath, e);
            }
        }

        // 3. Компиляция JRXML
        log.debug("Compiling JRXML report: {}", jrxmlPath);
        JasperReport report = compileJrxml(jrxmlPath);

        // 4. Сохранение в кэш
        memoryCache.put(jrxmlPathString, report);
        updateCompilationTimestamp(jrxmlPath);

        // Сохранение на диск, если кэширование включено
        if (properties.getCompilation().isCacheEnabled()) {
            saveCompiledReport(report, jasperPath);
        }

        return report;
    }

    /**
     * Компилирует JRXML файл в JasperReport.
     * 
     * @param jrxmlPath путь к JRXML файлу
     * @return скомпилированный JasperReport
     * @throws JRException если компиляция не удалась
     */
    private JasperReport compileJrxml(Path jrxmlPath) throws JRException {
        try (InputStream inputStream = Files.newInputStream(jrxmlPath)) {
            // Загружаем JRXML в JasperDesign
            JasperDesign design = JRXmlLoader.load(inputStream);
            
            // Компилируем в JasperReport
            JasperReport report = JasperCompileManager.compileReport(design);
            
            log.info("Successfully compiled report: {}", jrxmlPath);
            return report;
        } catch (IOException e) {
            throw new JRException("Failed to read JRXML file: " + jrxmlPath, e);
        }
    }

    /**
     * Загружает прекомпилированный .jasper файл.
     * 
     * @param jasperPath путь к .jasper файлу
     * @return загруженный JasperReport или null при ошибке
     */
    private JasperReport loadPrecompiledReport(Path jasperPath) {
        try (InputStream inputStream = Files.newInputStream(jasperPath)) {
            JasperReport report = (JasperReport) JRLoader.loadObject(inputStream);
            log.debug("Loaded precompiled report from: {}", jasperPath);
            return report;
        } catch (Exception e) {
            log.error("Failed to load precompiled report: {}", jasperPath, e);
            return null;
        }
    }

    /**
     * Сохраняет скомпилированный отчёт в .jasper файл.
     * 
     * @param report скомпилированный JasperReport
     * @param jasperPath путь для сохранения .jasper файла
     */
    private void saveCompiledReport(JasperReport report, Path jasperPath) {
        try {
            // Создаём директорию, если не существует
            Path parentDir = jasperPath.getParent();
            if (parentDir != null && !Files.exists(parentDir)) {
                Files.createDirectories(parentDir);
            }

            // Сохраняем скомпилированный отчёт
            try (FileOutputStream outputStream = new FileOutputStream(jasperPath.toFile())) {
                JRSaver.saveObject(report, outputStream);
                log.debug("Saved compiled report to cache: {}", jasperPath);
            }
        } catch (Exception e) {
            log.warn("Failed to save compiled report to cache: {}", jasperPath, e);
            // Не бросаем исключение, так как это не критично
        }
    }

    /**
     * Проверяет, требуется ли перекомпиляция отчёта.
     * 
     * @param jrxmlPath путь к JRXML файлу
     * @return true если требуется перекомпиляция
     */
    private boolean needsRecompilation(Path jrxmlPath) {
        if (!properties.getCompilation().isRecompileOnChange()) {
            return false;
        }

        try {
            if (!Files.exists(jrxmlPath)) {
                return true; // Файл удалён, нужно перекомпилировать
            }

            FileTime jrxmlLastModified = Files.getLastModifiedTime(jrxmlPath);
            Long lastCompilationTime = compilationTimestamps.get(jrxmlPath.toString());

            if (lastCompilationTime == null) {
                return true; // Ещё не компилировали
            }

            // Проверяем, изменился ли JRXML файл после последней компиляции
            return jrxmlLastModified.toMillis() > lastCompilationTime;
        } catch (IOException e) {
            log.warn("Failed to check modification time for: {}", jrxmlPath, e);
            return true; // В случае ошибки перекомпилируем
        }
    }

    /**
     * Проверяет, требуется ли перекомпиляция, сравнивая JRXML и .jasper файлы.
     * 
     * @param jrxmlPath путь к JRXML файлу
     * @param jasperPath путь к .jasper файлу
     * @return true если требуется перекомпиляция
     */
    private boolean needsRecompilation(Path jrxmlPath, Path jasperPath) {
        if (!properties.getCompilation().isRecompileOnChange()) {
            return false;
        }

        try {
            if (!Files.exists(jrxmlPath)) {
                return true; // JRXML файл удалён
            }

            if (!Files.exists(jasperPath)) {
                return true; // .jasper файл отсутствует, нужно скомпилировать
            }

            FileTime jrxmlLastModified = Files.getLastModifiedTime(jrxmlPath);
            FileTime jasperLastModified = Files.getLastModifiedTime(jasperPath);

            // Если JRXML новее .jasper файла, требуется перекомпиляция
            return jrxmlLastModified.toMillis() > jasperLastModified.toMillis();
        } catch (IOException e) {
            log.warn("Failed to compare modification times: {} vs {}", jrxmlPath, jasperPath, e);
            return true; // В случае ошибки перекомпилируем
        }
    }

    /**
     * Получает путь к .jasper файлу для данного JRXML файла.
     * 
     * @param jrxmlPath путь к JRXML файлу
     * @return путь к соответствующему .jasper файлу
     */
    private Path getJasperPath(Path jrxmlPath) {
        String jrxmlFileName = jrxmlPath.getFileName().toString();
        String jasperFileName = jrxmlFileName.replace(".jrxml", ".jasper");

        // Если кэширование включено, сохраняем в директорию кэша
        if (properties.getCompilation().isCacheEnabled()) {
            Path cacheDir = properties.getCompilation().getCacheDirectoryAsPath();
            return cacheDir.resolve(jasperFileName);
        }

        // Иначе в той же директории, что и JRXML
        return jrxmlPath.getParent().resolve(jasperFileName);
    }

    /**
     * Обновляет timestamp последней компиляции для файла.
     * 
     * @param jrxmlPath путь к JRXML файлу
     */
    private void updateCompilationTimestamp(Path jrxmlPath) {
        try {
            if (Files.exists(jrxmlPath)) {
                FileTime lastModified = Files.getLastModifiedTime(jrxmlPath);
                compilationTimestamps.put(jrxmlPath.toString(), lastModified.toMillis());
            }
        } catch (IOException e) {
            log.warn("Failed to update compilation timestamp for: {}", jrxmlPath, e);
        }
    }

    /**
     * Очищает кэш в памяти для конкретного отчёта.
     * 
     * @param jrxmlPath путь к JRXML файлу
     */
    public void clearCache(Path jrxmlPath) {
        String jrxmlPathString = jrxmlPath.toString();
        memoryCache.remove(jrxmlPathString);
        compilationTimestamps.remove(jrxmlPathString);
        log.debug("Cleared cache for: {}", jrxmlPath);
    }

    /**
     * Очищает весь кэш в памяти.
     */
    public void clearAllCache() {
        memoryCache.clear();
        compilationTimestamps.clear();
        log.info("Cleared all report compilation cache");
    }

    /**
     * Получает количество отчётов в кэше памяти.
     * 
     * @return количество отчётов в кэше
     */
    public int getCacheSize() {
        return memoryCache.size();
    }
}
