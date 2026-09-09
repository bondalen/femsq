package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzInvDbtDoubleAdvice;
import com.femsq.database.model.sudz.SudzInvDbtSlot;
import com.femsq.database.model.sudz.SudzInvDbtSplitCandidate;
import com.femsq.database.model.sudz.SudzInvDbtTimelinePoint;
import com.femsq.database.model.sudz.SudzDbtSplitPart;
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
 * Эвристики советника КСДД (сегм. 22c): текст {@code [советник]} для оператора.
 */
final class InvDbtDoubleAdvisor {

    private static final BigDecimal DEFAULT_EPS = new BigDecimal("0.01");
    private static final int MIN_AMORT_STEPS = 3;

    private InvDbtDoubleAdvisor() {
    }

    /**
     * Канон слота для детекта Split: последняя Value (предпочтительно текущая upl).
     *
     * @param slotKey {@code invDbt.idKey}
     * @param dbtKey канон
     * @param ttl сумма
     * @param varKey эталонный var
     */
    record SlotCanon(int slotKey, int dbtKey, BigDecimal ttl, Integer varKey) {
    }

    /**
     * Открытая строка очереди / доля свода.
     *
     * @param ciudKey ключ очереди
     * @param ttl сумма Excel
     * @param overd просрочка Excel
     * @param varKey var строки
     */
    record OpenShare(int ciudKey, BigDecimal ttl, BigDecimal overd, Integer varKey) {
    }

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
        return advise(
                row,
                excel,
                slots,
                slotAccnts,
                slotVars,
                f1UniqueSlot,
                newSumMatches,
                slotTimelines,
                excelStatusDate,
                epsilon,
                Optional.empty());
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
     * @param split готовый кандидат Split (S77.4)
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
            BigDecimal epsilon,
            Optional<SudzInvDbtSplitCandidate> split
    ) {
        Objects.requireNonNull(row, "row");
        BigDecimal eps = epsilon == null ? DEFAULT_EPS : epsilon;
        StringBuilder msg = new StringBuilder("[советник]");
        String confidence = "none";
        String action = "manual";
        Integer recommendSlot = null;
        Integer recommendVar = row.ciudIdvvKey();

        if (split != null && split.isPresent()) {
            SudzInvDbtSplitCandidate cand = split.get();
            appendLine(msg, "Свод " + cand.parts().size() + " строк, сумма "
                    + formatMoney(cand.sourceTtl())
                    + " = Value слота " + cand.sourceSlotKey()
                    + " (Dbt " + cand.dbtKey() + ")");
            appendLine(msg, "→ Split слота " + cand.sourceSlotKey()
                    + " на доли (уверенность: высокая) — не Link и не Create");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(),
                    "high",
                    "split",
                    cand.sourceSlotKey(),
                    row.ciudIdvvKey(),
                    cand.dbtKey(),
                    cand.uplKey(),
                    cand.parts());
        }

        if (row.ciudIdvvKey() == null || row.ciudIdvvKey() <= 0) {
            appendLine(msg, "Нет варианта контекста (invDbtVar) — сначала «Выбрать контекст»");
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
                appendLine(msg, "Счёт Excel (" + excelAccnt + ") совпадает со слотом "
                        + accntSlots.get(0));
            } else if (accntSlots.isEmpty()) {
                appendLine(msg, "Ни один слот не совпадает со счётом Excel (" + excelAccnt + ")");
            } else {
                appendLine(msg, "Счёт Excel (" + excelAccnt + ") — подходящие слоты: "
                        + accntSlots);
            }
        }

        if (f1UniqueSlot.isPresent()) {
            int slot = f1UniqueSlot.get();
            appendLine(msg, "Сумма Excel однозначно указывает на слот " + slot);
            appendRecommendLink(msg, slot, "high");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "link", slot, row.ciudIdvvKey());
        }

        if (newSumMatches.size() == 1) {
            SudzSfDoubleNewSumMatch m = newSumMatches.get(0);
            if (m.dvInvDbt() != null) {
                appendLine(msg, "Точное совпадение суммы в DbtValue: dvKey=" + m.dvKey()
                        + ", invDbt=" + m.dvInvDbt());
                appendRecommendLink(msg, m.dvInvDbt(), "high");
                return new SudzInvDbtDoubleAdvice(
                        msg.toString(), "high", "link", m.dvInvDbt(), row.ciudIdvvKey());
            }
        } else if (newSumMatches.isEmpty() && row.ciudDebt() != null) {
            appendLine(msg, "Якорь " + formatMoney(row.ciudDebt())
                    + " не найден в истории DbtValue (±" + eps + ")");
        }

        Integer bridgedSlot = slots.stream()
                .filter(s -> row.ciudIdvvKey().equals(slotVars.get(s.idKey())))
                .map(SudzInvDbtSlot::idKey)
                .findFirst()
                .orElse(null);
        if (bridgedSlot != null) {
            appendLine(msg, "Мост готов: var " + row.ciudIdvvKey()
                    + " уже привязан к слоту " + bridgedSlot);
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
            appendLine(msg, "Амортизация, слот " + bestAmort.slotId()
                    + " (" + bestAmort.label() + "): шаг "
                    + formatMoney(bestAmort.step()) + " × " + bestAmort.steps()
                    + " (R²=" + String.format(Locale.US, "%.4f", bestAmort.r2()) + ")");
            appendLine(msg, "Прогноз по разрыву: " + bestAmort.projectionLine());
            recommendSlot = bestAmort.slotId();
            confidence = bestAmort.confidence();
            action = "link";
            appendRecommendLink(msg, recommendSlot, confidence);
            appendLine(msg, "Причина: равномерная амортизация + "
                    + (bestAmort.projectionHit() ? "попадание Excel в тренд" : "сверить первичку"));
        } else if (bridgedSlot != null && excelAccnt != null
                && excelAccnt.equals(slotAccnts.get(bridgedSlot))) {
            recommendSlot = bridgedSlot;
            confidence = "medium";
            action = "link";
            appendRecommendLink(msg, bridgedSlot, confidence);
            appendLine(msg, "Причина: счёт Excel совпадает, мост var↔slot уже есть");
        } else {
            appendLine(msg, "Рекомендация: выберите слот вручную (по ciaName / контексту)");
        }

        appendLine(msg, "Примечание: советник не заменяет первичку; при средней или низкой "
                + "уверенности проверьте вручную");
        return new SudzInvDbtDoubleAdvice(
                msg.toString(), confidence, action, recommendSlot, recommendVar);
    }

    /**
     * N строк свода на СФ, сумма = Value слота, каждая строка ≠ целому → Split.
     *
     * @param row текущая строка очереди
     * @param shares открытые доли той же СФ/upl (включая текущую)
     * @param canons слоты с последней Value
     * @param uplKey срез
     * @param epsilon допуск
     * @return кандидат или empty
     */
    static Optional<SudzInvDbtSplitCandidate> detectSplit(
            SudzCnInvUplInvDbtDouble row,
            List<OpenShare> shares,
            List<SlotCanon> canons,
            int uplKey,
            BigDecimal epsilon
    ) {
        Objects.requireNonNull(row, "row");
        BigDecimal eps = epsilon == null ? DEFAULT_EPS : epsilon;
        if (shares == null || shares.size() < 2 || canons == null || canons.isEmpty() || uplKey <= 0) {
            return Optional.empty();
        }
        boolean currentInShares = shares.stream().anyMatch(s -> s.ciudKey() == row.ciudKey());
        if (!currentInShares) {
            return Optional.empty();
        }
        BigDecimal sum = BigDecimal.ZERO;
        for (OpenShare share : shares) {
            if (share.ttl() == null || share.ttl().compareTo(BigDecimal.ZERO) <= 0) {
                return Optional.empty();
            }
            sum = sum.add(share.ttl());
        }
        List<SlotCanon> matches = new ArrayList<>();
        for (SlotCanon canon : canons) {
            if (canon.ttl() == null) {
                continue;
            }
            if (canon.ttl().subtract(sum).abs().compareTo(eps) > 0) {
                continue;
            }
            boolean shareEqualsWhole = shares.stream()
                    .anyMatch(s -> s.ttl().subtract(canon.ttl()).abs().compareTo(eps) <= 0);
            if (shareEqualsWhole) {
                continue;
            }
            matches.add(canon);
        }
        if (matches.size() != 1) {
            return Optional.empty();
        }
        SlotCanon canon = matches.get(0);
        List<SudzDbtSplitPart> parts = new ArrayList<>();
        int i = 1;
        for (OpenShare share : shares) {
            parts.add(new SudzDbtSplitPart(
                    share.ttl(),
                    share.overd(),
                    share.varKey(),
                    "S77-split-" + i++,
                    null,
                    null,
                    null,
                    share.ciudKey()));
        }
        return Optional.of(new SudzInvDbtSplitCandidate(
                canon.dbtKey(),
                canon.slotKey(),
                uplKey,
                canon.ttl(),
                List.copyOf(parts)));
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
        String projectionLine = "нет даты среза выгрузки";
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
        String label = slotNote != null && !slotNote.isBlank() ? slotNote : "слот " + slotId;
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

    private static void appendRecommendLink(StringBuilder sb, int slot, String confidence) {
        appendLine(sb, "→ Связать со слотом " + slot + " (уверенность: "
                + confidenceRu(confidence) + ")");
    }

    private static String confidenceRu(String confidence) {
        return switch (confidence) {
            case "high" -> "высокая";
            case "medium" -> "средняя";
            case "low" -> "низкая";
            case "none" -> "нет";
            default -> confidence;
        };
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
