package com.femsq.database.service;

import com.femsq.database.model.ImpIpgShResolveResult;

/**
 * Резолв {@code ipgpSh} по notes O1 §5.2 (§3.2.3): prev-IP / else 4 / дубли→схемы/ERR.
 *
 * <p>Не пишет в {@code ipgPn} и staging.
 */
public interface ImpIpgShResolveService {

    /**
     * Превью назначения схем для листьев сессии.
     *
     * @param loadKey         ключ {@code impIpgLoad}
     * @param previousIpgKey  предшествующая ИП или {@code null}
     * @return итог; {@code ready=true} при leafCount&gt;0 и errorCount=0
     */
    ImpIpgShResolveResult evaluate(int loadKey, Integer previousIpgKey);

    /**
     * То же, что {@link #evaluate(int, Integer)}, но при ошибках — {@code DaoException}.
     *
     * @param loadKey        ключ сессии
     * @param previousIpgKey предшествующая ИП или {@code null}
     * @return готовый итог с {@code resolvedLeaves}
     */
    ImpIpgShResolveResult assertReady(int loadKey, Integer previousIpgKey);
}
