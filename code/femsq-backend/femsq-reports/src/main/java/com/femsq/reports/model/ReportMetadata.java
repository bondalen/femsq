package com.femsq.reports.model;

import java.util.List;
import java.util.Map;

/**
 * Полные метаданные отчёта.
 * 
 * <p>Содержит всю информацию об отчёте: параметры, файлы, интеграцию с UI,
 * категорию, теги, уровень доступа и т.д.
 * 
 * <p>Загружается из JSON файла рядом с JRXML шаблоном или извлекается
 * из самого JRXML файла (fallback).
 * 
 * @param id              уникальный идентификатор отчёта
 * @param version         версия отчёта (semantic versioning)
 * @param name            отображаемое имя отчёта
 * @param description     описание назначения отчёта
 * @param category        категория (contractors, objects, analytics, finance)
 * @param author          автор отчёта
 * @param created         дата создания
 * @param lastModified    дата последнего изменения
 * @param files           информация о файлах отчёта
 * @param parameters      список параметров отчёта
 * @param uiIntegration   настройки интеграции с UI
 * @param tags            теги для фильтрации
 * @param accessLevel     уровень доступа (user, manager, admin)
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
public record ReportMetadata(
        String id,
        String version,
        String name,
        String description,
        String category,
        String author,
        String created,
        String lastModified,
        Files files,
        List<ReportParameter> parameters,
        UiIntegration uiIntegration,
        List<String> tags,
        String accessLevel
) {
    /**
     * Информация о файлах отчёта.
     * 
     * @param template  имя JRXML файла шаблона
     * @param compiled  имя прекомпилированного .jasper файла (опционально)
     * @param thumbnail путь к превью изображению (опционально)
     */
    public record Files(
            String template,
            String compiled,
            String thumbnail
    ) {
    }

    /**
     * Настройки интеграции с UI компонентами.
     * 
     * @param showInReportsList показывать ли в каталоге отчётов
     * @param contextMenus      список контекстных меню для компонентов
     */
    public record UiIntegration(
            boolean showInReportsList,
            List<ContextMenu> contextMenus
    ) {
        /**
         * Контекстное меню для компонента UI.
         * 
         * @param component        имя Vue компонента
         * @param label            текст пункта меню
         * @param icon             иконка (опционально)
         * @param parameterMapping маппинг параметров из контекста компонента
         */
        public record ContextMenu(
                String component,
                String label,
                String icon,
                Map<String, String> parameterMapping
        ) {
        }
    }

    /**
     * Создаёт минимальные метаданные с базовой информацией.
     * 
     * @param id          идентификатор
     * @param name        имя
     * @param description описание
     * @param template    имя файла шаблона
     * @return ReportMetadata с минимальными данными
     */
    public static ReportMetadata minimal(
            String id,
            String name,
            String description,
            String template
    ) {
        return new ReportMetadata(
                id,
                "1.0.0",
                name,
                description,
                null,
                null,
                null,
                null,
                new Files(template, null, null),
                List.of(),
                new UiIntegration(true, List.of()),
                List.of(),
                "user"
        );
    }
}
