package com.femsq.database.model.relation;

import java.util.List;

/**
 * Строка обхода: PK целевой таблицы и поля.
 *
 * @param key PK
 * @param fields колонки
 */
public record RelationRow(int key, List<RelationField> fields) {
}
