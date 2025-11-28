package com.femsq.reports.core;

import com.femsq.reports.model.ReportMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Интеграционные тесты для {@link ReportMetadataLoader} с реальными JSON и JRXML файлами.
 * 
 * <p>Использует реальные файлы из test/resources для проверки
 * загрузки метаданных и извлечения параметров из JRXML.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportMetadataLoaderWithRealFilesTest {

    private ReportMetadataLoader loader;

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
        loader = new ReportMetadataLoader();
    }

    @Test
    void loadFromJsonForJrxml_withRealJson_loadsMetadata() throws Exception {
        // Копируем тестовые файлы во временную директорию
        Path jrxmlPath = copyTestFile("simple-report.jrxml");
        Path jsonPath = copyTestFile("simple-report.json");
        
        // Загружаем метаданные из JSON
        ReportMetadata metadata = loader.loadFromJsonForJrxml(jrxmlPath);
        
        assertNotNull(metadata);
        assertEquals("simple-report", metadata.id());
        assertEquals("Simple Test Report", metadata.name());
        assertEquals("1.0.0", metadata.version());
        assertNotNull(metadata.parameters());
        assertEquals(2, metadata.parameters().size());
    }

    @Test
    void loadMetadata_withRealJson_prioritizesJson() throws Exception {
        // Копируем тестовые файлы во временную директорию
        Path jrxmlPath = copyTestFile("simple-report.jrxml");
        copyTestFile("simple-report.json");
        
        // Загружаем метаданные (должен использовать JSON)
        ReportMetadata metadata = loader.loadMetadata(jrxmlPath);
        
        assertNotNull(metadata);
        assertEquals("simple-report", metadata.id());
        assertEquals("Simple Test Report", metadata.name());
        // Проверяем, что параметры загружены из JSON
        assertNotNull(metadata.parameters());
        assertEquals(2, metadata.parameters().size());
    }

    @Test
    void extractFromJrxml_withRealJrxml_extractsParameters() throws Exception {
        // Копируем только JRXML файл (без JSON)
        Path jrxmlPath = copyTestFile("simple-report.jrxml");
        
        // Извлекаем метаданные из JRXML
        ReportMetadata metadata = loader.extractFromJrxml(jrxmlPath);
        
        assertNotNull(metadata);
        // Проверяем, что параметры извлечены из JRXML
        assertNotNull(metadata.parameters());
        // simple-report.jrxml содержит параметры "title" и "message"
        assertTrue(metadata.parameters().size() >= 2);
    }

    @Test
    void loadMetadata_withOnlyJrxml_fallsBackToJrxml() throws Exception {
        // Копируем только JRXML файл (без JSON)
        Path jrxmlPath = copyTestFile("simple-report.jrxml");
        
        // Загружаем метаданные (должен использовать JRXML как fallback)
        ReportMetadata metadata = loader.loadMetadata(jrxmlPath);
        
        assertNotNull(metadata);
        // Проверяем, что метаданные извлечены из JRXML
        assertNotNull(metadata.id());
    }

    /**
     * Копирует тестовый файл из resources во временную директорию.
     */
    private Path copyTestFile(String fileName) throws IOException {
        InputStream fileStream = getClass().getResourceAsStream(
                "/reports/test/" + fileName);
        
        if (fileStream == null) {
            // Если файл не найден, возвращаем путь, но не создаём файл
            return tempDir.resolve(fileName);
        }
        
        Path filePath = tempDir.resolve(fileName);
        Files.copy(fileStream, filePath, StandardCopyOption.REPLACE_EXISTING);
        fileStream.close();
        
        return filePath;
    }
}
