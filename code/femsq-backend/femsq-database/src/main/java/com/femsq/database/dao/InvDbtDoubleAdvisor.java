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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

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
     * Строка очереди / доля свода (open или уже Linked).
     *
     * @param ciudKey ключ очереди
     * @param ttl сумма Excel
     * @param overd просрочка Excel
     * @param varKey var строки
     * @param linkedSlotKey {@code ciudCreatedIdKey} после Link/Create; иначе null
     */
    record OpenShare(
            int ciudKey,
            BigDecimal ttl,
            BigDecimal overd,
            Integer varKey,
            Integer linkedSlotKey
    ) {
        /**
         * Open-доля без привязанного слота.
         *
         * @param ciudKey ключ
         * @param ttl сумма
         * @param overd просрочка
         * @param varKey var
         */
        OpenShare(int ciudKey, BigDecimal ttl, BigDecimal overd, Integer varKey) {
            this(ciudKey, ttl, overd, varKey, null);
        }
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
                Optional.empty(),
                Optional.empty(),
                List.of());
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
                split,
                Optional.empty(),
                List.of());
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
     * @param existingShareSlot слот-доля при уже выполненном Split
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
            Optional<SudzInvDbtSplitCandidate> split,
            Optional<Integer> existingShareSlot
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
                split,
                existingShareSlot,
                List.of());
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
     * @param existingShareSlot слот-доля при уже выполненном Split
     * @param openShares open-строки той же СФ/upl (для подсказки «впервые N»)
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
            Optional<SudzInvDbtSplitCandidate> split,
            Optional<Integer> existingShareSlot,
            List<OpenShare> openShares
    ) {
        Objects.requireNonNull(row, "row");
        BigDecimal eps = epsilon == null ? DEFAULT_EPS : epsilon;
        StringBuilder msg = new StringBuilder("[советник]");
        String confidence = "none";
        String action = "manual";
        Integer recommendSlot = null;
        Integer recommendVar = row.ciudIdvvKey();
        int openShareCount = openShares == null
                ? 0
                : (int) openShares.stream()
                .filter(s -> s.linkedSlotKey() == null || s.linkedSlotKey() <= 0)
                .count();

        if (row.ciudCreatedIdKey() != null && row.ciudCreatedIdKey() > 0
                && "created".equalsIgnoreCase(row.ciudStatus())) {
            int linked = row.ciudCreatedIdKey();
            appendLine(msg, "Строка уже связана со слотом " + linked
                    + " — повторный Link не нужен");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "linked", linked, row.ciudIdvvKey());
        }

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

        if (existingShareSlot != null && existingShareSlot.isPresent()) {
            int slot = existingShareSlot.get();
            appendLine(msg, "Доли канона уже созданы — Split не нужен");
            appendLine(msg, "Сумма Excel совпадает с долей-слотом " + slot);
            appendRecommendLink(msg, slot, "high");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "link", slot, row.ciudIdvvKey());
        }

        if (row.ciudIdvvKey() == null || row.ciudIdvvKey() <= 0) {
            appendLine(msg, "Нет варианта контекста (invDbtVar) — сначала «Выбрать контекст»");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "create_var", null, null);
        }

        if (slots == null || slots.isEmpty()) {
            appendLine(msg, "На СФ нет слотов invDbt");
            if (openShareCount >= 2) {
                appendLine(msg, "В очереди " + openShareCount
                        + " open-задолженности на эту СФ — Create по одной на каждую строку"
                        + " (не Split: нет канона-целого)");
            }
            appendLine(msg, "→ Создать слот под сумму Excel "
                    + formatMoney(row.ciudDebt())
                    + " (уверенность: высокая)");
            return new SudzInvDbtDoubleAdvice(
                    msg.toString(), "high", "create_slot", null, row.ciudIdvvKey());
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

        List<Integer> bridgedSlots = slots.stream()
                .filter(s -> row.ciudIdvvKey().equals(slotVars.get(s.idKey())))
                .map(SudzInvDbtSlot::idKey)
                .toList();
        Integer bridgedSlot = bridgedSlots.size() == 1 ? bridgedSlots.get(0) : null;
        boolean bridgeSumMatches = bridgedSlot != null
                && slotLatestTtlMatches(bridgedSlot, row.ciudDebt(), slotTimelines, eps);
        boolean slotClaimedByOtherShare = bridgedSlot != null && openShares != null
                && openShares.stream().anyMatch(s ->
                s.linkedSlotKey() != null
                        && s.linkedSlotKey() == bridgedSlot
                        && s.ciudKey() != row.ciudKey());
        if (bridgedSlots.size() == 1) {
            appendLine(msg, "Мост готов: var " + row.ciudIdvvKey()
                    + " уже привязан к слоту " + bridgedSlot);
            if (slotClaimedByOtherShare) {
                appendLine(msg, "Слот " + bridgedSlot
                        + " уже занят другой строкой очереди — нужен свой Create");
            } else if (!bridgeSumMatches && row.ciudDebt() != null) {
                appendLine(msg, "Сумма Excel " + formatMoney(row.ciudDebt())
                        + " ≠ Value слота " + bridgedSlot
                        + " — Link по мосту не предлагаем (нужен свой слот)");
            }
        } else if (bridgedSlots.size() > 1) {
            appendLine(msg, "Мост var " + row.ciudIdvvKey()
                    + " неоднозначен (несколько слотов: " + bridgedSlots
                    + ") — не используем для Link");
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
        }
        if (bestAmort != null && bestAmort.projectionHit()) {
            recommendSlot = bestAmort.slotId();
            confidence = bestAmort.confidence();
            action = "link";
            appendRecommendLink(msg, recommendSlot, confidence);
            appendLine(msg, "Причина: равномерная амортизация + попадание Excel в тренд");
        } else {
            if (bestAmort != null) {
                appendLine(msg, "Прогноз не попал в Excel — amort не используем для Link"
                        + " (слот " + bestAmort.slotId() + ")");
            }
            if (bridgedSlot != null && bridgeSumMatches && !slotClaimedByOtherShare
                    && excelAccnt != null
                    && excelAccnt.equals(slotAccnts.get(bridgedSlot))) {
                recommendSlot = bridgedSlot;
                confidence = "medium";
                action = "link";
                appendRecommendLink(msg, bridgedSlot, confidence);
                appendLine(msg, "Причина: счёт Excel совпадает, мост var↔slot уже есть,"
                        + " сумма слота совпадает с Excel");
            } else {
                appendLine(msg, "Ни один слот не подходит под сумму Excel "
                        + formatMoney(row.ciudDebt()));
                appendLine(msg, "→ Создать новый слот (уверенность: высокая) — не Link на чужой");
                return new SudzInvDbtDoubleAdvice(
                        msg.toString(), "high", "create_slot", null, row.ciudIdvvKey());
            }
        }

        appendLine(msg, "Примечание: советник не заменяет первичку; при средней или низкой "
                + "уверенности проверьте вручную");
        return new SudzInvDbtDoubleAdvice(
                msg.toString(), confidence, action, recommendSlot, recommendVar);
    }

    /**
     * N строк свода на СФ, сумма = Value слота, каждая строка ≠ целому → Split.
     * Если у того же {@code dbt} уже есть слоты-доли с Value под open-строки — empty
     * (повторный Split не предлагать; см. {@link #findExistingShareLink}).
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
            if (sharesAlreadyCoveredBySiblingSlots(canon, shares, canons, eps)) {
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

    /**
     * Слот-доля для Link, когда Split уже выполнен.
     * Учитывает уже Linked строки ({@code linkedSlotKey}): свободным open
     * назначаются оставшиеся доли (не повтор того же слота).
     *
     * @param row текущая строка очереди
     * @param shares доли той же СФ/upl (open + created)
     * @param canons слоты с последней Value
     * @param epsilon допуск
     * @return {@code invDbt.idKey} доли или empty
     */
    static Optional<Integer> findExistingShareLink(
            SudzCnInvUplInvDbtDouble row,
            List<OpenShare> shares,
            List<SlotCanon> canons,
            BigDecimal epsilon
    ) {
        Objects.requireNonNull(row, "row");
        BigDecimal eps = epsilon == null ? DEFAULT_EPS : epsilon;
        if (shares == null || shares.isEmpty() || canons == null || canons.isEmpty()) {
            return Optional.empty();
        }
        OpenShare current = shares.stream()
                .filter(s -> s.ciudKey() == row.ciudKey())
                .findFirst()
                .orElse(null);
        if (current == null) {
            return Optional.empty();
        }
        if (current.linkedSlotKey() != null && current.linkedSlotKey() > 0) {
            return Optional.empty();
        }
        for (OpenShare share : shares) {
            if (share.ttl() == null || share.ttl().compareTo(BigDecimal.ZERO) <= 0) {
                return Optional.empty();
            }
        }
        BigDecimal familySum = shares.stream()
                .map(OpenShare::ttl)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        Set<Integer> usedSlots = shares.stream()
                .map(OpenShare::linkedSlotKey)
                .filter(k -> k != null && k > 0)
                .collect(Collectors.toCollection(java.util.LinkedHashSet::new));
        List<OpenShare> openShares = shares.stream()
                .filter(s -> s.linkedSlotKey() == null || s.linkedSlotKey() <= 0)
                .toList();
        if (openShares.isEmpty()) {
            return Optional.empty();
        }
        Map<Integer, List<SlotCanon>> byDbt = canons.stream()
                .collect(Collectors.groupingBy(SlotCanon::dbtKey, LinkedHashMap::new, Collectors.toList()));
        for (List<SlotCanon> group : byDbt.values()) {
            List<SlotCanon> partSlots = group.stream()
                    .filter(c -> c.ttl() != null
                            && c.ttl().subtract(familySum).abs().compareTo(eps) > 0)
                    .filter(c -> !usedSlots.contains(c.slotKey()))
                    .toList();
            Map<Integer, Integer> assignment = matchSharesToSlots(openShares, partSlots, eps);
            if (assignment.size() == openShares.size() && assignment.containsKey(row.ciudKey())) {
                return Optional.of(assignment.get(row.ciudKey()));
            }
        }
        return Optional.empty();
    }

    /**
     * У канона-целого уже есть слоты-доли того же {@code dbt}, Value которых покрывают open-строки.
     *
     * @param wholeCanon слот с суммой = ∑ open
     * @param shares open-строки
     * @param canons все каноны СФ
     * @param epsilon допуск
     * @return true если Split уже сделан
     */
    private static boolean sharesAlreadyCoveredBySiblingSlots(
            SlotCanon wholeCanon,
            List<OpenShare> shares,
            List<SlotCanon> canons,
            BigDecimal epsilon
    ) {
        List<SlotCanon> siblings = canons.stream()
                .filter(c -> c.dbtKey() == wholeCanon.dbtKey()
                        && c.slotKey() != wholeCanon.slotKey())
                .toList();
        return matchSharesToSlots(shares, siblings, epsilon).size() == shares.size();
    }

    /**
     * Жадное сопоставление open-строк со слотами по сумме (±ε), порядок: ciudKey → idKey.
     *
     * @param shares доли свода
     * @param slots кандидаты слотов
     * @param epsilon допуск
     * @return ciudKey → slotKey; неполный при невозможности покрыть все доли
     */
    private static Map<Integer, Integer> matchSharesToSlots(
            List<OpenShare> shares,
            List<SlotCanon> slots,
            BigDecimal epsilon
    ) {
        Map<Integer, Integer> assignment = new LinkedHashMap<>();
        if (shares == null || slots == null || slots.isEmpty()) {
            return assignment;
        }
        List<OpenShare> orderedShares = shares.stream()
                .sorted(Comparator.comparingInt(OpenShare::ciudKey))
                .toList();
        List<SlotCanon> available = new ArrayList<>(slots);
        for (OpenShare share : orderedShares) {
            Optional<SlotCanon> match = available.stream()
                    .filter(s -> s.ttl() != null
                            && share.ttl().subtract(s.ttl()).abs().compareTo(epsilon) <= 0)
                    .min(Comparator.comparingInt(SlotCanon::slotKey));
            if (match.isEmpty()) {
                return Map.of();
            }
            assignment.put(share.ciudKey(), match.get().slotKey());
            available.remove(match.get());
        }
        return assignment;
    }

    /**
     * Последняя Value слота (±ε) совпадает с суммой Excel.
     * Пустой ряд — считаем совместимым (слот ещё без истории).
     *
     * @param slotKey слот
     * @param debt сумма Excel
     * @param slotTimelines ряды
     * @param epsilon допуск
     * @return true если можно Link по сумме
     */
    private static boolean slotLatestTtlMatches(
            int slotKey,
            BigDecimal debt,
            java.util.Map<Integer, List<SudzInvDbtTimelinePoint>> slotTimelines,
            BigDecimal epsilon
    ) {
        if (debt == null) {
            return false;
        }
        List<SudzInvDbtTimelinePoint> pts = slotTimelines == null
                ? List.of()
                : slotTimelines.getOrDefault(slotKey, List.of());
        SudzInvDbtTimelinePoint last = pts.stream()
                .filter(p -> p != null && p.statusDate() != null && p.ttl() != null)
                .max(Comparator.comparing(SudzInvDbtTimelinePoint::statusDate)
                        .thenComparing(p -> p.uplKey() == null ? Integer.MIN_VALUE : p.uplKey()))
                .orElse(null);
        if (last == null) {
            return false;
        }
        return last.ttl().subtract(debt).abs().compareTo(epsilon) <= 0;
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
        /**
         * Попадание Excel в прогноз важнее «красивого» R² без попадания.
         */
        double score() {
            if (projectionHit) {
                return 100.0 + r2;
            }
            return r2;
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

    /**
     * Равномерная амортизация хвоста: шаг нормируется на число кварталов между точками
     * (разрыв в 2 квартала → два шага {@code Δ/2}), иначе дыры в ряде ломают R².
     */
    private static AmortizationResult tryUniformTail(
            int slotId,
            String slotNote,
            List<SudzInvDbtTimelinePoint> tail,
            BigDecimal excelDebt,
            LocalDate excelStatusDate,
            BigDecimal epsilon
    ) {
        List<BigDecimal> perQuarterDeltas = new ArrayList<>();
        for (int i = 1; i < tail.size(); i++) {
            SudzInvDbtTimelinePoint prev = tail.get(i - 1);
            SudzInvDbtTimelinePoint next = tail.get(i);
            BigDecimal raw = next.ttl().subtract(prev.ttl());
            long days = ChronoUnit.DAYS.between(prev.statusDate(), next.statusDate());
            int quarters = Math.max(1, (int) Math.round(days / 91.25));
            BigDecimal perQ = raw.divide(BigDecimal.valueOf(quarters), 4, RoundingMode.HALF_UP);
            for (int q = 0; q < quarters; q++) {
                perQuarterDeltas.add(perQ);
            }
        }
        boolean allNonPositive = perQuarterDeltas.stream().allMatch(d -> d.signum() <= 0);
        boolean anyNegative = perQuarterDeltas.stream().anyMatch(d -> d.signum() < 0);
        if (!allNonPositive || !anyNegative) {
            return null;
        }
        List<BigDecimal> negativeDeltas = perQuarterDeltas.stream()
                .filter(d -> d.signum() < 0)
                .toList();
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
                int qSteps = Math.max(1, (int) Math.round(days / 91.25));
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
