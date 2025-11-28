package com.femsq.reports.model;

import java.util.List;
import java.util.Map;

/**
 * Описание параметра отчёта.
 * 
 * <p>Используется для валидации и генерации UI форм ввода параметров.
 * Содержит информацию о типе, валидации, значениях по умолчанию и источниках данных.
 * 
 * @param name          имя параметра (соответствует имени в JRXML)
 * @param type          тип параметра (date, long, integer, string, boolean, enum)
 * @param label         отображаемое имя параметра
 * @param description   описание/подсказка для пользователя
 * @param required      обязательность параметра
 * @param defaultValue  значение по умолчанию (может содержать выражения типа ${today})
 * @param validation    правила валидации (min, max, pattern, minDate, maxDate)
 * @param options       опции для enum типа
 * @param source        источник данных для загрузки опций (API endpoint)
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
public record ReportParameter(
        String name,
        String type,
        String label,
        String description,
        boolean required,
        String defaultValue,
        Validation validation,
        List<Option> options,
        Source source
) {
    /**
     * Правила валидации параметра.
     * 
     * @param minDate минимальная дата (для типа date)
     * @param maxDate максимальная дата (для типа date)
     * @param min     минимальное значение (для числовых типов)
     * @param max     максимальное значение (для числовых типов)
     * @param pattern регулярное выражение (для типа string)
     */
    public record Validation(
            String minDate,
            String maxDate,
            Number min,
            Number max,
            String pattern
    ) {
        /**
         * Создаёт пустую валидацию (без правил).
         * 
         * @return Validation без правил
         */
        public static Validation empty() {
            return new Validation(null, null, null, null, null);
        }
    }

    /**
     * Опция для enum типа параметра.
     * 
     * @param value значение опции
     * @param label отображаемое имя опции
     */
    public record Option(
            String value,
            String label
    ) {
    }

    /**
     * Источник данных для загрузки опций параметра.
     * 
     * @param type       тип источника ("api" - загрузка через REST API)
     * @param endpoint   URL endpoint для загрузки данных
     * @param valueField имя поля в ответе, содержащего значение
     * @param labelField имя поля в ответе, содержащего отображаемое имя
     */
    public record Source(
            String type,
            String endpoint,
            String valueField,
            String labelField
    ) {
    }

    /**
     * Создаёт простой параметр без валидации и источников.
     * 
     * @param name        имя параметра
     * @param type        тип параметра
     * @param label       отображаемое имя
     * @param description описание
     * @param required    обязательность
     * @return ReportParameter с пустой валидацией
     */
    public static ReportParameter simple(
            String name,
            String type,
            String label,
            String description,
            boolean required
    ) {
        return new ReportParameter(
                name,
                type,
                label,
                description,
                required,
                null,
                Validation.empty(),
                null,
                null
        );
    }
}
