package com.femsq.reports.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportGenerationRequest;
import com.femsq.reports.model.ReportMetadata;
import com.femsq.reports.model.ReportResult;
import net.sf.jasperreports.engine.JRException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeoutException;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Интеграционные тесты для генерации отчётов через {@link ReportController}.
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
        "reports.embedded.enabled=false",
        "reports.compilation.cache-enabled=true",
        "reports.generation.timeout=300000",
        "reports.generation.max-concurrent=5"
})
class ReportControllerGenerateIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private com.femsq.reports.core.ReportDiscoveryService discoveryService;

    @MockBean
    private com.femsq.reports.core.ReportGenerationService generationService;

    @MockBean
    private com.femsq.reports.core.ReportMetadataLoader metadataLoader;

    @BeforeEach
    void setUp() {
        // Базовая настройка моков
    }

    @Test
    void generateReport_withValidRequest_returnsPdf() throws Exception {
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
        
        byte[] pdfContent = "PDF content".getBytes();
        ReportResult result = new ReportResult(
                "test-report",
                "pdf",
                pdfContent,
                LocalDateTime.now(),
                "test-report.pdf",
                pdfContent.length
        );
        
        when(discoveryService.getMetadata("test-report")).thenReturn(metadata);
        when(generationService.generateReport(any(ReportGenerationRequest.class)))
                .thenReturn(result);

        ReportGenerationRequest request = new ReportGenerationRequest(
                "test-report",
                Map.of("param1", "value1"),
                "pdf"
        );

        mockMvc.perform(post("/api/reports/test-report/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_PDF))
                .andExpect(header().exists("Content-Disposition"))
                .andExpect(content().bytes(pdfContent));
    }

    @Test
    void generateReport_withInvalidReportId_returnsBadRequest() throws Exception {
        ReportGenerationRequest request = new ReportGenerationRequest(
                "different-id",
                Map.of(),
                "pdf"
        );

        mockMvc.perform(post("/api/reports/test-report/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void generateReport_withInvalidFormat_returnsBadRequest() throws Exception {
        ReportGenerationRequest request = new ReportGenerationRequest(
                "test-report",
                Map.of(),
                "invalid-format"
        );

        mockMvc.perform(post("/api/reports/test-report/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void generateReport_whenReportNotFound_returnsBadRequest() throws Exception {
        when(discoveryService.getMetadata("non-existent")).thenReturn(null);

        ReportGenerationRequest request = new ReportGenerationRequest(
                "non-existent",
                Map.of(),
                "pdf"
        );

        mockMvc.perform(post("/api/reports/non-existent/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void generateReport_whenGenerationFails_returnsInternalServerError() throws Exception {
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
        when(generationService.generateReport(any(ReportGenerationRequest.class)))
                .thenThrow(new JRException("Generation failed"));

        ReportGenerationRequest request = new ReportGenerationRequest(
                "test-report",
                Map.of(),
                "pdf"
        );

        mockMvc.perform(post("/api/reports/test-report/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isInternalServerError());
    }

    @Test
    void generatePreview_withValidRequest_returnsPdf() throws Exception {
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
        
        byte[] pdfContent = "PDF preview".getBytes();
        ReportResult result = new ReportResult(
                "test-report",
                "pdf",
                pdfContent,
                LocalDateTime.now(),
                "test-report-preview.pdf",
                pdfContent.length
        );
        
        when(discoveryService.getMetadata("test-report")).thenReturn(metadata);
        when(generationService.generatePreview(anyString(), any(Map.class)))
                .thenReturn(result);

        mockMvc.perform(post("/api/reports/test-report/preview")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_PDF))
                .andExpect(header().exists("Content-Disposition"))
                .andExpect(content().bytes(pdfContent));
    }

    @Test
    void generatePreview_whenReportNotFound_returnsBadRequest() throws Exception {
        when(discoveryService.getMetadata("non-existent")).thenReturn(null);

        mockMvc.perform(post("/api/reports/non-existent/preview")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
