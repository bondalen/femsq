package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperReport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit-тесты для {@link JasperReportsEngine}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class JasperReportsEngineTest {

    @Mock
    private ReportsProperties properties;

    @Mock
    private ReportsProperties.Compilation compilation;

    @TempDir
    Path tempDir;

    private JasperReportsEngine engine;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        when(properties.getCompilation()).thenReturn(compilation);
        when(compilation.isCacheEnabled()).thenReturn(true);
        when(compilation.getCacheDirectoryAsPath()).thenReturn(tempDir.resolve("cache"));
        when(compilation.isRecompileOnChange()).thenReturn(true);
        
        engine = new JasperReportsEngine(properties);
    }

    @Test
    void clearAllCache_whenCalled_clearsCache() {
        engine.clearAllCache();
        
        int size = engine.getCacheSize();
        assertEquals(0, size);
    }

    @Test
    void getCacheSize_whenEmpty_returnsZero() {
        int size = engine.getCacheSize();
        
        assertEquals(0, size);
    }

    @Test
    void clearCache_whenFileNotInCache_doesNotThrow() {
        Path jrxmlPath = tempDir.resolve("test.jrxml");
        
        assertDoesNotThrow(() -> engine.clearCache(jrxmlPath));
    }
}
