package com.femsq.reports.core;

import com.femsq.reports.model.ReportParameter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit-тесты для {@link ReportMetadataLoader}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
class ReportMetadataLoaderTest {

    private ReportMetadataLoader loader;

    @BeforeEach
    void setUp() {
        loader = new ReportMetadataLoader();
    }

    @Test
    void parseDynamicValue_today_returnsCurrentDate() {
        String result = loader.parseDynamicValue("${today}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-\\d{2}"));
    }

    @Test
    void parseDynamicValue_yesterday_returnsYesterdayDate() {
        String result = loader.parseDynamicValue("${yesterday}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-\\d{2}"));
    }

    @Test
    void parseDynamicValue_firstDayOfMonth_returnsFirstDay() {
        String result = loader.parseDynamicValue("${firstDayOfMonth}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-01"));
    }

    @Test
    void parseDynamicValue_lastDayOfMonth_returnsLastDay() {
        String result = loader.parseDynamicValue("${lastDayOfMonth}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-\\d{2}"));
    }

    @Test
    void parseDynamicValue_firstDayOfQuarter_returnsFirstDay() {
        String result = loader.parseDynamicValue("${firstDayOfQuarter}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-\\d{2}"));
    }

    @Test
    void parseDynamicValue_lastDayOfQuarter_returnsLastDay() {
        String result = loader.parseDynamicValue("${lastDayOfQuarter}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-\\d{2}-\\d{2}"));
    }

    @Test
    void parseDynamicValue_firstDayOfYear_returnsFirstDay() {
        String result = loader.parseDynamicValue("${firstDayOfYear}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-01-01"));
    }

    @Test
    void parseDynamicValue_lastDayOfYear_returnsLastDay() {
        String result = loader.parseDynamicValue("${lastDayOfYear}");
        
        assertNotNull(result);
        assertTrue(result.matches("\\d{4}-12-31"));
    }

    @Test
    void parseDynamicValue_unknownExpression_returnsOriginal() {
        String result = loader.parseDynamicValue("${unknown}");
        
        assertEquals("${unknown}", result);
    }

    @Test
    void parseDynamicValue_nonExpression_returnsOriginal() {
        String result = loader.parseDynamicValue("plain text");
        
        assertEquals("plain text", result);
    }

    @Test
    void parseDynamicValue_null_returnsNull() {
        String result = loader.parseDynamicValue(null);
        
        assertNull(result);
    }

    @Test
    void resolveDefaultValues_withContext_resolvesContextValues() {
        List<ReportParameter> parameters = List.of(
                new ReportParameter(
                        "contractorId",
                        "string",
                        "Contractor ID",
                        null,
                        false,
                        "${contractorId}",
                        null,
                        null,
                        null
                )
        );
        
        Map<String, String> context = Map.of("contractorId", "123");
        
        List<ReportParameter> resolved = loader.resolveDefaultValues(parameters, context);
        
        assertEquals(1, resolved.size());
        assertEquals("123", resolved.get(0).defaultValue());
    }

    @Test
    void resolveDefaultValues_emptyList_returnsEmptyList() {
        List<ReportParameter> result = loader.resolveDefaultValues(List.of(), Map.of());
        
        assertTrue(result.isEmpty());
    }

    @Test
    void resolveDefaultValues_nullList_returnsEmptyList() {
        List<ReportParameter> result = loader.resolveDefaultValues(null, Map.of());
        
        assertTrue(result.isEmpty());
    }
}
