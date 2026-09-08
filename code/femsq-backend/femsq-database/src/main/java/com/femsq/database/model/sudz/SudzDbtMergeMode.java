package com.femsq.database.model.sudz;

/**
 * Режим Merge (S77.3).
 */
public enum SudzDbtMergeMode {
    /** N канонов → один {@code Dbt}; Value на слотах не трогаем (113→112). */
    CANONS,
    /** Доли на одной СФ: на upl снова одна Value на survivor-слоте (полоса C). */
    SHARES_ON_UPL
}
