package com.femsq.web.api.sudz.repay;

import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Разбор «погашено» витрины Rslt по классам шага 1 (S79).
 * Порог выгрузки — число открытых {@code suspect}. Очередь P1 этим порогом не является.
 * Близнецы листа Tbl в расчёт не входят: их даёт пакетный скрипт шага 1.
 */
public final class SudzRsltRepaymentChecker {

    private static final BigDecimal EPS = new BigDecimal("0.01");

    private SudzRsltRepaymentChecker() {
    }

    /**
     * Считает классы по уже загруженному портфелю.
     *
     * @param yrKey год-вариант
     * @param asOfUpl крайняя выгрузка
     * @param debts долги {@code getYrDbtChanges}
     * @return протокол и открытые строки
     */
    public static SudzRsltRepaymentCheck check(int yrKey, int asOfUpl, List<SudzRsltDebt> debts) {
        List<Slice> slices = slicesOf(debts);
        List<Band> bands = new ArrayList<>();
        for (SudzRsltDebt debt : debts) {
            bands.add(Band.of(debt, slices));
        }
        int likely = 0;
        int suspect = 0;
        int ambiguous = 0;
        int documented = 0;
        int candidates = 0;
        List<SudzRsltRepaymentCase> open = new ArrayList<>();
        for (Band band : bands) {
            if (band.pog == null || band.pog.compareTo(BigDecimal.ZERO) == 0) {
                continue;
            }
            candidates++;
            Verdict verdict = classify(band, bands);
            switch (verdict.clazz) {
                case "likely-true" -> likely++;
                case "suspect" -> suspect++;
                case "ambiguous" -> ambiguous++;
                case "documented" -> documented++;
                default -> {
                }
            }
            if ("suspect".equals(verdict.clazz) || "ambiguous".equals(verdict.clazz)) {
                open.add(new SudzRsltRepaymentCase(
                        band.dbtKey,
                        band.account,
                        band.inv,
                        band.cn,
                        band.kind,
                        verdict.clazz,
                        verdict.reason,
                        band.pog));
            }
        }
        open.sort(Comparator.comparing(SudzRsltRepaymentCase::pogasheno, Comparator.nullsLast(Comparator.reverseOrder())));
        String log = """
                Проверить погашения yr=%d до upl=%d
                кандидатов %d
                likely-true %d, suspect %d, ambiguous %d, documented %d
                Порог выгрузки: suspect > 0. Открытых подозрений: %d.
                Близнецы листа Tbl в эту проверку не входят.
                """.formatted(yrKey, asOfUpl, candidates, likely, suspect, ambiguous, documented, suspect);
        return new SudzRsltRepaymentCheck(
                yrKey, asOfUpl, candidates, likely, suspect, ambiguous, documented, log.strip(), List.copyOf(open));
    }

    private static Verdict classify(Band cand, List<Band> all) {
        String documented = documented(cand.inv);
        if (documented != null) {
            return new Verdict("documented", documented);
        }
        List<Hit> foreign = foreignTwins(cand, all);
        if (cand.partial) {
            if (foreign.isEmpty()) {
                return new Verdict("likely-true", "partial_reduce_same_slot_no_foreign_twin");
            }
            if (foreign.size() == 1) {
                return new Verdict("suspect", "partial_reduce_but_foreign_twin");
            }
            return new Verdict("ambiguous", "partial_reduce_multi_foreign_twin");
        }
        List<Hit> foreignTtl = foreign.stream().filter(hit -> "ttl".equals(hit.field)).toList();
        if (foreign.isEmpty()) {
            return new Verdict("likely-true", "full_disappear_no_twin");
        }
        if (foreignTtl.size() == 1 || (foreignTtl.isEmpty() && foreign.size() == 1)) {
            return new Verdict("suspect", "full_disappear_foreign_twin");
        }
        return new Verdict("ambiguous", "full_disappear_multi_twin");
    }

    private static List<Hit> foreignTwins(Band cand, List<Band> all) {
        List<Hit> hits = new ArrayList<>();
        for (Band other : all) {
            if (other.dbtKey == cand.dbtKey) {
                continue;
            }
            boolean sameInv = cand.inv.equals(other.inv) && !cand.inv.isEmpty();
            if (sameInv) {
                continue;
            }
            for (BigDecimal sought : cand.search) {
                for (Amount amount : other.targets) {
                    if (near(sought, amount.value)) {
                        hits.add(new Hit(other.dbtKey, amount.field));
                    }
                }
            }
        }
        Map<String, Hit> seen = new LinkedHashMap<>();
        for (Hit hit : hits) {
            seen.putIfAbsent(hit.dbtKey + "|" + hit.field, hit);
        }
        return List.copyOf(seen.values());
    }

    private static String documented(String inv) {
        if ("86740".equals(inv) || "10000086740".equals(inv)) {
            return "E-Access-Missing-86740";
        }
        if (inv.contains("А45-19974") || inv.contains("A45-19974")) {
            return "E-Split-A45-19974";
        }
        return null;
    }

    private static boolean near(BigDecimal left, BigDecimal right) {
        if (left == null || right == null) {
            return false;
        }
        return left.subtract(right).abs().compareTo(EPS) <= 0;
    }

    private static List<Slice> slicesOf(List<SudzRsltDebt> debts) {
        Map<Integer, LocalDate> dates = new LinkedHashMap<>();
        for (SudzRsltDebt debt : debts) {
            if (debt.periods() == null) {
                continue;
            }
            for (SudzRsltPeriod period : debt.periods()) {
                dates.putIfAbsent(period.uplKey(), period.uplDate());
            }
        }
        List<Slice> slices = new ArrayList<>();
        dates.forEach((upl, date) -> slices.add(new Slice(upl, date)));
        slices.sort(Comparator
                .comparing(Slice::date, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(Slice::upl));
        return slices;
    }

    private record Slice(int upl, LocalDate date) {
    }

    private record Hit(int dbtKey, String field) {
    }

    private record Verdict(String clazz, String reason) {
    }

    private record Amount(String field, BigDecimal value) {
    }

    private static final class Band {
        private final int dbtKey;
        private final String account;
        private final String inv;
        private final String cn;
        private final String kind;
        private final boolean partial;
        private final BigDecimal pog;
        private final List<BigDecimal> search;
        private final List<Amount> targets;

        private Band(
                int dbtKey,
                String account,
                String inv,
                String cn,
                String kind,
                boolean partial,
                BigDecimal pog,
                List<BigDecimal> search,
                List<Amount> targets
        ) {
            this.dbtKey = dbtKey;
            this.account = account;
            this.inv = inv;
            this.cn = cn;
            this.kind = kind;
            this.partial = partial;
            this.pog = pog;
            this.search = search;
            this.targets = targets;
        }

        private static Band of(SudzRsltDebt debt, List<Slice> slices) {
            List<List<SudzRsltPeriod>> bySlice = new ArrayList<>();
            for (Slice slice : slices) {
                List<SudzRsltPeriod> on = new ArrayList<>();
                if (debt.periods() != null) {
                    for (SudzRsltPeriod period : debt.periods()) {
                        if (period.uplKey() == slice.upl) {
                            on.add(period);
                        }
                    }
                }
                bySlice.add(on);
            }
            BigDecimal baseOverd = bySlice.isEmpty() ? null : sumOverd(bySlice.get(0));
            List<SudzRsltPeriod> last = bySlice.isEmpty() ? List.of() : bySlice.get(bySlice.size() - 1);
            BigDecimal currOverd = last.isEmpty() ? null : sumOverd(last);
            BigDecimal pog = slices.size() < 2 ? null : pogashenoAccess(baseOverd, currOverd);
            boolean partial = !last.isEmpty() && last.stream().anyMatch(period -> period.ttl() != null || period.overd() != null);
            String inv = "";
            String cn = "";
            for (int i = bySlice.size() - 1; i >= 0; i--) {
                for (SudzRsltPeriod period : bySlice.get(i)) {
                    if (inv.isEmpty() && period.invNumEnum() != null && !period.invNumEnum().isBlank()) {
                        inv = normInv(period.invNumEnum());
                    }
                    if (cn.isEmpty() && period.cnNumEnum() != null && !period.cnNumEnum().isBlank()) {
                        cn = period.cnNumEnum().trim();
                    }
                }
                if (!inv.isEmpty() && !cn.isEmpty()) {
                    break;
                }
            }
            List<BigDecimal> search = new ArrayList<>();
            addAmount(search, pog);
            if (!bySlice.isEmpty()) {
                addAmount(search, sumTtl(bySlice.get(0)));
                addAmount(search, baseOverd);
                for (int i = 1; i < bySlice.size() - 1; i++) {
                    addAmount(search, sumTtl(bySlice.get(i)));
                    addAmount(search, sumOverd(bySlice.get(i)));
                }
            }
            List<Amount> targets = new ArrayList<>();
            for (List<SudzRsltPeriod> slice : bySlice) {
                addTarget(targets, "ttl", sumTtl(slice));
                addTarget(targets, "overd", sumOverd(slice));
            }
            return new Band(
                    debt.dbtKey(),
                    debt.accountNum(),
                    inv,
                    cn,
                    partial ? "partial_reduce" : "full_disappear",
                    partial,
                    pog,
                    List.copyOf(search),
                    List.copyOf(targets));
        }
    }

    private static void addAmount(List<BigDecimal> amounts, BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }
        for (BigDecimal existing : amounts) {
            if (near(existing, value)) {
                return;
            }
        }
        amounts.add(value);
    }

    private static void addTarget(List<Amount> targets, String field, BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }
        targets.add(new Amount(field, value));
    }

    /**
     * Та же формула, что {@code SudzRsltExcelExporter.pogashenoAccess}.
     */
    private static BigDecimal pogashenoAccess(BigDecimal baseOverd, BigDecimal currOverdOrNull) {
        if (baseOverd == null) {
            return null;
        }
        BigDecimal curr = currOverdOrNull != null ? currOverdOrNull : BigDecimal.ZERO;
        BigDecimal delta = baseOverd.subtract(curr);
        if (delta.compareTo(BigDecimal.ZERO) <= 0) {
            return null;
        }
        return delta;
    }

    private static BigDecimal sumOverd(List<SudzRsltPeriod> periods) {
        BigDecimal sum = null;
        for (SudzRsltPeriod period : periods) {
            if (period.overd() == null) {
                continue;
            }
            sum = sum == null ? period.overd() : sum.add(period.overd());
        }
        return sum;
    }

    private static BigDecimal sumTtl(List<SudzRsltPeriod> periods) {
        BigDecimal sum = null;
        for (SudzRsltPeriod period : periods) {
            if (period.ttl() == null) {
                continue;
            }
            sum = sum == null ? period.ttl() : sum.add(period.ttl());
        }
        return sum;
    }

    private static String normInv(String raw) {
        String text = raw.trim().replaceAll("\\s+", " ");
        int comma = text.indexOf(',');
        if (comma >= 0) {
            text = text.substring(0, comma).trim();
        }
        text = text.replaceAll("\\(номеров:\\s*\\d+\\)", "").trim();
        return text.toUpperCase(Locale.ROOT);
    }
}
