package com.femsq.reports.api;

import com.femsq.reports.model.ReportInfo;
import com.femsq.reports.model.ReportMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Path;
import java.util.List;
import java.util.Objects;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Интеграционные тесты для {@link ReportController}.
 * 
 * <p>Использует @SpringBootTest для поднятия полного контекста Spring
 * и MockMvc для тестирования REST endpoints.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "reports.external.enabled=true",
        "reports.external.path=./reports",
        "reports.external.scan-interval=60000",
        "reports.embedded.enabled=false",
        "reports.compilation.cache-enabled=true",
        "reports.compilation.cache-directory=./reports/cache",
        "reports.compilation.recompile-on-change=true",
        "reports.generation.timeout=300000",
        "reports.generation.max-concurrent=5",
        "reports.generation.temp-directory=./temp/reports"
})
class ReportControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private com.femsq.reports.core.ReportDiscoveryService discoveryService;

    @MockitoBean
    private com.femsq.reports.core.ReportGenerationService generationService;

    @MockitoBean
    private com.femsq.reports.core.ReportMetadataLoader metadataLoader;

    @TempDir
    Path tempDir;

    @NonNull
    private static final MediaType APPLICATION_JSON = Objects.requireNonNull(MediaType.APPLICATION_JSON);

    @BeforeEach
    void setUp() throws Exception {
        // Настройка моков для базовых сценариев
        when(discoveryService.getAllReports()).thenReturn(List.of());
        when(discoveryService.getReports(anyString(), anyString())).thenReturn(List.of());
        when(discoveryService.getMetadata(anyString())).thenReturn(null);
        when(discoveryService.getAllCategories()).thenReturn(List.of());
        when(discoveryService.getAllTags()).thenReturn(List.of());
    }

    @Test
    void getAvailableReports_returnsOk() throws Exception {
        ReportInfo reportInfo = new ReportInfo(
                "test-report",
                "Test Report",
                "Test Description",
                "category1",
                List.of("tag1"),
                "external",
                null
        );
        
        when(discoveryService.getAllReports()).thenReturn(List.of(reportInfo));

        mockMvc.perform(get("/api/reports/available"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].id").value("test-report"))
                .andExpect(jsonPath("$[0].name").value("Test Report"));
    }

    @Test
    void getAvailableReports_withCategoryFilter_returnsFiltered() throws Exception {
        ReportInfo reportInfo = new ReportInfo(
                "test-report",
                "Test Report",
                "Test Description",
                "category1",
                List.of(),
                "external",
                null
        );
        
        when(discoveryService.getReports("category1", null)).thenReturn(List.of(reportInfo));

        mockMvc.perform(get("/api/reports/available")
                        .param("category", "category1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].category").value("category1"));
    }

    @Test
    void getAvailableReports_withTagFilter_returnsFiltered() throws Exception {
        ReportInfo reportInfo = new ReportInfo(
                "test-report",
                "Test Report",
                "Test Description",
                "category1",
                List.of("tag1"),
                "external",
                null
        );
        
        when(discoveryService.getReports(null, "tag1")).thenReturn(List.of(reportInfo));

        mockMvc.perform(get("/api/reports/available")
                        .param("tag", "tag1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void getReportMetadata_whenReportExists_returnsMetadata() throws Exception {
        ReportMetadata metadata = new ReportMetadata(
                "test-report",
                "1.0.0",
                "Test Report",
                "Test Description",
                "category1",
                "Test Author",
                "2025-01-01",
                "2025-01-01",
                new ReportMetadata.Files("template.jrxml", null, null),
                List.of(),
                null,
                List.of(),
                "user"
        );
        
        when(discoveryService.getMetadata("test-report")).thenReturn(metadata);

        mockMvc.perform(get("/api/reports/test-report/metadata"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value("test-report"))
                .andExpect(jsonPath("$.name").value("Test Report"))
                .andExpect(jsonPath("$.version").value("1.0.0"));
    }

    @Test
    void getReportMetadata_whenReportNotExists_returnsNotFound() throws Exception {
        when(discoveryService.getMetadata("non-existent")).thenReturn(null);

        mockMvc.perform(get("/api/reports/non-existent/metadata"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getReportParameters_whenReportExists_returnsParameters() throws Exception {
        ReportMetadata metadata = new ReportMetadata(
                "test-report",
                "1.0.0",
                "Test Report",
                "Test Description",
                "category1",
                "Test Author",
                "2025-01-01",
                "2025-01-01",
                new ReportMetadata.Files("template.jrxml", null, null),
                List.of(),
                null,
                List.of(),
                "user"
        );
        
        when(discoveryService.getMetadata("test-report")).thenReturn(metadata);
        when(metadataLoader.resolveDefaultValues(any(), any())).thenReturn(List.of());

        mockMvc.perform(get("/api/reports/test-report/parameters"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void getReportParameters_whenReportNotExists_returnsNotFound() throws Exception {
        when(discoveryService.getMetadata("non-existent")).thenReturn(null);

        mockMvc.perform(get("/api/reports/non-existent/parameters"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getCategories_returnsList() throws Exception {
        when(discoveryService.getAllCategories()).thenReturn(List.of("category1", "category2"));

        mockMvc.perform(get("/api/reports/categories"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0]").value("category1"))
                .andExpect(jsonPath("$[1]").value("category2"));
    }

    @Test
    void getTags_returnsList() throws Exception {
        when(discoveryService.getAllTags()).thenReturn(List.of("tag1", "tag2"));

        mockMvc.perform(get("/api/reports/tags"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0]").value("tag1"))
                .andExpect(jsonPath("$[1]").value("tag2"));
    }
}
