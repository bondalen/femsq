package com.femsq.database.service;

import com.femsq.database.model.ImpIpgPointsApplyResult;

/**
 * Apply листьев staging → {@code ipgPn}+{@code ipgStPn} (§3.2.4 / §3.2.7 partial).
 *
 * <p>Ошибка строки → лог + skip; успешные пишутся. Unique уже есть → skip OK.
 * Без sti у строки пункт не создаётся (ERROR в логе), пакет не валится.
 */
public interface ImpIpgPointsApplyService {

    /**
     * Проход по листьям load; при {@code dryRun=false} пишет доступные пункты.
     *
     * @param loadKey         сессия {@code impIpgLoad}
     * @param previousIpgKey  предшествующая ИП для резолва схем (nullable)
     * @param dryRun          {@code true} — только счётчики / лог, без INSERT
     */
    ImpIpgPointsApplyResult apply(int loadKey, Integer previousIpgKey, boolean dryRun);
}
