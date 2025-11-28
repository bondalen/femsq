package com.femsq.reports.model;

import java.util.Map;

/**
 * Запрос на генерацию отчёта.
 * 
 * <p>Используется в REST API для передачи параметров генерации отчёта.
 * Содержит идентификатор отчёта, параметры и желаемый формат вывода.
 * 
 * @param reportId  идентификатор отчёта для генерации
 * @param parameters параметры отчёта (имя параметра → значение)
 * @param format    формат вывода (pdf, excel, html)
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
public record ReportGenerationRequest(
        String reportId,
        Map<String, Object> parameters,
        String format
) {
    /**
     * Создаёт запрос на генерацию PDF отчёта.
     * 
     * @param reportId   идентификатор отчёта
     * @param parameters параметры отчёта
     * @return ReportGenerationRequest с форматом PDF
     */
    public static ReportGenerationRequest pdf(String reportId, Map<String, Object> parameters) {
        return new ReportGenerationRequest(reportId, parameters, "pdf");
    }

    /**
     * Создаёт запрос на генерацию Excel отчёта.
     * 
     * @param reportId   идентификатор отчёта
     * @param parameters параметры отчёта
     * @return ReportGenerationRequest с форматом Excel
     */
    public static ReportGenerationRequest excel(String reportId, Map<String, Object> parameters) {
        return new ReportGenerationRequest(reportId, parameters, "excel");
    }

    /**
     * Создаёт запрос на генерацию HTML отчёта.
     * 
     * @param reportId   идентификатор отчёта
     * @param parameters параметры отчёта
     * @return ReportGenerationRequest с форматом HTML
     */
    public static ReportGenerationRequest html(String reportId, Map<String, Object> parameters) {
        return new ReportGenerationRequest(reportId, parameters, "html");
    }

    /**
     * Проверяет, является ли формат валидным.
     * 
     * @return true если формат поддерживается
     */
    public boolean isValidFormat() {
        return format != null && (format.equalsIgnoreCase("pdf") 
                || format.equalsIgnoreCase("excel") 
                || format.equalsIgnoreCase("html"));
    }
}
