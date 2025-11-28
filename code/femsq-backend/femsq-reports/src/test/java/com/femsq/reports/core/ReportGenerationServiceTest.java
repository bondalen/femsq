package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportGenerationRequest;
import com.femsq.reports.model.ReportMetadata;
import com.femsq.reports.model.ReportResult;
import net.sf.jasperreports.engine.JRException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.core.io.ResourceLoader;

import javax.sql.DataSource;
import java.nio.file.Paths;
import java.util.Map;
import java.util.concurrent.TimeoutException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit-тесты для {@link ReportGenerationService}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportGenerationServiceTest {

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
    private ResourceLoader resourceLoader;

    private ReportGenerationService service;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        when(properties.getGeneration()).thenReturn(generation);
        when(properties.getEmbedded()).thenReturn(embedded);
        when(generation.getMaxConcurrent()).thenReturn(5);
        when(generation.getTimeout()).thenReturn(300000L);
        when(generation.getTempDirectoryAsPath()).thenReturn(Paths.get("target/test-temp-generation"));
        when(embedded.getPath()).thenReturn("classpath:reports/embedded");
        
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
    void getMaxConcurrent_returnsConfiguredValue() {
        int maxConcurrent = service.getMaxConcurrent();
        
        assertEquals(5, maxConcurrent);
    }

    @Test
    void getActiveGenerations_whenNoActive_returnsZero() {
        int active = service.getActiveGenerations();
        
        assertEquals(0, active);
    }
}
