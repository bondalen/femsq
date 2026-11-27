package com.femsq.database.dao;

import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlP;
import com.femsq.database.model.IpgUtPlPnLmMnCell;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * DAO планов UtPl / UtPlP / LmMn (C2 O2 §4.2).
 */
public interface IpgUtPlDao {

    /**
     * Планы агента текущей ИП ({@code iuplIpg = ?}).
     */
    List<IpgUtPl> findUtPlByIpg(int ipgKey);

    /**
     * План по ключу.
     */
    Optional<IpgUtPl> findUtPlByKey(int iuplKey);

    /**
     * Создать план агента на ИП.
     */
    IpgUtPl createUtPl(int ipgKey, int agKey, String name, LocalDate date);

    /**
     * Заголовки UtPlP плана.
     */
    List<IpgUtPlP> findUtPlPByPlan(int plKey);

    /**
     * Найти заголовок (pl, pn, SubAg IS NULL).
     */
    Optional<IpgUtPlP> findUtPlP(int plKey, int ipgpKey);

    /**
     * Создать заголовок без SubAg.
     */
    IpgUtPlP createUtPlP(int plKey, int ipgpKey);

    /**
     * Все ячейки LmMn заголовка.
     */
    List<IpgUtPlPnLmMnCell> findLmMnByPlPn(int plPnKey);

    /**
     * Upsert/delete ячейки для (plPn, stCost, month). lim null/0 → delete.
     */
    void upsertLmMnCell(int plPnKey, int stCost, int month, BigDecimal lim);

    /**
     * Синхронизация широких Mxx / Qx / Lim заголовка (семантика 212).
     */
    void syncWideMonthsAndLim(
            int plPnKey,
            BigDecimal[] months212,
            BigDecimal limYear,
            BigDecimal[] quarters);
}
