package com.femsq.database.model.relation;

/**
 * Кардинальность ребра в каталоге (как в JSON экземпляра).
 */
public enum RelationCard {
    /** Одна запись с обеих сторон. */
    ONE_TO_ONE,
    /** От from несколько to. */
    ONE_TO_MANY,
    /** Несколько from на один to. */
    MANY_TO_ONE
}
