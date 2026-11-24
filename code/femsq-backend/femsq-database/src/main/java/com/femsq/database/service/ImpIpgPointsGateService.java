package com.femsq.database.service;

import com.femsq.database.model.ImpIpgPointsGateResult;

/**
 * Gate перед bulk {@code impIpg} → {@code ipgPn}+{@code ipgStPn} (C2 §3.2.1).
 */
public interface ImpIpgPointsGateService {

    /**
     * Оценивает готовность сессии: ПТСФ open=0 на сети {@code ipg.ipgStRlSh}.
     *
     * @param loadKey ключ {@code impIpgLoad}
     * @return результат без исключения при бизнес-отказе
     */
    ImpIpgPointsGateResult evaluate(int loadKey);

    /**
     * То же, что {@link #evaluate(int)}, но при {@code ready=false} бросает ошибку.
     *
     * @param loadKey ключ сессии
     * @return результат при успехе
     */
    ImpIpgPointsGateResult assertReady(int loadKey);
}
