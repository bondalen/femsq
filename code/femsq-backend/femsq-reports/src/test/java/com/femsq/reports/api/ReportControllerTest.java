package com.femsq.reports.api;

import com.femsq.reports.core.ReportDiscoveryService;
import com.femsq.reports.core.ReportGenerationService;
import com.femsq.reports.core.ReportMetadataLoader;
import com.femsq.reports.model.ReportInfo;
import com.femsq.reports.model.ReportMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Objects;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit-тесты для {@link ReportController}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportControllerTest {

    @Mock
    private ReportDiscoveryService discoveryService;

    @Mock
    private ReportGenerationService generationService;

    @Mock
    private ReportMetadataLoader metadataLoader;

    private ReportController controller;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        controller = new ReportController(discoveryService, generationService, metadataLoader);
    }

    @Test
    void getAvailableReports_whenNoReports_returnsEmptyList() {
        when(discoveryService.getAllReports()).thenReturn(List.of());
        
        ResponseEntity<List<ReportInfo>> response = controller.getAvailableReports(null, null);
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        List<ReportInfo> body = Objects.requireNonNull(response.getBody());
        assertTrue(body.isEmpty());
    }

    @Test
    void getAvailableReports_withCategoryFilter_callsServiceWithFilter() {
        when(discoveryService.getReports("category1", null)).thenReturn(List.of());
        
        ResponseEntity<List<ReportInfo>> response = controller.getAvailableReports("category1", null);
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(discoveryService).getReports("category1", null);
    }

    @Test
    void getReportMetadata_whenReportExists_returnsMetadata() {
        ReportMetadata metadata = createMetadata("test-report");
        when(discoveryService.getMetadata("test-report")).thenReturn(metadata);
        
        ResponseEntity<ReportMetadata> response = controller.getReportMetadata("test-report");
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        ReportMetadata body = Objects.requireNonNull(response.getBody());
        assertEquals("test-report", body.id());
    }

    @Test
    void getReportMetadata_whenReportNotExists_returnsNotFound() {
        when(discoveryService.getMetadata("non-existent")).thenReturn(null);
        
        ResponseEntity<ReportMetadata> response = controller.getReportMetadata("non-existent");
        
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    void getCategories_returnsList() {
        when(discoveryService.getAllCategories()).thenReturn(List.of("category1", "category2"));
        
        ResponseEntity<List<String>> response = controller.getCategories();
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        List<String> body = Objects.requireNonNull(response.getBody());
        assertEquals(2, body.size());
    }

    @Test
    void getTags_returnsList() {
        when(discoveryService.getAllTags()).thenReturn(List.of("tag1", "tag2"));
        
        ResponseEntity<List<String>> response = controller.getTags();
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        List<String> body = Objects.requireNonNull(response.getBody());
        assertEquals(2, body.size());
    }

    private ReportMetadata createMetadata(String id) {
        return new ReportMetadata(
                id,
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
    }
}
