package com.femsq.database.service;

import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlP;
import com.femsq.database.model.IpgUtPlPnLmMnGrid;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Сервис планов UtPl / LmMn (C2 O2 §4.2): list + upsert с AggAxis / G-agg.
 */
public interface IpgUtPlService {

    /**
     * Планы агента текущей ИП.
     */
    List<IpgUtPl> listUtPlByIpg(int ipgKey);

    /**
     * Создать план агента.
     */
    IpgUtPl createUtPl(int ipgKey, int agKey, String name, LocalDate date);

    /**
     * Заголовки UtPlP плана.
     */
    List<IpgUtPlP> listUtPlPByPlan(int plKey);

    /**
     * Найти или создать заголовок (pl, pn).
     */
    IpgUtPlP ensureUtPlP(int plKey, int ipgpKey);

    /**
     * Грид LmMn для (plan, point); создаёт заголовок при отсутствии.
     */
    IpgUtPlPnLmMnGrid loadLmMnGrid(int plKey, int ipgpKey);

    /**
     * Запись оси C месяца + sync wide Mxx/Lim (ось T AUTHOR) + G-agg.
     */
    IpgUtPlPnLmMnGrid upsertLmMnMonth(
            int plKey,
            int ipgpKey,
            int month,
            BigDecimal lim212,
            BigDecimal lim195,
            BigDecimal lim172,
            BigDecimal lim187);

    /**
     * LdM apply (§6.6): записать 12× LmMn@212 (без PART), sync wide M/Q/Lim.
     *
     * <p>{@code limYear} / {@code quarters} из Excel — авторитет для wide; иначе Σ месяцев.
     *
     * @param months12 ровно 12 элементов (nullable)
     * @param quarters4 Q1..Q4 или null
     */
    void applyTotalMonths212(
            int plKey,
            int ipgpKey,
            java.util.List<BigDecimal> months12,
            BigDecimal limYear,
            java.util.List<BigDecimal> quarters4);
}
