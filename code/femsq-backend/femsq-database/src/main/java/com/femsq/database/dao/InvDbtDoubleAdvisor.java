package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzInvDbtDoubleAdvice;
import com.femsq.database.model.sudz.SudzInvDbtSlot;
import com.femsq.database.model.sudz.SudzInvDbtTimelinePoint;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import com.femsq.database.model.sudz.SudzSfDoubleNewSumMatch;
import com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;

/**
 * Эвристики советника КСДД (сегм. 22c): текст {@code [advisor]} для оператора.
 */
final class InvDbtDoubleAdvisor {

    private static final BigDecimal DEFAULT_EPS = new BigDecimal("0.01");
    private static final int MIN_AMORT_STEPS = 3;

    private InvDbtDoubleAdvisor() {
    }

    /**
     * Сформировать совет по строке очереди.
     *
     * @param row строка очереди
     * @param excel Excel-кандидат
     * @param slots слоты на iKey
     * @param slotAccnts accnt по idKey (primary var)
     * @param slotVars var по idKey
     * @param f1UniqueSlot единственный слот F1 или empty
     * @param newSumMatches совпадения DbtValue по сумме
     * @param slotTimelines ряды по слотам (для амортизации)
     * @param excelStatusDate дата среза upl
     * @param epsilon допуск суммы
     * @return совет
     */
    static SudzInvDbtDoubleAdvice advise(
            SudzCnInvUplInvDbtDouble row,
            SudzSfDoubleExcelCandidate excel,
            List<SudzInvDbtSlot> slots,
            java.util.Map<Integer, Integer> slotAccnts,
            java.util.Map<Integer, Integer> slotVars,
            Optional<Integer> f1UniqueSlot,
            List<SudzSfDoubleNewSumMatch> newSumMatches,
            java.util.Map<Integer, List<SudzInvDbtTimelinePoint>> slotTimelines,
            LocalDate excelStatusDate,
            BigDecimal epsilon
    ) {
        Objects.requireNonNull(row, "row");
        BigDecimal eps = epsilon == null ? DEFAULT_EPS : epsilon;
        StringBuilder msg = new StringBuilder("[advisor]");
        String confidence = "none";
        String action = "manual";
        Integer recommendSlot = null;
        Integer recommendVar = row.ciudIdvvKey();

        if (row.ciudIdvvKey() == null || row.ciudIdvvKey() <= 0) {
            appendLine(msg, "check=no_var: нет invDbtVar → сначала Create var");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "create_var", null, null);
        }

        Integer excelAccnt = excel != null ? excel.cidutAccount() : null;
        if (excelAccnt != null) {
            List<Integer> accntSlots = slots.stream()
                    .filter(s -> excelAccnt.equals(slotAccnts.get(s.idKey())))
                    .map(SudzInvDbtSlot::idKey)
                    .toList();
            if (accntSlots.size() == 1) {
                appendLine(msg, "check=account_match: Excel accnt=" + excelAccnt
                        + " → slot " + accntSlots.get(0));
            } else if (accntSlots.isEmpty()) {
                appendLine(msg, "check=account_match: ни один слот не совпадает с accnt Excel ("
                        + excelAccnt + ")");
            } else {
                appendLine(msg, "check=account_match: accnt " + excelAccnt + " → слоты "
                        + accntSlots);
            }
        }

        if (f1UniqueSlot.isPresent()) {
            int slot = f1UniqueSlot.get();
            appendLine(msg, "check=unique_sum_f1: сумма Excel → единственный slot " + slot);
            appendLine(msg, "recommend=link slot=" + slot + " confidence=high");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "link", slot, row.ciudIdvvKey());
        }

        if (newSumMatches.size() == 1) {
            SudzSfDoubleNewSumMatch m = newSumMatches.get(0);
            if (m.dvInvDbt() != null) {
                appendLine(msg, "check=sum_exact_new: dvKey=" + m.dvKey()
                        + " invDbt=" + m.dvInvDbt());
                appendLine(msg, "recommend=link slot=" + m.dvInvDbt() + " confidence=high");
                return new SudzInvDbtDoubleAdvice(
                        msg.toString(), "high", "link", m.dvInvDbt(), row.ciudIdvvKey());
            }
        } else if (newSumMatches.isEmpty() && row.ciudDebt() != null) {
            appendLine(msg, "check=sum_exact: якорь " + formatMoney(row.ciudDebt())
                    + " не найден в истории DbtValue (±" + eps + ")");
        }

        Integer bridgedSlot = slots.stream()
                .filter(s -> row.ciudIdvvKey().equals(slotVars.get(s.idKey())))
                .map(SudzInvDbtSlot::idKey)
                .findFirst()
                .orElse(null);
        if (bridgedSlot != null) {
            appendLine(msg, "check=bridge_ready: var " + row.ciudIdvvKey()
                    + " уже на slot " + bridgedSlot);
        }

        AmortizationResult bestAmort = null;
        for (SudzInvDbtSlot slot : slots) {
            List<SudzInvDbtTimelinePoint> pts = slotTimelines.getOrDefault(slot.idKey(), List.of());
            AmortizationResult ar = analyzeAmortization(
                    slot.idKey(),
                    slot.idNote(),
                    pts,
                    row.ciudDebt(),
                    excelStatusDate,
                    eps);
            if (ar != null && (bestAmort == null || ar.score() > bestAmort.score())) {
                bestAmort = ar;
            }
        }
        if (bestAmort != null) {
            appendLine(msg, "check=amortization: slot " + bestAmort.slotId()
                    + " (" + bestAmort.label() + "): шаг "
                    + formatMoney(bestAmort.step()) + " × " + bestAmort.steps()
                    + " (R²=" + String.format(Locale.US, "%.4f", bestAmort.r2()) + ")");
            appendLine(msg, "check=gap_projection: " + bestAmort.projectionLine());
            recommendSlot = bestAmort.slotId();
            confidence = bestAmort.confidence();
            action = "link";
            appendLine(msg, "recommend=link slot=" + recommendSlot + " confidence=" + confidence);
            appendLine(msg, "reason=равномерная амортизация + "
                    + (bestAmort.projectionHit() ? "попадание Excel в тренд" : "сверить первичку"));
        } else if (bridgedSlot != null && excelAccnt != null
                && excelAccnt.equals(slotAccnts.get(bridgedSlot))) {
            recommendSlot = bridgedSlot;
            confidence = "medium";
            action = "link";
            appendLine(msg, "recommend=link slot=" + bridgedSlot + " confidence=medium");
            appendLine(msg, "reason=accnt Excel + готовый мост var↔slot");
        } else {
            appendLine(msg, "recommend=manual: выберите slot по ciaName / контексту");
        }

        appendLine(msg, "note=советник не заменяет первичку; при medium/low — проверьте вручную");
        return new SudzInvDbtDoubleAdvice(
                msg.toString(), confidence, action, recommendSlot, recommendVar);
    }

    private record AmortizationResult(
            int slotId,
            String label,
            BigDecimal step,
            int steps,
            double r2,
            boolean projectionHit,
            String projectionLine,
            String confidence
    ) {
        double score() {
            return r2 * (projectionHit ? 2.0 : 1.0);
        }
    }

    private static AmortizationResult analyzeAmortization(
            int slotId,
            String slotNote,
            List<SudzInvDbtTimelinePoint> points,
            BigDecimal excelDebt,
            LocalDate excelStatusDate,
            BigDecimal epsilon
    ) {
        if (points == null || points.size() < MIN_AMORT_STEPS + 1 || excelDebt == null) {
            return null;
        }
        List<SudzInvDbtTimelinePoint> sorted = points.stream()
                .filter(p -> p.statusDate() != null && p.ttl() != null)
                .sorted(Comparator.comparing(SudzInvDbtTimelinePoint::statusDate))
                .toList();
        if (sorted.size() < MIN_AMORT_STEPS + 1) {
            return null;
        }
        AmortizationResult best = null;
        int maxLen = Math.min(12, sorted.size());
        for (int len = MIN_AMORT_STEPS + 1; len <= maxLen; len++) {
            List<SudzInvDbtTimelinePoint> tail = sorted.subList(sorted.size() - len, sorted.size());
            AmortizationResult candidate = tryUniformTail(
                    slotId, slotNote, tail, excelDebt, excelStatusDate, epsilon);
            if (candidate != null && (best == null || candidate.score() > best.score())) {
                best = candidate;
            }
        }
        return best;
    }

    private static AmortizationResult tryUniformTail(
            int slotId,
            String slotNote,
            List<SudzInvDbtTimelinePoint> tail,
            BigDecimal excelDebt,
            LocalDate excelStatusDate,
            BigDecimal epsilon
    ) {
        List<BigDecimal> deltas = new ArrayList<>();
        for (int i = 1; i < tail.size(); i++) {
            deltas.add(tail.get(i).ttl().subtract(tail.get(i - 1).ttl()));
        }
        boolean allNonPositive = deltas.stream().allMatch(d -> d.signum() <= 0);
        boolean anyNegative = deltas.stream().anyMatch(d -> d.signum() < 0);
        if (!allNonPositive || !anyNegative) {
            return null;
        }
        List<BigDecimal> negativeDeltas = deltas.stream().filter(d -> d.signum() < 0).toList();
        if (negativeDeltas.size() < MIN_AMORT_STEPS) {
            return null;
        }
        BigDecimal meanDelta = negativeDeltas.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .divide(BigDecimal.valueOf(negativeDeltas.size()), 4, RoundingMode.HALF_UP);
        BigDecimal variance = BigDecimal.ZERO;
        for (BigDecimal d : negativeDeltas) {
            BigDecimal diff = d.subtract(meanDelta);
            variance = variance.add(diff.multiply(diff));
        }
        variance = variance.divide(BigDecimal.valueOf(negativeDeltas.size()), 8, RoundingMode.HALF_UP);
        double stdDev = Math.sqrt(variance.doubleValue());
        double meanAbs = Math.abs(meanDelta.doubleValue());
        if (meanAbs < 0.01 || stdDev / meanAbs > 0.05) {
            return null;
        }
        double r2 = 1.0 - Math.min(1.0, stdDev / meanAbs);
        SudzInvDbtTimelinePoint last = tail.get(tail.size() - 1);
        boolean projectionHit = false;
        String projectionLine = "нет даты среза upl";
        String confidence = "medium";
        if (excelStatusDate != null && last.statusDate() != null) {
            long days = ChronoUnit.DAYS.between(last.statusDate(), excelStatusDate);
            if (days > 0) {
                BigDecimal quarters = BigDecimal.valueOf(days)
                        .divide(BigDecimal.valueOf(91.25), 4, RoundingMode.HALF_UP);
                int qSteps = quarters.setScale(0, RoundingMode.HALF_UP).intValue();
                if (qSteps < 1) {
                    qSteps = 1;
                }
                BigDecimal projected = last.ttl().add(meanDelta.multiply(BigDecimal.valueOf(qSteps)));
                projectionHit = projected.subtract(excelDebt).abs().compareTo(epsilon) <= 0;
                projectionLine = last.statusDate() + " " + formatMoney(last.ttl())
                        + " → " + excelStatusDate + ": "
                        + qSteps + "×(" + formatMoney(meanDelta) + ") = "
                        + formatMoney(projected)
                        + (projectionHit ? " ✓ Excel" : " (Excel " + formatMoney(excelDebt) + ")");
                if (projectionHit && qSteps <= 4) {
                    confidence = "high";
                }
            }
        }
        String label = slotNote != null && !slotNote.isBlank() ? slotNote : "slot " + slotId;
        return new AmortizationResult(
                slotId,
                label,
                meanDelta,
                negativeDeltas.size(),
                r2,
                projectionHit,
                projectionLine,
                confidence
        );
    }

    private static void appendLine(StringBuilder sb, String line) {
        sb.append('\n').append(line);
    }

    private static String formatMoney(BigDecimal v) {
        if (v == null) {
            return "—";
        }
        return v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }
}
