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

    /**
     * Обновляет существующую связь {@code cnInv}.
     *
     * @param ciKey PK связи {@code ags.cnInv.ciKey}
     * @param invKey существующий {@code ags.inv.iKey}
     * @param cnKey существующий {@code ags.cn.cn_key}
     * @return актуальная связь после правки
     */
    CnInv update(int ciKey, int invKey, int cnKey);

    /**
     * Удаляет связь {@code cnInv} по PK.
     *
     * @param ciKey PK связи
     * @return {@code true}, если строка была удалена
     */
    boolean delete(int ciKey);
}
