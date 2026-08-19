package com.femsq.database.service;

import com.femsq.database.model.CnInv;

/**
 * Доменная работа со связями {@code cnInv}.
 */
public interface CnInvService {

    /**
     * Создаёт связь договора и СФ либо возвращает уже существующую.
     *
     * @param invKey существующий {@code ags.inv.iKey}
     * @param cnKey существующий {@code ags.cn.cn_key}
     * @return актуальная связь
     */
    CnInv create(int invKey, int cnKey);
}
