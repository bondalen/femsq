package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportInfo;
import com.femsq.reports.model.ReportMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.core.io.ResourceLoader;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit-тесты для {@link ReportDiscoveryService}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportDiscoveryServiceTest {

    @Mock
    private ReportsProperties properties;

    @Mock
    private ReportsProperties.External external;

    @Mock
    private ReportsProperties.Embedded embedded;

    @Mock
    private ReportMetadataLoader metadataLoader;

    @Mock
    private ResourceLoader resourceLoader;

    private ReportDiscoveryService service;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        when(properties.getExternal()).thenReturn(external);
        when(properties.getEmbedded()).thenReturn(embedded);
        when(external.isEnabled()).thenReturn(false);
        when(embedded.isEnabled()).thenReturn(false);
        
        service = new ReportDiscoveryService(properties, metadataLoader, resourceLoader);
    }

    @Test
    void getAllReports_whenNoReports_returnsEmptyList() {
        List<ReportInfo> reports = service.getAllReports();
        
        assertTrue(reports.isEmpty());
    }

    @Test
    void getReports_withCategoryFilter_returnsFilteredList() {
        List<ReportInfo> reports = service.getReports("category1", null);
        
        assertNotNull(reports);
        assertTrue(reports.isEmpty());
    }

    @Test
    void getReports_withTagFilter_returnsFilteredList() {
        List<ReportInfo> reports = service.getReports(null, "tag1");
        
        assertNotNull(reports);
        assertTrue(reports.isEmpty());
    }

    @Test
    void getMetadata_whenReportNotExists_returnsNull() {
        ReportMetadata metadata = service.getMetadata("non-existent");
        
        assertNull(metadata);
    }

    @Test
    void reportExists_whenReportNotExists_returnsFalse() {
        boolean exists = service.reportExists("non-existent");
        
        assertFalse(exists);
    }

    @Test
    void getReportCount_whenNoReports_returnsZero() {
        int count = service.getReportCount();
        
        assertEquals(0, count);
    }

    @Test
    void getAllCategories_whenNoReports_returnsEmptyList() {
        List<String> categories = service.getAllCategories();
        
        assertTrue(categories.isEmpty());
    }

    @Test
    void getAllTags_whenNoReports_returnsEmptyList() {
        List<String> tags = service.getAllTags();
        
        assertTrue(tags.isEmpty());
    }
}
