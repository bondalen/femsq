package com.femsq.database.dao;

import com.femsq.database.model.relation.RelationEdge;
import com.femsq.database.model.relation.RelationQueryDefinition;
import com.femsq.database.model.relation.RelationRow;
import com.femsq.database.model.relation.RelationTable;
import java.util.List;
import java.util.Optional;

/**
 * Чтение строк по каталогу рёбер (без знания экранов).
 */
public interface RelationDao {

    /**
     * Строка таблицы по PK.
     *
     * @param table таблица из каталога
     * @param id PK
     * @return строка или empty
     */
    Optional<RelationRow> findNode(RelationTable table, int id);

    /**
     * Связанные строки по ребру.
     *
     * @param edge ребро из каталога
     * @param fromId PK таблицы from
     * @return 0..N строк to
     */
    List<RelationRow> expand(RelationEdge edge, int fromId);

    /**
     * Именованный SELECT из {@link com.femsq.database.relation.RelationQueryCatalog}.
     *
     * @param definition запрос
     * @param fromId bind первого {@code ?}
     * @return строки
     */
    List<RelationRow> runQuery(RelationQueryDefinition definition, int fromId);
}
