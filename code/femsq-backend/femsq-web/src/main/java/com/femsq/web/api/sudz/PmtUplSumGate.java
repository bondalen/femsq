package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplSum;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Сверка сумм книги (строки Tbl с «№ докум.») и вкладки «счета, сумма»
 * ({@code ags.q_cn_inv_pm_upl_sum}) в конце воронки платежей.
 * Совпадение — по каждому счёту и по итогу пакета, семь денежных полей, ε=0,01.
 */
final class PmtUplSumGate {

    static final BigDecimal EPS = new BigDecimal("0.01");

    private static final int MAX_GAP_LINES = 40;

    private static final String[] LABELS = {
            "дебет",
            "дебет проср.",
            "дебет не проср.",
            "кредит",
            "кредит проср.",
            "кредит не проср.",
            "сальдо"
    };

    /**
     * @param matched true, если книга и база совпали
     * @param lines строки для лога прогона
     */
    record Verdict(boolean matched, List<String> lines) {
    }

    private PmtUplSumGate() {
    }

    /**
     * Сравнивает суммы книги и базы.
     *
     * @param book суммы Tbl по счетам, без строки итога
     * @param db строки представления, включая итог с пустым счётом
     * @return вердикт и строки лога
     */
    static Verdict compare(List<SudzPmtUplSum> book, List<SudzPmtUplSum> db) {
        if (book == null || book.isEmpty()) {
            return new Verdict(false, List.of(
                    "Сверка сумм: в книге (Tbl, строки с «№ докум.») нет сумм."));
        }
        Map<Integer, BigDecimal[]> bookBy = index(book);
        Map<Integer, BigDecimal[]> dbBy = index(db == null ? List.of() : db);
        SudzPmtUplSum bookTotalRow = sumAccounts(book);
        BigDecimal[] bookTotal = money(bookTotalRow);
        BigDecimal[] dbTotal = totalRow(db);

        List<String> gaps = new ArrayList<>();
        Set<Integer> accounts = new HashSet<>();
        accounts.addAll(bookBy.keySet());
        accounts.addAll(dbBy.keySet());
        List<Integer> ordered = new ArrayList<>(accounts);
        ordered.sort(Comparator.nullsLast(Comparator.naturalOrder()));
        for (Integer account : ordered) {
            BigDecimal[] left = bookBy.get(account);
            BigDecimal[] right = dbBy.get(account);
            if (left == null) {
                left = zeros();
            }
            if (right == null) {
                right = zeros();
            }
            appendGaps(gaps, accountLabel(account), left, right);
        }
        appendGaps(gaps, "итого", bookTotal, dbTotal == null ? zeros() : dbTotal);

        if (gaps.isEmpty()) {
            int accountsN = (int) ordered.stream().filter(account -> account != null).count();
            return new Verdict(true, List.of(
                    "Сверка сумм с книгой: совпало (счетов <b>" + accountsN + "</b>, ε=0,01)."));
        }
        List<String> lines = new ArrayList<>();
        lines.add("Сверка сумм с книгой: расхождение (ε=0,01).");
        int shown = Math.min(gaps.size(), MAX_GAP_LINES);
        lines.addAll(gaps.subList(0, shown));
        if (gaps.size() > shown) {
            lines.add("… ещё расхождений: <b>" + (gaps.size() - shown) + "</b>.");
        }
        return new Verdict(false, List.copyOf(lines));
    }

    private static void appendGaps(List<String> gaps, String where, BigDecimal[] left, BigDecimal[] right) {
        for (int i = 0; i < LABELS.length; i++) {
            if (near(left[i], right[i])) {
                continue;
            }
            BigDecimal delta = nz(left[i]).subtract(nz(right[i]));
            gaps.add(where + " · " + LABELS[i]
                    + " книга " + moneyText(left[i])
                    + " · база " + moneyText(right[i])
                    + " · Δ " + moneyText(delta));
        }
    }

    private static String accountLabel(Integer account) {
        return account == null ? "счёт (пусто)" : "счёт " + account;
    }

    private static Map<Integer, BigDecimal[]> index(List<SudzPmtUplSum> rows) {
        Map<Integer, BigDecimal[]> byAccount = new HashMap<>();
        for (SudzPmtUplSum row : rows) {
            if (row.accountNum() == null) {
                continue;
            }
            byAccount.merge(row.accountNum(), money(row), PmtUplSumGate::add);
        }
        return byAccount;
    }

    private static BigDecimal[] totalRow(List<SudzPmtUplSum> rows) {
        if (rows == null) {
            return null;
        }
        BigDecimal[] total = null;
        for (SudzPmtUplSum row : rows) {
            if (row.accountNum() != null) {
                continue;
            }
            total = total == null ? money(row) : add(total, money(row));
        }
        return total;
    }

    private static SudzPmtUplSum sumAccounts(List<SudzPmtUplSum> rows) {
        BigDecimal[] sum = zeros();
        int pmKey = 1;
        for (SudzPmtUplSum row : rows) {
            if (row.accountNum() == null) {
                continue;
            }
            pmKey = row.pmKey();
            sum = add(sum, money(row));
        }
        return new SudzPmtUplSum(pmKey, null, sum[0], sum[1], sum[2], sum[3], sum[4], sum[5], sum[6]);
    }

    private static BigDecimal[] money(SudzPmtUplSum row) {
        return new BigDecimal[] {
                nz(row.dbtBlns()),
                nz(row.dbtBlnsOverd()),
                nz(row.dbtBlnsNotOverd()),
                nz(row.cdtBlns()),
                nz(row.cdtBlnsOverd()),
                nz(row.cdtBlnsNotOverd()),
                nz(row.blns())
        };
    }

    private static BigDecimal[] zeros() {
        BigDecimal[] values = new BigDecimal[LABELS.length];
        for (int i = 0; i < values.length; i++) {
            values[i] = BigDecimal.ZERO;
        }
        return values;
    }

    private static BigDecimal[] add(BigDecimal[] left, BigDecimal[] right) {
        BigDecimal[] sum = new BigDecimal[LABELS.length];
        for (int i = 0; i < sum.length; i++) {
            sum[i] = nz(left[i]).add(nz(right[i]));
        }
        return sum;
    }

    private static boolean near(BigDecimal left, BigDecimal right) {
        return nz(left).subtract(nz(right)).abs().compareTo(EPS) <= 0;
    }

    private static BigDecimal nz(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private static String moneyText(BigDecimal value) {
        return nz(value).setScale(2, RoundingMode.HALF_UP).toPlainString();
    }
}
