package com.femsq.database.service;

import com.femsq.database.model.ImpIpgStiInheritResult;

/**
 * Наследование {@code stiKey} листьев от закрытого родителя-раздела (§3.2.2).
 *
 * <p>Не пишет в {@code ags.impIpg} и не создаёт доменные {@code ipgPn}/{@code ipgStPn}.
 */
public interface ImpIpgStiInheritService {

    /**
     * Превью: резолв L←S, список дыр (листья без sti).
     *
     * @param loadKey ключ {@code impIpgLoad}
     * @return итог; {@code ready=true} только при leafCount&gt;0 и holeCount=0
     */
    ImpIpgStiInheritResult evaluate(int loadKey);

    /**
     * То же, что {@link #evaluate(int)}, но при неготовности бросает {@code DaoException}
     * (контракт apply: дыра = ERROR).
     *
     * @param loadKey ключ сессии
     * @return готовый итог с {@code readyLeaves}
     */
    ImpIpgStiInheritResult assertReady(int loadKey);
}
