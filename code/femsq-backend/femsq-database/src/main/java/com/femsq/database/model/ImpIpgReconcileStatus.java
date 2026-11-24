package com.femsq.database.model;

/**
 * Статус строки ПТСФ при сверке со схемой.
 */
public enum ImpIpgReconcileStatus {
    /** Уникальный stiKey, путь OK, сырое имя в пуле — закрыто. */
    MATCHED,
    /** Уникальный stiKey и путь OK, но сырое имя только через нормализацию — нужна alias. */
    NEEDS_ALIAS,
    /** Имя нашлось, путь не совпал ни с одним путём к узлу. */
    PATH_MISMATCH,
    /** Несколько кандидатов по имени, путь не выбрал одного. */
    HOMONYM,
    /** Имя ни с чем не стыкуется. */
    UNMATCHED,
    /** stiKey задан вручную. */
    MANUAL
}
