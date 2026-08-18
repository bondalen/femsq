package com.femsq.database.model.relation;

/**
 * Поле строки expand/get.
 *
 * @param name имя колонки
 * @param value строковое значение или {@code null}
 */
public record RelationField(String name, String value) {
}
