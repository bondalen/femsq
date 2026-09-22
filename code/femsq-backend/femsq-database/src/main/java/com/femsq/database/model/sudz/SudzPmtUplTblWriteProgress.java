package com.femsq.database.model.sudz;

/**
 * Колбэк хода записи {@code CnInvPmtUplTbl} (O3/L1): mid-flush Progress / server log.
 */
@FunctionalInterface
public interface SudzPmtUplTblWriteProgress {

    /**
     * Сообщить о прогрессе вставки.
     *
     * @param done вставлено строк
     * @param total всего строк
     * @param elapsedMs миллисекунды с начала replace
     */
    void onProgress(int done, int total, long elapsedMs);
}
