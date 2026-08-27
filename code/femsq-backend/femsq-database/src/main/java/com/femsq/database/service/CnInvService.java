package com.femsq.database.service;

import com.femsq.database.model.CnInv;
import com.femsq.database.model.CnInvPage;

/**
 * Доменная работа со связями {@code cnInv}.
 */
public interface CnInvService {

    /**
     * Страница связей договора↔СФ (page с 1, join {@code inv.iNum}).
     *
     * @param cnKey {@code ags.cn.cn_key}
     * @param page номер страницы (≥1)
     * @param rowsPerPage размер страницы
     * @param filter опциональный текст (iNum / число → ciInv|ciKey)
     * @param sortBy whitelist: ciKey, ciInv, iNum, ciTimeOfEntry
     * @param descending true → DESC
     * @return страница с totalCount
     */
    CnInvPage listByCn(
            int cnKey,
            int page,
            int rowsPerPage,
            String filter,
            String sortBy,
            boolean descending
    );

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
