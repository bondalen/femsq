package com.femsq.reports.model;

import java.time.LocalDateTime;

/**
 * Результат генерации отчёта.
 * 
 * <p>Содержит сгенерированный контент отчёта в виде байтов,
 * метаданные о генерации и информацию об отчёте.
 * 
 * @param reportId    идентификатор отчёта
 * @param format      формат сгенерированного отчёта (pdf, excel, html)
 * @param content     содержимое отчёта в виде массива байтов
 * @param generatedAt дата и время генерации
 * @param fileName    рекомендуемое имя файла для сохранения
 * @param size        размер файла в байтах
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
public record ReportResult(
        String reportId,
        String format,
        byte[] content,
        LocalDateTime generatedAt,
        String fileName,
        long size
) {
    /**
     * Создаёт результат генерации с автоматическим определением имени файла.
     * 
     * @param reportId    идентификатор отчёта
     * @param format      формат отчёта
     * @param content     содержимое отчёта
     * @param generatedAt дата генерации
     * @return ReportResult с автоматически сгенерированным именем файла
     */
    public static ReportResult withAutoFileName(
            String reportId,
            String format,
            byte[] content,
            LocalDateTime generatedAt
    ) {
        String extension = switch (format.toLowerCase()) {
            case "pdf" -> "pdf";
            case "excel", "xls", "xlsx" -> "xlsx";
            case "html" -> "html";
            default -> "bin";
        };
        
        String fileName = String.format("%s-%s.%s", 
                reportId, 
                generatedAt.toString().replace(":", "-"), 
                extension);
        
        return new ReportResult(
                reportId,
                format,
                content,
                generatedAt,
                fileName,
                content.length
        );
    }

    /**
     * Создаёт результат генерации с текущим временем.
     * 
     * @param reportId идентификатор отчёта
     * @param format   формат отчёта
     * @param content  содержимое отчёта
     * @return ReportResult с текущим временем генерации
     */
    public static ReportResult now(String reportId, String format, byte[] content) {
        return withAutoFileName(reportId, format, content, LocalDateTime.now());
    }

    /**
     * Получает MIME тип для формата отчёта.
     * 
     * @return MIME тип (application/pdf, application/vnd.ms-excel, text/html)
     */
    public String getMimeType() {
        return switch (format.toLowerCase()) {
            case "pdf" -> "application/pdf";
            case "excel", "xls", "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            case "html" -> "text/html";
            default -> "application/octet-stream";
        };
    }
}
