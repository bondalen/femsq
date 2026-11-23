package com.femsq.database.dao;

import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * DAO Leaves: карточка {@code ipg}, пункты {@code ipgPn}, привязки {@code ipgStPn}.
 */
public interface IpgLeavesDao {

    Optional<IpgFull> findIpgByKey(int ipgKey);

    List<IpgFull> findIpgs(Integer year, Integer ogKey, String nameContains);

    IpgFull createIpg(
            int ipgOg,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear);

    IpgFull updateIpg(
            int ipgKey,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear);

    Optional<IpgPn> findPnByKey(int ipgpKey);

    List<IpgPn> findPnsByIpg(int ipgKey);

    IpgPn createPn(
            int ipgpIpg,
            Integer ipgpNum,
            int ipgpCstAgPn,
            int ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms);

    IpgPn updatePn(
            int ipgpKey,
            Integer ipgpNum,
            int ipgpCstAgPn,
            int ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms);

    /**
     * Удаляет пункт: сначала {@code ipgStPn}; запрещено при UtPl/Lim.
     */
    void deletePn(int ipgpKey);

    List<IpgStPn> findStPnByPn(int ipgpKey);

    IpgStPn addStPn(int ipgpKey, int stiKey);

    void removeStPn(int ipgspKey);

    /**
     * Заменяет набор привязок пункта (транзакция).
     */
    List<IpgStPn> setStPn(int ipgpKey, List<Integer> stiKeys);

    List<IpgSh> findAllSh();
}
