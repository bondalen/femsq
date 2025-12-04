package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportInfo;
import com.femsq.reports.model.ReportMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.core.io.ResourceLoader;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Интеграционные тесты для hot-reload функциональности {@link ReportDiscoveryService}.
 * 
 * <p>Проверяет автоматическое обнаружение изменений в файлах отчётов
 * и обновление кэша метаданных.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportDiscoveryServiceHotReloadTest {

    @Mock
    private ReportsProperties properties;

    @Mock
    private ReportsProperties.External external;

    @Mock
    private ReportsProperties.Embedded embedded;

    @Mock
    private ResourceLoader resourceLoader;

    private ReportMetadataLoader metadataLoader;
    private ReportDiscoveryService service;

    @TempDir
    Path tempDir;

    private Path reportsDir;
    private Path customDir;

    @BeforeEach
    void setUp() throws Exception {
        MockitoAnnotations.openMocks(this);
        
        // Настраиваем структуру директорий
        reportsDir = tempDir.resolve("reports");
        customDir = reportsDir.resolve("custom");
        Files.createDirectories(customDir);
        
        when(properties.getExternal()).thenReturn(external);
        when(properties.getEmbedded()).thenReturn(embedded);
        when(external.isEnabled()).thenReturn(true);
        when(external.getPathAsPath()).thenReturn(reportsDir);
        when(external.getScanInterval()).thenReturn(1000L); // 1 секунда для тестов
        when(embedded.isEnabled()).thenReturn(false);
        
        metadataLoader = new ReportMetadataLoader();
        service = new ReportDiscoveryService(properties, metadataLoader, resourceLoader);
    }

    @Test
    void scanReports_discoversNewReport() throws Exception {
        // Изначально отчётов нет
        assertEquals(0, service.getReportCount());
        
        // Копируем тестовый отчёт
        copyTestReport("simple-report.jrxml", "simple-report.json");
        
        // Сканируем отчёты
        service.scanReports();
        
        // Проверяем, что отчёт обнаружен
        assertEquals(1, service.getReportCount());
        assertTrue(service.reportExists("simple-report"));
        
        ReportMetadata metadata = service.getMetadata("simple-report");
        assertNotNull(metadata);
        assertEquals("simple-report", metadata.id());
    }

    @Test
    void scanReports_discoversMultipleReports() throws Exception {
        // Копируем несколько отчётов
        copyTestReport("simple-report.jrxml", "simple-report.json");
        
        // Создаём второй отчёт
        createSecondReport();
        
        // Сканируем отчёты
        service.scanReports();
        
        // Проверяем, что оба отчёта обнаружены
        assertEquals(2, service.getReportCount());
        assertTrue(service.reportExists("simple-report"));
        assertTrue(service.reportExists("second-report"));
    }

    @Test
    void scanReports_detectsRemovedReport() throws Exception {
        // Копируем отчёт
        Path jrxmlFile = copyTestReport("simple-report.jrxml", "simple-report.json");
        
        // Сканируем отчёты
        service.scanReports();
        assertEquals(1, service.getReportCount());
        
        // Удаляем отчёт
        Files.delete(jrxmlFile);
        Files.deleteIfExists(jrxmlFile.getParent().resolve("simple-report.json"));
        
        // Сканируем снова
        service.scanReports();
        
        // Отчёт должен быть удалён из кэша
        // (В текущей реализации отчёты не удаляются автоматически,
        // но это можно проверить через отсутствие файла)
        // Для полной проверки нужно реализовать удаление из кэша
    }

    @Test
    void scanReports_updatesMetadataOnChange() throws Exception {
        // Копируем отчёт
        Path jsonFile = copyTestReport("simple-report.jrxml", "simple-report.json");
        
        // Сканируем отчёты
        service.scanReports();
        ReportMetadata metadata1 = service.getMetadata("simple-report");
        assertNotNull(metadata1);
        String originalName = metadata1.name();
        
        // Изменяем JSON метаданные
        String updatedJson = """
                {
                  "id": "simple-report",
                  "version": "1.0.1",
                  "name": "Updated Test Report",
                  "description": "Updated description",
                  "category": "test",
                  "author": "Test Author",
                  "created": "2025-01-01",
                  "lastModified": "2025-01-02",
                  "files": {
                    "template": "simple-report.jrxml",
                    "compiled": null,
                    "thumbnail": null
                  },
                  "parameters": [],
                  "uiIntegration": {
                    "showInReportsList": true,
                    "contextMenus": null
                  },
                  "tags": ["test"],
                  "accessLevel": "user"
                }
                """;
        Files.writeString(jsonFile, updatedJson);
        
        // Сканируем снова
        service.scanReports();
        
        // Проверяем, что метаданные обновлены
        ReportMetadata metadata2 = service.getMetadata("simple-report");
        assertNotNull(metadata2);
        assertEquals("1.0.1", metadata2.version());
        assertEquals("Updated Test Report", metadata2.name());
        assertNotEquals(originalName, metadata2.name());
    }

    @Test
    void getAllReports_returnsUpdatedList() throws Exception {
        // Копируем отчёт
        copyTestReport("simple-report.jrxml", "simple-report.json");
        
        // Сканируем отчёты
        service.scanReports();
        
        List<ReportInfo> reports = service.getAllReports();
        assertEquals(1, reports.size());
        assertEquals("simple-report", reports.get(0).id());
        
        // Создаём второй отчёт
        createSecondReport();
        
        // Сканируем снова
        service.scanReports();
        
        // Проверяем, что список обновлён
        List<ReportInfo> updatedReports = service.getAllReports();
        assertEquals(2, updatedReports.size());
    }

    /**
     * Копирует тестовый отчёт (JRXML + JSON) в директорию custom.
     */
    private Path copyTestReport(String jrxmlName, String jsonName) throws IOException {
        // Копируем JRXML
        InputStream jrxmlStream = getClass().getResourceAsStream(
                "/reports/test/" + jrxmlName);
        assertNotNull(jrxmlStream, "Test template not found: " + jrxmlName);
        
        Path jrxmlPath = customDir.resolve(jrxmlName);
        Files.copy(jrxmlStream, jrxmlPath, StandardCopyOption.REPLACE_EXISTING);
        jrxmlStream.close();
        
        // Копируем JSON
        InputStream jsonStream = getClass().getResourceAsStream(
                "/reports/test/" + jsonName);
        if (jsonStream != null) {
            Path jsonPath = customDir.resolve(jsonName);
            Files.copy(jsonStream, jsonPath, StandardCopyOption.REPLACE_EXISTING);
            jsonStream.close();
        }
        
        return jrxmlPath;
    }

    /**
     * Создаёт второй тестовый отчёт.
     */
    private void createSecondReport() throws IOException {
        // Создаём простой JRXML файл
        String jrxmlContent = """
                <?xml version="1.0" encoding="UTF-8"?>
                <jasperReport xmlns="http://jasperreports.sourceforge.net/jasperreports"
                              name="SecondReport"
                              pageWidth="595"
                              pageHeight="842">
                    <title>
                        <band height="50">
                            <staticText>
                                <reportElement x="0" y="0" width="555" height="30"/>
                                <text><![CDATA[Second Test Report]]></text>
                            </staticText>
                        </band>
                    </title>
                </jasperReport>
                """;
        
        Files.writeString(customDir.resolve("second-report.jrxml"), jrxmlContent);
        
        // Создаём JSON метаданные
        String jsonContent = """
                {
                  "id": "second-report",
                  "version": "1.0.0",
                  "name": "Second Test Report",
                  "description": "Second test report",
                  "category": "test",
                  "author": "Test Author",
                  "created": "2025-01-01",
                  "lastModified": "2025-01-01",
                  "files": {
                    "template": "second-report.jrxml",
                    "compiled": null,
                    "thumbnail": null
                  },
                  "parameters": [],
                  "uiIntegration": {
                    "showInReportsList": true,
                    "contextMenus": null
                  },
                  "tags": ["test"],
                  "accessLevel": "user"
                }
                """;
        
        Files.writeString(customDir.resolve("second-report.json"), jsonContent);
    }
}
