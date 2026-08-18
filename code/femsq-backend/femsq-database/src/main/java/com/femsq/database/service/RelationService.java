package com.femsq.database.service;

import com.femsq.database.model.relation.RelationRow;
import java.util.List;
import java.util.Optional;

/**
 * Обход связей по каталогу рёбер.
 */
public interface RelationService {

    /**
     * Строка таблицы каталога.
     *
     * @param table имя JSON
     * @param id PK
     * @return строка
     */
    Optional<RelationRow> getNode(String table, int id);

    /**
     * Раскрытие ребра.
     *
     * @param edge имя JSON
     * @param fromId PK from
     * @return строки to
     */
    List<RelationRow> expand(String edge, int fromId);
}
