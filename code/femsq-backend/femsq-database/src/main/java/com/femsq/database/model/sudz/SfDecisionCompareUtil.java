package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;

/**
 * Сверка Excel ↔ кандидат СФ для шапки decision-TreeList.
 */
public final class SfDecisionCompareUtil {

    /** Пустые/заглушечные № СФ (export-row §5.1 + decision compare). */
    private static final Set<String> SUSPICIOUS_INV = Set.of(
            "б/н", "б\\н", "бн", "б/с", "б\\с", "бс",
            "-", "—", "*", "nullилипусто", "без номера"
    );

    /** Длина хвоста кода стройки — как {@link SudzPmtUplCstMatch#CODE_SUFFIX_LENGTH}. */
    public static final int CST_CODE_SUFFIX_LENGTH = SudzPmtUplCstMatch.CODE_SUFFIX_LENGTH;

    private SfDecisionCompareUtil() {
    }

    /**
     * Нормализует текст номера/договора для сравнения.
     *
     * @param raw исходная строка
     * @return нормализованная или пустая
     */
    public static String normalize(String raw) {
        if (raw == null) {
            return "";
        }
        String t = raw.trim().toLowerCase(Locale.ROOT).replace('ё', 'е');
        t = t.replaceAll("\\s+", " ");
        return t;
    }

    /**
     * Номер — заглушка / «пустой» (б/н, Б/С, «-», …).
     *
     * @param raw номер Excel или кандидата
     * @return true если нельзя считать тождеством по одному номеру
     */
    public static boolean isSuspiciousInvNum(String raw) {
        String n = normalize(raw);
        if (n.isEmpty()) {
            return true;
        }
        return SUSPICIOUS_INV.contains(n);
    }

    /**
     * Исход по номеру СФ (один кандидат — обычно {@code inv.iNum}).
     *
     * @param excelNum номер Excel
     * @param candidateNum номер кандидата
     * @return yes|no|suspicious|na
     */
    public static String invNumVerdict(String excelNum, String candidateNum) {
        return invNumVerdict(excelNum, candidateNum == null ? List.of() : List.of(candidateNum));
    }

    /**
     * Исход по номеру СФ с учётом алиасов {@code ags.invNum}.
     * Совпадение с любым алиасом = yes (или suspicious для б/н).
     *
     * @param excelNum номер Excel
     * @param candidateNums {@code inv.iNum} и/или алиасы
     * @return yes|no|suspicious|na
     */
    public static String invNumVerdict(String excelNum, Collection<String> candidateNums) {
        String e = normalize(excelNum);
        List<String> nums = new java.util.ArrayList<>();
        if (candidateNums != null) {
            for (String raw : candidateNums) {
                if (raw == null || raw.isBlank()) {
                    continue;
                }
                nums.add(raw);
            }
        }
        if (e.isEmpty() && nums.isEmpty()) {
            return "na";
        }
        if (e.isEmpty() || nums.isEmpty()) {
            return "no";
        }
        boolean excelSuspicious = isSuspiciousInvNum(excelNum);
        boolean anyHit = false;
        boolean anySuspiciousHit = false;
        for (String cand : nums) {
            String c = normalize(cand);
            if (c.isEmpty()) {
                continue;
            }
            if (!Objects.equals(e, c)) {
                continue;
            }
            anyHit = true;
            if (excelSuspicious || isSuspiciousInvNum(cand)) {
                anySuspiciousHit = true;
            }
        }
        if (!anyHit) {
            return "no";
        }
        return anySuspiciousHit ? "suspicious" : "yes";
    }

    /**
     * Есть ли переезд кода документа на другой inv/cn.
     *
     * @param anyTransfer хотя бы один docSum с чужим inv/cn
     * @return transfer|na
     */
    public static String docTransferVerdict(boolean anyTransfer) {
        return anyTransfer ? "transfer" : "na";
    }

    /**
     * Исход по договору.
     *
     * @param excelCn текст Excel
     * @param candidateCn номер/имя кандидата
     * @return yes|no|na
     */
    public static String cnVerdict(String excelCn, String candidateCn) {
        return cnVerdict(excelCn, candidateCn == null ? List.of() : List.of(candidateCn));
    }

    /**
     * Исход по договору: совпадение Excel с <b>любым</b> cnInv кандидата
     * (один inv может быть на нескольких договорах).
     *
     * @param excelCn договор Excel
     * @param candidateCns номера/имена cn через cnInv
     * @return yes|no|na
     */
    public static String cnVerdict(String excelCn, Collection<String> candidateCns) {
        String e = normalize(excelCn);
        if (e.isEmpty()) {
            return "na";
        }
        if (candidateCns == null || candidateCns.isEmpty()) {
            return "na";
        }
        boolean any = false;
        for (String raw : candidateCns) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            String c = normalize(raw);
            if (c.isEmpty()) {
                continue;
            }
            any = true;
            if (Objects.equals(e, c) || c.contains(e) || e.contains(c)) {
                return "yes";
            }
        }
        return any ? "no" : "na";
    }

    /**
     * Исход по сумме.
     *
     * @param excelSum сумма Excel
     * @param candidateSum сумма кандидата (часто Σ текущего пакета)
     * @return yes|no|na
     */
    public static String sumVerdict(BigDecimal excelSum, BigDecimal candidateSum) {
        if (excelSum == null || candidateSum == null) {
            return "na";
        }
        BigDecimal diff = excelSum.subtract(candidateSum).abs().setScale(2, RoundingMode.HALF_UP);
        return diff.compareTo(new BigDecimal("0.01")) <= 0 ? "yes" : "no";
    }

    /**
     * Исход по исполнителю (БУиРГ).
     *
     * @param excelBuirg БУиРГ из Excel-кандидата
     * @param candidateBuirg БУиРГ стороны договора кандидата
     * @return yes|no|na
     */
    public static String executorVerdict(Integer excelBuirg, Integer candidateBuirg) {
        if (excelBuirg == null || candidateBuirg == null) {
            return "na";
        }
        return Objects.equals(excelBuirg, candidateBuirg) ? "yes" : "no";
    }

    /**
     * Хвост кода стройки: {@code RIGHT(TRIM(code), 6)} — как очередь «стройки новые».
     *
     * @param code полный код САК или Excel CAC
     * @return хвост или пустая строка
     */
    public static String cstCodeSuffix(String code) {
        if (code == null) {
            return "";
        }
        String t = code.trim();
        if (t.length() < CST_CODE_SUFFIX_LENGTH) {
            return t.isEmpty() ? "" : t;
        }
        return t.substring(t.length() - CST_CODE_SUFFIX_LENGTH);
    }

    /**
     * Сверка одного кода pm с Excel CAC.
     *
     * @param excelCac код из Excel
     * @param pmCode код на платеже
     * @return yes|suffix|no|na
     */
    public static String cstCodeMatch(String excelCac, String pmCode) {
        String e = excelCac == null ? "" : excelCac.trim();
        String c = pmCode == null ? "" : pmCode.trim();
        if (e.isEmpty() || c.isEmpty()) {
            return "na";
        }
        if (e.equalsIgnoreCase(c)) {
            return "yes";
        }
        String es = cstCodeSuffix(e);
        String cs = cstCodeSuffix(c);
        if (!es.isEmpty() && es.equalsIgnoreCase(cs)) {
            return "suffix";
        }
        return "no";
    }

    /**
     * Исход по стройке: полный код среди переданных pm, иначе хвост из 6 символов
     * (код может переходить между агентами).
     *
     * @param excelCac CAC Excel
     * @param candidateCodes коды САК (обычно pm <b>текущего</b> пакета)
     * @return yes|suffix|no|na
     */
    public static String cstVerdict(String excelCac, Collection<String> candidateCodes) {
        String e = excelCac == null ? "" : excelCac.trim();
        if (e.isEmpty()) {
            return "na";
        }
        if (candidateCodes == null || candidateCodes.isEmpty()) {
            return "na";
        }
        boolean anyCode = false;
        boolean suffixHit = false;
        String excelSuffix = cstCodeSuffix(e);
        for (String raw : candidateCodes) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            anyCode = true;
            String c = raw.trim();
            if (e.equalsIgnoreCase(c)) {
                return "yes";
            }
            if (!excelSuffix.isEmpty() && excelSuffix.equalsIgnoreCase(cstCodeSuffix(c))) {
                suffixHit = true;
            }
        }
        if (!anyCode) {
            return "na";
        }
        return suffixHit ? "suffix" : "no";
    }

    /**
     * Есть ли в истории (pm не текущего пакета) стройки, не совпадающие с Excel.
     * Совпадение yes/suffix не считается «другой» стройкой.
     *
     * @param excelCac CAC Excel
     * @param histCodes коды САК на исторических pm
     * @return other|na
     */
    public static String cstHistVerdict(String excelCac, Collection<String> histCodes) {
        String e = excelCac == null ? "" : excelCac.trim();
        if (e.isEmpty() || histCodes == null || histCodes.isEmpty()) {
            return "na";
        }
        for (String raw : histCodes) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            if ("no".equals(cstCodeMatch(e, raw))) {
                return "other";
            }
        }
        return "na";
    }

    /**
     * Собирает compare (номер — один текст или primary).
     *
     * @param excelInvNum номер Excel
     * @param invNum номер кандидата
     * @param excelCnText договор Excel
     * @param candidateContracts договоры кандидата (все cnInv)
     * @param excelBuirg БУиРГ Excel
     * @param candidateBuirg БУиРГ кандидата
     * @param excelBlnsSum сумма Excel
     * @param sumForCompare сумма для сверки
     * @param excelCac код стройки Excel
     * @param packageCstCodes коды САК на pm текущего пакета (или все, если пакет не задан)
     * @param histCstCodes коды САК на pm других пакетов
     * @return compare
     */
    public static SudzSfDecisionCompare build(
            String excelInvNum,
            String invNum,
            String excelCnText,
            Collection<String> candidateContracts,
            Integer excelBuirg,
            Integer candidateBuirg,
            BigDecimal excelBlnsSum,
            BigDecimal sumForCompare,
            String excelCac,
            Collection<String> packageCstCodes,
            Collection<String> histCstCodes
    ) {
        return build(
                excelInvNum,
                invNum == null ? List.of() : List.of(invNum),
                excelCnText,
                candidateContracts,
                excelBuirg,
                candidateBuirg,
                excelBlnsSum,
                sumForCompare,
                excelCac,
                packageCstCodes,
                histCstCodes,
                false
        );
    }

    /**
     * Собирает compare с алиасами номера и флагом переездов документов.
     *
     * @param excelInvNum номер Excel
     * @param candidateInvNums primary + алиасы
     * @param excelCnText договор Excel
     * @param candidateContracts договоры кандидата (все cnInv)
     * @param excelBuirg БУиРГ Excel
     * @param candidateBuirg БУиРГ кандидата
     * @param excelBlnsSum сумма Excel
     * @param sumForCompare сумма для сверки
     * @param excelCac код стройки Excel
     * @param packageCstCodes коды САК на pm текущего пакета (или все, если пакет не задан)
     * @param histCstCodes коды САК на pm других пакетов
     * @param anyDocTransfer есть ли переезд docKod
     * @return compare
     */
    public static SudzSfDecisionCompare build(
            String excelInvNum,
            Collection<String> candidateInvNums,
            String excelCnText,
            Collection<String> candidateContracts,
            Integer excelBuirg,
            Integer candidateBuirg,
            BigDecimal excelBlnsSum,
            BigDecimal sumForCompare,
            String excelCac,
            Collection<String> packageCstCodes,
            Collection<String> histCstCodes,
            boolean anyDocTransfer
    ) {
        return new SudzSfDecisionCompare(
                invNumVerdict(excelInvNum, candidateInvNums),
                cnVerdict(excelCnText, candidateContracts),
                executorVerdict(excelBuirg, candidateBuirg),
                sumVerdict(excelBlnsSum, sumForCompare),
                cstVerdict(excelCac, packageCstCodes),
                cstHistVerdict(excelCac, histCstCodes),
                docTransferVerdict(anyDocTransfer)
        );
    }
}
