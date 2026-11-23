package com.femsq.database.service;

import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link IpgLeavesService}.
 */
public class DefaultIpgLeavesService implements IpgLeavesService {

    private static final Logger log = Logger.getLogger(DefaultIpgLeavesService.class.getName());

    private final IpgLeavesDao leavesDao;

    public DefaultIpgLeavesService(IpgLeavesDao leavesDao) {
        this.leavesDao = Objects.requireNonNull(leavesDao, "leavesDao");
    }

    @Override
    public Optional<IpgFull> getIpg(int ipgKey) {
        return leavesDao.findIpgByKey(ipgKey);
    }

    @Override
    public List<IpgFull> listIpgs(Integer year, Integer ogKey, String nameContains) {
        return leavesDao.findIpgs(year, ogKey, nameContains);
    }

    @Override
    public IpgFull createIpg(
            int ipgOg,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear) {
        log.info(() -> "createIpg og=" + ipgOg + " yy=" + ipgYy + " num=" + ipgNum);
        return leavesDao.createIpg(
                ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear);
    }

    @Override
    public IpgFull updateIpg(
            int ipgKey,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear) {
        return leavesDao.updateIpg(
                ipgKey, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear);
    }

    @Override
    public Optional<IpgPn> getPn(int ipgpKey) {
        return leavesDao.findPnByKey(ipgpKey);
    }

    @Override
    public List<IpgPn> listPns(int ipgKey) {
        return leavesDao.findPnsByIpg(ipgKey);
    }

    @Override
    public IpgPn createPn(
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
            String ipgpTskCms) {
        log.info(() -> "createPn ipg=" + ipgpIpg + " cstAgPn=" + ipgpCstAgPn + " sh=" + ipgpSh);
        return leavesDao.createPn(
                ipgpIpg,
                ipgpNum,
                ipgpCstAgPn,
                ipgpSh,
                ipgpSmTtl,
                ipgpSmWrk,
                ipgpSmEqu,
                ipgpSmOth,
                ipgpSmAgFee,
                ipgpCostAdjust,
                ipgpSmReserv,
                ipgpTskCms);
    }

    @Override
    public IpgPn updatePn(
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
            String ipgpTskCms) {
        return leavesDao.updatePn(
                ipgpKey,
                ipgpNum,
                ipgpCstAgPn,
                ipgpSh,
                ipgpSmTtl,
                ipgpSmWrk,
                ipgpSmEqu,
                ipgpSmOth,
                ipgpSmAgFee,
                ipgpCostAdjust,
                ipgpSmReserv,
                ipgpTskCms);
    }

    @Override
    public void deletePn(int ipgpKey) {
        leavesDao.deletePn(ipgpKey);
    }

    @Override
    public List<IpgStPn> listStPn(int ipgpKey) {
        return leavesDao.findStPnByPn(ipgpKey);
    }

    @Override
    public IpgStPn addStPn(int ipgpKey, int stiKey) {
        return leavesDao.addStPn(ipgpKey, stiKey);
    }

    @Override
    public void removeStPn(int ipgspKey) {
        leavesDao.removeStPn(ipgspKey);
    }

    @Override
    public List<IpgStPn> setStPn(int ipgpKey, List<Integer> stiKeys) {
        return leavesDao.setStPn(ipgpKey, stiKeys);
    }

    @Override
    public List<IpgSh> listSh() {
        return leavesDao.findAllSh();
    }
}
