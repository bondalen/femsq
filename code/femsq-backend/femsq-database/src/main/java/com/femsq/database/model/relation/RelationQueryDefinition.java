package com.femsq.database.model.relation;

/**
 * Именованный read-only запрос для relation-дерева (реестр на backend).
 *
 * @param id идентификатор для JSON ({@code sudz.invDbtVar.contextBySlot})
 * @param sql параметризованный SELECT с одним {@code ?} (fromId)
 * @param keyColumn имя колонки PK в ResultSet
 * @param maxRows верхняя граница строк
 */
public record RelationQueryDefinition(
        String id,
        String sql,
        String keyColumn,
        int maxRows
) {
    /**
     * @param id идентификатор
     * @param sql SQL
     * @param keyColumn PK-колонка
     */
    public RelationQueryDefinition(String id, String sql, String keyColumn) {
        this(id, sql, keyColumn, 50);
    }
}
