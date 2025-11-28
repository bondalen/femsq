package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperReport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.FileTime;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Интеграционные тесты для кэширования в {@link JasperReportsEngine}.
 * 
 * <p>Проверяет работу кэша скомпилированных отчётов:
 * - Кэширование в памяти
 * - Кэширование на диск
 * - Обновление кэша при изменении файлов
 * - Recompile-on-change функциональность
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class JasperReportsEngineCacheTest {

    @Mock
    private ReportsProperties properties;

    @Mock
    private ReportsProperties.Compilation compilation;

    @TempDir
    Path tempDir;

    private JasperReportsEngine engine;
    private Path cacheDir;
    private Path jrxmlPath;

    @BeforeEach
    void setUp() throws Exception {
        MockitoAnnotations.openMocks(this);
        
        cacheDir = tempDir.resolve("cache");
        Files.createDirectories(cacheDir);
        
        when(properties.getCompilation()).thenReturn(compilation);
        when(compilation.isCacheEnabled()).thenReturn(true);
        when(compilation.getCacheDirectoryAsPath()).thenReturn(cacheDir);
        when(compilation.isRecompileOnChange()).thenReturn(true);
        
        engine = new JasperReportsEngine(properties);
        
        // Копируем тестовый JRXML файл
        jrxmlPath = copyTestTemplate("simple-report.jrxml");
    }

    @Test
    void compileReport_cachesInMemory() throws Exception {
        // Первая компиляция
        JasperReport report1 = engine.compileReport(jrxmlPath);
        assertNotNull(report1);
        
        // Проверяем размер кэша
        assertEquals(1, engine.getCacheSize());
        
        // Вторая компиляция должна использовать кэш
        JasperReport report2 = engine.compileReport(jrxmlPath);
        assertNotNull(report2);
        
        // Кэш должен содержать тот же отчёт
        assertEquals(1, engine.getCacheSize());
    }

    @Test
    void compileReport_savesToDiskCache() throws Exception {
        // Компилируем отчёт
        JasperReport report = engine.compileReport(jrxmlPath);
        assertNotNull(report);
        
        // Проверяем, что .jasper файл создан в кэше
        Path jasperFile = cacheDir.resolve("simple-report.jasper");
        assertTrue(Files.exists(jasperFile), "Compiled report should be saved to disk cache");
        assertTrue(Files.size(jasperFile) > 0, "Cached file should not be empty");
    }

    @Test
    void compileReport_loadsFromDiskCache() throws Exception {
        // Первая компиляция - создаёт кэш на диске
        JasperReport report1 = engine.compileReport(jrxmlPath);
        assertNotNull(report1);
        
        // Очищаем кэш в памяти
        engine.clearAllCache();
        assertEquals(0, engine.getCacheSize());
        
        // Вторая компиляция должна загрузить из дискового кэша
        JasperReport report2 = engine.compileReport(jrxmlPath);
        assertNotNull(report2);
        
        // Проверяем, что кэш в памяти восстановлен
        assertEquals(1, engine.getCacheSize());
    }

    @Test
    void compileReport_recompilesOnChange() throws Exception {
        // Первая компиляция
        JasperReport report1 = engine.compileReport(jrxmlPath);
        assertNotNull(report1);
        
        // Изменяем JRXML файл (изменяем timestamp)
        Files.setLastModifiedTime(jrxmlPath, FileTime.from(Instant.now().plusSeconds(10)));
        
        // Очищаем кэш в памяти для проверки recompile
        engine.clearCache(jrxmlPath);
        
        // Вторая компиляция должна перекомпилировать
        JasperReport report2 = engine.compileReport(jrxmlPath);
        assertNotNull(report2);
        
        // Проверяем, что кэш обновлён
        assertEquals(1, engine.getCacheSize());
    }

    @Test
    void compileReport_withRecompileOnChangeDisabled_usesCache() throws Exception {
        // Отключаем recompile-on-change
        when(compilation.isRecompileOnChange()).thenReturn(false);
        
        // Первая компиляция
        JasperReport report1 = engine.compileReport(jrxmlPath);
        assertNotNull(report1);
        
        // Изменяем timestamp файла
        Files.setLastModifiedTime(jrxmlPath, FileTime.from(Instant.now().plusSeconds(10)));
        
        // Очищаем кэш в памяти
        engine.clearCache(jrxmlPath);
        
        // Вторая компиляция должна использовать дисковый кэш
        // (не перекомпилирует, так как recompile-on-change отключен)
        JasperReport report2 = engine.compileReport(jrxmlPath);
        assertNotNull(report2);
    }

    @Test
    void clearCache_removesFromMemory() throws Exception {
        // Компилируем отчёт
        JasperReport report = engine.compileReport(jrxmlPath);
        assertNotNull(report);
        assertEquals(1, engine.getCacheSize());
        
        // Очищаем кэш
        engine.clearCache(jrxmlPath);
        
        // Проверяем, что кэш очищен
        assertEquals(0, engine.getCacheSize());
    }

    @Test
    void clearAllCache_removesAllFromMemory() throws Exception {
        // Компилируем несколько отчётов
        Path jrxml1 = copyTestTemplate("simple-report.jrxml");
        engine.compileReport(jrxml1);
        
        // Создаём второй отчёт
        Path jrxml2 = tempDir.resolve("second-report.jrxml");
        Files.copy(jrxml1, jrxml2);
        engine.compileReport(jrxml2);
        
        assertEquals(2, engine.getCacheSize());
        
        // Очищаем весь кэш
        engine.clearAllCache();
        
        // Проверяем, что кэш полностью очищен
        assertEquals(0, engine.getCacheSize());
    }

    @Test
    void compileReport_withCacheDisabled_doesNotSaveToDisk() throws Exception {
        // Отключаем кэширование
        when(compilation.isCacheEnabled()).thenReturn(false);
        
        // Создаём новый engine с отключенным кэшем
        JasperReportsEngine noCacheEngine = new JasperReportsEngine(properties);
        
        // Компилируем отчёт
        JasperReport report = noCacheEngine.compileReport(jrxmlPath);
        assertNotNull(report);
        
        // Проверяем, что .jasper файл НЕ создан
        Path jasperFile = cacheDir.resolve("simple-report.jasper");
        assertFalse(Files.exists(jasperFile), 
                "Compiled report should not be saved when cache is disabled");
    }

    /**
     * Копирует тестовый JRXML шаблон во временную директорию.
     */
    private Path copyTestTemplate(String templateName) throws IOException {
        InputStream templateStream = getClass().getResourceAsStream(
                "/reports/test/" + templateName);
        
        assertNotNull(templateStream, "Test template not found: " + templateName);
        
        Path jrxmlPath = tempDir.resolve(templateName);
        Files.copy(templateStream, jrxmlPath, StandardCopyOption.REPLACE_EXISTING);
        templateStream.close();
        
        return jrxmlPath;
    }
}
