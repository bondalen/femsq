package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportGenerationRequest;
import com.femsq.reports.model.ReportResult;
import net.sf.jasperreports.engine.JRException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.core.io.ResourceLoader;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Интеграционные тесты для {@link ReportGenerationService} с реальными JRXML шаблонами.
 * 
 * <p>Использует реальные JRXML файлы для проверки полного цикла генерации отчётов:
 * компиляция → заполнение → экспорт в PDF.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportGenerationServiceWithRealTemplatesTest {

    @Mock
    private ReportsProperties properties;

    @Mock
    private ReportsProperties.Generation generation;

    @Mock
    private ReportsProperties.Embedded embedded;

    @Mock
    private ReportDiscoveryService discoveryService;

    @Mock
    private JasperReportsEngine jasperEngine;

    @Mock
    private DataSource dataSource;

    @Mock
    private Connection connection;

    @Mock
    private ResourceLoader resourceLoader;

    @TempDir
    Path tempDir;

    private ReportGenerationService service;
    private Path jrxmlPath;

    @BeforeEach
    void setUp() throws Exception {
        MockitoAnnotations.openMocks(this);
        
        when(properties.getGeneration()).thenReturn(generation);
        when(properties.getExternal()).thenReturn(mock(ReportsProperties.External.class));
        when(properties.getExternal().getPathAsPath()).thenReturn(tempDir);
        when(properties.getEmbedded()).thenReturn(embedded);
        when(embedded.getPath()).thenReturn("classpath:reports/embedded");
        
        when(generation.getMaxConcurrent()).thenReturn(5);
        when(generation.getTimeout()).thenReturn(300000L);
        when(generation.getTempDirectoryAsPath()).thenReturn(tempDir.resolve("generation-temp"));
        
        when(dataSource.getConnection()).thenReturn(connection);
        
        // Копируем тестовый JRXML файл
        jrxmlPath = copyTestTemplateToTemp("simple-report.jrxml");
        
        service = new ReportGenerationService(
                properties,
                discoveryService,
                jasperEngine,
                dataSource,
                null, // ConnectionFactory не нужен в тестах, используется DataSource
                null, // DatabaseConfigurationService
                resourceLoader
        );
    }

    @Test
    void generateReport_withRealTemplate_generatesPdf() throws Exception {
        // Настраиваем моки
        com.femsq.reports.model.ReportMetadata metadata = createTestMetadata();
        when(discoveryService.getMetadata("simple-report")).thenReturn(metadata);
        
        // Используем реальный JasperReportsEngine для компиляции
        ReportsProperties testProps = createTestProperties();
        JasperReportsEngine realEngine = new JasperReportsEngine(testProps);
        
        // Компилируем шаблон заранее
        net.sf.jasperreports.engine.JasperReport compiledReport = realEngine.compileReport(jrxmlPath);
        when(jasperEngine.compileReport(any(Path.class))).thenReturn(compiledReport);
        
        // Создаём запрос на генерацию
        ReportGenerationRequest request = new ReportGenerationRequest(
                "simple-report",
                Map.of("title", "Test Title", "message", "Test Message"),
                "pdf"
        );
        
        // Генерируем отчёт
        ReportResult result = service.generateReport(request);
        
        assertNotNull(result);
        assertEquals("simple-report", result.reportId());
        assertEquals("pdf", result.format());
        assertNotNull(result.content());
        assertTrue(result.content().length > 0, "Generated PDF should not be empty");
    }

    @Test
    void generatePreview_withRealTemplate_generatesPdf() throws Exception {
        // Настраиваем моки
        com.femsq.reports.model.ReportMetadata metadata = createTestMetadata();
        when(discoveryService.getMetadata("simple-report")).thenReturn(metadata);
        
        // Используем реальный JasperReportsEngine для компиляции
        ReportsProperties testProps = createTestProperties();
        JasperReportsEngine realEngine = new JasperReportsEngine(testProps);
        
        // Компилируем шаблон заранее
        net.sf.jasperreports.engine.JasperReport compiledReport = realEngine.compileReport(jrxmlPath);
        when(jasperEngine.compileReport(any(Path.class))).thenReturn(compiledReport);
        
        // Генерируем preview
        ReportResult result = service.generatePreview(
                "simple-report",
                Map.of("title", "Test Title", "message", "Test Message")
        );
        
        assertNotNull(result);
        assertEquals("simple-report", result.reportId());
        assertEquals("pdf", result.format());
        assertNotNull(result.content());
        assertTrue(result.content().length > 0, "Generated preview PDF should not be empty");
    }

    /**
     * Создаёт тестовые метаданные отчёта.
     */
    private com.femsq.reports.model.ReportMetadata createTestMetadata() {
        // Используем полный путь к файлу для корректной работы getTemplatePath
        return new com.femsq.reports.model.ReportMetadata(
                "simple-report",
                "1.0.0",
                "Simple Test Report",
                "Test Description",
                "test",
                "Test Author",
                "2025-01-01",
                "2025-01-01",
                new com.femsq.reports.model.ReportMetadata.Files(
                        jrxmlPath.toString(), // Полный путь для корректной работы
                        null,
                        null
                ),
                java.util.List.of(),
                null,
                java.util.List.of(),
                "user"
        );
    }

    /**
     * Создаёт тестовые свойства для ReportsProperties.
     */
    private ReportsProperties createTestProperties() {
        ReportsProperties props = mock(ReportsProperties.class);
        ReportsProperties.Compilation compilation = mock(ReportsProperties.Compilation.class);
        
        when(props.getCompilation()).thenReturn(compilation);
        when(compilation.isCacheEnabled()).thenReturn(true);
        when(compilation.getCacheDirectoryAsPath()).thenReturn(tempDir.resolve("cache"));
        when(compilation.isRecompileOnChange()).thenReturn(true);
        
        return props;
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
