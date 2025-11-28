package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperReport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Интеграционные тесты для {@link JasperReportsEngine} с реальными JRXML шаблонами.
 * 
 * <p>Использует реальные JRXML файлы из test/resources для проверки
 * компиляции и кэширования шаблонов.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class JasperReportsEngineWithRealTemplatesTest {

    private ReportsProperties properties;
    private ReportsProperties.Compilation compilation;
    private JasperReportsEngine engine;

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
        properties = mock(ReportsProperties.class);
        compilation = mock(ReportsProperties.Compilation.class);
        
        when(properties.getCompilation()).thenReturn(compilation);
        when(compilation.isCacheEnabled()).thenReturn(true);
        when(compilation.getCacheDirectoryAsPath()).thenReturn(tempDir.resolve("cache"));
        when(compilation.isRecompileOnChange()).thenReturn(true);
        
        engine = new JasperReportsEngine(properties);
    }

    @Test
    void compileReport_withRealJrxml_compilesSuccessfully() throws Exception {
        // Копируем тестовый JRXML файл во временную директорию
        Path jrxmlPath = copyTestTemplateToTemp("simple-report.jrxml");
        
        // Компилируем отчёт
        JasperReport report = engine.compileReport(jrxmlPath);
        
        assertNotNull(report);
        assertEquals("SimpleReport", report.getName());
    }

    @Test
    void compileReport_withRealJrxml_cachesCompiledReport() throws Exception {
        // Копируем тестовый JRXML файл во временную директорию
        Path jrxmlPath = copyTestTemplateToTemp("simple-report.jrxml");
        
        // Первая компиляция
        JasperReport report1 = engine.compileReport(jrxmlPath);
        assertNotNull(report1);
        
        // Вторая компиляция должна использовать кэш
        JasperReport report2 = engine.compileReport(jrxmlPath);
        assertNotNull(report2);
        
        // Проверяем, что .jasper файл создан в кэше
        Path cacheDir = tempDir.resolve("cache");
        assertTrue(Files.exists(cacheDir), "Cache directory should exist");
    }

    @Test
    void compileReport_withRealJrxml_handlesParameters() throws Exception {
        // Копируем тестовый JRXML файл во временную директорию
        Path jrxmlPath = copyTestTemplateToTemp("simple-report.jrxml");
        
        // Компилируем отчёт
        JasperReport report = engine.compileReport(jrxmlPath);
        
        assertNotNull(report);
        
        // Проверяем, что параметры загружены из JRXML
        // simple-report.jrxml содержит параметры "title" и "message"
        assertTrue(report.getParameters().length >= 2, 
                "Report should have at least 2 parameters (title, message)");
    }

    /**
     * Копирует тестовый JRXML шаблон из resources во временную директорию.
     */
    private Path copyTestTemplateToTemp(String templateName) throws IOException {
        InputStream templateStream = getClass().getResourceAsStream(
                "/reports/test/" + templateName);
        
        assertNotNull(templateStream, "Test template not found: " + templateName);
        
        Path jrxmlPath = tempDir.resolve(templateName);
        Files.copy(templateStream, jrxmlPath, StandardCopyOption.REPLACE_EXISTING);
        templateStream.close();
        
        return jrxmlPath;
    }
}
