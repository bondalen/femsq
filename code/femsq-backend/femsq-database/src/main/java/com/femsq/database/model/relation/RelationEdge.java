package com.femsq.database.model.relation;

/**
 * Ребро каталога: как читать связанные строки.
 *
 * @param name имя в JSON ({@code invNum.inv})
 * @param from таблица-источник
 * @param to таблица-назначение
 * @param fromJoin колонка на from, равная PK to (для N:1 / 1:1)
 * @param toJoin колонка на to, равная PK from (для 1:N)
 * @param card кардинальность в БД
 */
public record RelationEdge(
        String name,
        RelationTable from,
        RelationTable to,
        String fromJoin,
        String toJoin,
        RelationCard card
) {
}
