package com.femsq.database.model;

/**
 * Поколоночный фильтр страницы номеров договоров.
 * Пустая строка поле не сужает.
 *
 * @param cnnNum подстрока номера
 * @param cnnTypeName подстрока имени типа
 */
public record CnNumColumnFilters(
        String cnnNum,
        String cnnTypeName
) {
}
