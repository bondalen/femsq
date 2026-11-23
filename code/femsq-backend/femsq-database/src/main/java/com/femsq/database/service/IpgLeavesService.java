package com.femsq.database.service;

import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Сервис Leaves: ИП / пункты / привязки к структуре.
 */
public interface IpgLeavesService {

    Optional<IpgFull> getIpg(int ipgKey);

    List<IpgFull> listIpgs(Integer year, Integer ogKey, String nameContains);

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

    Optional<IpgPn> getPn(int ipgpKey);

    List<IpgPn> listPns(int ipgKey);

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

    void deletePn(int ipgpKey);

    List<IpgStPn> listStPn(int ipgpKey);

    IpgStPn addStPn(int ipgpKey, int stiKey);

    void removeStPn(int ipgspKey);

    List<IpgStPn> setStPn(int ipgpKey, List<Integer> stiKeys);

    List<IpgSh> listSh();
}
