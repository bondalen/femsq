package com.femsq.database.service;

import com.femsq.database.dao.IpgUtPlDao;
import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlP;
import com.femsq.database.model.IpgUtPlPnLmMnCell;
import com.femsq.database.model.IpgUtPlPnLmMnGrid;
import com.femsq.database.model.IpgUtPlPnLmMnMonth;
import com.femsq.database.util.AggAxis;
import com.femsq.database.util.AggAxisKind;
import com.femsq.database.util.AggAxisResult;
import com.femsq.database.util.FemsqMoney;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * Реализация {@link IpgUtPlService}: DoD A+B+G-agg (контракт O2 §3).
 */
public class DefaultIpgUtPlService implements IpgUtPlService {

    private static final Logger log = Logger.getLogger(DefaultIpgUtPlService.class.getName());

    private static final int ST_TOTAL = 212;
    private static final int ST_WRK = 195;
    private static final int ST_EQU = 172;
    private static final int ST_OTH = 187;

    private final IpgUtPlDao utPlDao;

    public DefaultIpgUtPlService(IpgUtPlDao utPlDao) {
        this.utPlDao = Objects.requireNonNull(utPlDao, "utPlDao");
    }

    @Override
    public List<IpgUtPl> listUtPlByIpg(int ipgKey) {
        return utPlDao.findUtPlByIpg(ipgKey);
    }

    @Override
    public IpgUtPl createUtPl(int ipgKey, int agKey, String name, LocalDate date) {
        log.info(() -> "createUtPl ipg=" + ipgKey + " ag=" + agKey);
        return utPlDao.createUtPl(ipgKey, agKey, name, date != null ? date : LocalDate.now());
    }

    @Override
    public List<IpgUtPlP> listUtPlPByPlan(int plKey) {
        return utPlDao.findUtPlPByPlan(plKey);
    }

    @Override
    public IpgUtPlP ensureUtPlP(int plKey, int ipgpKey) {
        requirePlan(plKey);
        return utPlDao.findUtPlP(plKey, ipgpKey)
                .orElseGet(() -> utPlDao.createUtPlP(plKey, ipgpKey));
    }

    @Override
    public IpgUtPlPnLmMnGrid loadLmMnGrid(int plKey, int ipgpKey) {
        IpgUtPlP header = ensureUtPlP(plKey, ipgpKey);
        return buildGrid(header);
    }

    @Override
    public IpgUtPlPnLmMnGrid upsertLmMnMonth(
            int plKey,
            int ipgpKey,
            int month,
            BigDecimal lim212,
            BigDecimal lim195,
            BigDecimal lim172,
            BigDecimal lim187) {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("month must be 1..12, got " + month);
        }
        IpgUtPlP header = ensureUtPlP(plKey, ipgpKey);
        AggAxisResult agg = requireAggWritable(lim212, lim195, lim172, lim187);
        log.info(() -> "upsertLmMnMonth plPn=" + header.iuplpKey()
                + " m=" + month + " code=" + agg.logCode());

        utPlDao.upsertLmMnCell(header.iuplpKey(), ST_TOTAL, month, nzOrNull(agg.ttl()));
        utPlDao.upsertLmMnCell(header.iuplpKey(), ST_WRK, month, nzOrNull(agg.wrk()));
        utPlDao.upsertLmMnCell(header.iuplpKey(), ST_EQU, month, nzOrNull(agg.equ()));
        utPlDao.upsertLmMnCell(header.iuplpKey(), ST_OTH, month, nzOrNull(agg.oth()));

        syncAxisTFromLmMn(header.iuplpKey());
        return buildGrid(utPlDao.findUtPlP(plKey, ipgpKey).orElse(header));
    }

    @Override
    public void applyTotalMonths212(
            int plKey,
            int ipgpKey,
            List<BigDecimal> months12,
            BigDecimal limYear,
            List<BigDecimal> quarters4) {
        Objects.requireNonNull(months12, "months12");
        if (months12.size() != 12) {
            throw new IllegalArgumentException("months12 must have size 12, got " + months12.size());
        }
        IpgUtPlP header = ensureUtPlP(plKey, ipgpKey);
        int plPnKey = header.iuplpKey();
        BigDecimal[] months = new BigDecimal[12];
        for (int m = 1; m <= 12; m++) {
            BigDecimal raw = months12.get(m - 1);
            AggAxisResult agg = requireAggWritable(raw, null, null, null);
            BigDecimal ttl = nzOrNull(agg.ttl());
            months[m - 1] = ttl;
            utPlDao.upsertLmMnCell(plPnKey, ST_TOTAL, m, ttl);
            // PART C не из LdM — обнуляем оси частей на месяц, чтобы G-agg был STRUCT/OK
            utPlDao.upsertLmMnCell(plPnKey, ST_WRK, m, null);
            utPlDao.upsertLmMnCell(plPnKey, ST_EQU, m, null);
            utPlDao.upsertLmMnCell(plPnKey, ST_OTH, m, null);
        }
        BigDecimal[] quarters = new BigDecimal[4];
        if (quarters4 != null && quarters4.size() == 4) {
            for (int q = 0; q < 4; q++) {
                quarters[q] = FemsqMoney.roundMln(quarters4.get(q));
                if (quarters[q] != null && quarters[q].compareTo(BigDecimal.ZERO) == 0) {
                    quarters[q] = null;
                }
            }
        } else {
            for (int q = 0; q < 4; q++) {
                BigDecimal qSum = BigDecimal.ZERO.setScale(FemsqMoney.SCALE_MLN);
                for (int m = 0; m < 3; m++) {
                    qSum = qSum.add(nz(months[q * 3 + m]));
                }
                quarters[q] = qSum.compareTo(BigDecimal.ZERO) == 0 ? null : qSum;
            }
        }
        BigDecimal yearRaw = FemsqMoney.roundMln(limYear);
        final BigDecimal year;
        if (yearRaw == null || yearRaw.compareTo(BigDecimal.ZERO) == 0) {
            BigDecimal sum = BigDecimal.ZERO.setScale(FemsqMoney.SCALE_MLN);
            for (BigDecimal m : months) {
                sum = sum.add(nz(m));
            }
            year = sum.compareTo(BigDecimal.ZERO) == 0 ? null : sum;
        } else {
            year = yearRaw;
        }
        utPlDao.syncWideMonthsAndLim(plPnKey, months, year, quarters);
        log.info(() -> "applyTotalMonths212 plPn=" + plPnKey + " limYear=" + year);
    }

    /**
     * Ось T: Σ M → limYear и Q (AUTHOR); wide M* ← 212 из LmMn.
     */
    private void syncAxisTFromLmMn(int plPnKey) {
        List<IpgUtPlPnLmMnCell> cells = utPlDao.findLmMnByPlPn(plPnKey);
        BigDecimal[] months = new BigDecimal[12];
        for (IpgUtPlPnLmMnCell cell : cells) {
            if (cell.iuplpmStCost() != ST_TOTAL) {
                continue;
            }
            int idx = cell.iuplpmMn() - 1;
            if (idx >= 0 && idx < 12) {
                months[idx] = FemsqMoney.roundMln(cell.iuplpmLim());
            }
        }
        BigDecimal year = BigDecimal.ZERO.setScale(FemsqMoney.SCALE_MLN);
        BigDecimal[] quarters = new BigDecimal[4];
        for (int q = 0; q < 4; q++) {
            BigDecimal qSum = BigDecimal.ZERO.setScale(FemsqMoney.SCALE_MLN);
            for (int m = 0; m < 3; m++) {
                BigDecimal v = months[q * 3 + m];
                if (v != null) {
                    qSum = qSum.add(v);
                }
            }
            quarters[q] = qSum.compareTo(BigDecimal.ZERO) == 0 ? null : qSum;
            year = year.add(nz(quarters[q]));
        }
        BigDecimal limYear = year.compareTo(BigDecimal.ZERO) == 0 ? null : year;
        utPlDao.syncWideMonthsAndLim(plPnKey, months, limYear, quarters);
    }

    private IpgUtPlPnLmMnGrid buildGrid(IpgUtPlP header) {
        List<IpgUtPlPnLmMnCell> cells = utPlDao.findLmMnByPlPn(header.iuplpKey());
        Map<Integer, BigDecimal[]> byMonth = new HashMap<>();
        for (IpgUtPlPnLmMnCell cell : cells) {
            BigDecimal[] axis = byMonth.computeIfAbsent(cell.iuplpmMn(), m -> new BigDecimal[4]);
            int slot = stCostSlot(cell.iuplpmStCost());
            if (slot >= 0) {
                axis[slot] = cell.iuplpmLim();
            }
        }
        List<IpgUtPlPnLmMnMonth> months = new ArrayList<>(12);
        boolean gAggOk = true;
        for (int m = 1; m <= 12; m++) {
            BigDecimal[] axis = byMonth.get(m);
            BigDecimal t = axis == null ? null : axis[0];
            BigDecimal w = axis == null ? null : axis[1];
            BigDecimal e = axis == null ? null : axis[2];
            BigDecimal o = axis == null ? null : axis[3];
            AggAxisResult check = AggAxis.reconcileMln(t, w, e, o);
            if (check.kind() == AggAxisKind.BLOCK) {
                gAggOk = false;
            }
            months.add(new IpgUtPlPnLmMnMonth(
                    header.iuplpKey(), m, t, w, e, o, check.logCode()));
        }
        return new IpgUtPlPnLmMnGrid(
                header.iuplpKey(),
                header.iuplpLim(),
                List.copyOf(months),
                List.copyOf(cells),
                gAggOk);
    }

    /**
     * R-MONEY-AGG ось C: если только части — заполняем 212=Σ до reconcile; BLOCK → отказ.
     */
    private static AggAxisResult requireAggWritable(
            BigDecimal ttl, BigDecimal wrk, BigDecimal equ, BigDecimal oth) {
        BigDecimal t = FemsqMoney.roundMln(ttl);
        BigDecimal w = FemsqMoney.roundMln(wrk);
        BigDecimal e = FemsqMoney.roundMln(equ);
        BigDecimal o = FemsqMoney.roundMln(oth);
        boolean anyPart = isNonZero(w) || isNonZero(e) || isNonZero(o);
        if (!isNonZero(t) && anyPart) {
            t = nz(w).add(nz(e)).add(nz(o))
                    .setScale(FemsqMoney.SCALE_MLN, java.math.RoundingMode.HALF_UP);
        }
        AggAxisResult agg = AggAxis.reconcileMln(t, w, e, o);
        if (!agg.writable()) {
            throw new IllegalArgumentException(
                    "AGG_BLOCK: 212≠195+172+187 (δ=" + agg.deltaBefore()
                            + "). Исправьте суммы или уменьшите расхождение.");
        }
        if (agg.kind() == AggAxisKind.QUANTUM_FIX || agg.kind() == AggAxisKind.AUTHOR_FIX) {
            log.info(() -> "UtPl AggAxis autofix " + agg.logCode() + " δ=" + agg.deltaBefore());
        }
        return agg;
    }

    private IpgUtPl requirePlan(int plKey) {
        return utPlDao.findUtPlByKey(plKey)
                .orElseThrow(() -> new IllegalArgumentException("ipgUtPl not found: " + plKey));
    }

    private static int stCostSlot(int stCost) {
        return switch (stCost) {
            case ST_TOTAL -> 0;
            case ST_WRK -> 1;
            case ST_EQU -> 2;
            case ST_OTH -> 3;
            default -> -1;
        };
    }

    private static BigDecimal nzOrNull(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) {
            return null;
        }
        return value;
    }

    private static boolean isNonZero(BigDecimal value) {
        return value != null && value.compareTo(BigDecimal.ZERO) != 0;
    }

    private static BigDecimal nz(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }
}
