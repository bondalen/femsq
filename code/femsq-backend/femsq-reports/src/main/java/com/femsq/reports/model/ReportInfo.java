package com.femsq.reports.model;

import java.util.List;

/**
 * DTO для представления информации об отчёте в списке доступных отчётов.
 * 
 * <p>Используется для отображения каталога отчётов в REST API и UI.
 * Содержит минимальную информацию, необходимую для выбора отчёта.
 * 
 * @param id          уникальный идентификатор отчёта
 * @param name        отображаемое имя отчёта
 * @param description краткое описание назначения отчёта
 * @param category    категория отчёта (contractors, objects, analytics, finance)
 * @param tags        теги для фильтрации и поиска
 * @param source      источник отчёта ("embedded" - встроенный, "external" - внешний)
 * @param thumbnail   путь к превью отчёта (опционально)
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
public record ReportInfo(
        String id,
        String name,
        String description,
        String category,
        List<String> tags,
        String source,
        String thumbnail
) {
    /**
     * Создаёт ReportInfo с пустым списком тегов.
     * 
     * @param id          идентификатор отчёта
     * @param name        имя отчёта
     * @param description описание
     * @param category    категория
     * @param source      источник
     * @param thumbnail   превью
     * @return ReportInfo с пустым списком тегов
     */
    public static ReportInfo withoutTags(
            String id,
            String name,
            String description,
            String category,
            String source,
            String thumbnail
    ) {
        return new ReportInfo(id, name, description, category, List.of(), source, thumbnail);
    }
}
