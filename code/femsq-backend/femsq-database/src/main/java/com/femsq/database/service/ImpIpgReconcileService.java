package com.femsq.database.service;

import com.femsq.database.model.ImpIpgReconcileResult;

/**
 * Сверка ПТСФ ({@code impIpg} разделы) со схемой {@code stNet} (C2 §3.1.6.3).
 */
public interface ImpIpgReconcileService {

    /**
     * Сопоставляет строки-разделы сессии с узлами схемы.
     *
     * @param loadKey         сессия {@code impIpgLoad}
     * @param stNetKey        схема структуры
     * @param persistMatches  записать уникальные stiKey в staging
     */
    ImpIpgReconcileResult reconcile(int loadKey, int stNetKey, boolean persistMatches);
}
