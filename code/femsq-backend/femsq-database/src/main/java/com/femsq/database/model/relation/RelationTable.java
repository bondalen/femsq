package com.femsq.database.model.relation;

import java.util.List;

/**
 * Таблица, доступная через {@code relationNode}.
 *
 * @param name имя в JSON ({@code invNum})
 * @param schema схема ({@code ags} / {@code sudz})
 * @param table физическое имя
 * @param pk колонка PK
 * @param columns колонки SELECT
 */
public record RelationTable(
        String name,
        String schema,
        String table,
        String pk,
        List<String> columns
) {
}
