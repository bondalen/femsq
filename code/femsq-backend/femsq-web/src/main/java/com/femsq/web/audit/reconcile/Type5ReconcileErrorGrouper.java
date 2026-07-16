package com.femsq.web.audit.reconcile;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Группировка ошибок сверки type=5 для дерева лога (§9.3.8.3): значение → Excel-строки,
 * с одной primary reason на строку.
 */
public final class Type5ReconcileErrorGrouper {

    /** Корневая причина: стройка отсутствует / не найдена. */
    public static final String PRIMARY_MISSING_CSTAP = "MISSING_CSTAP";
    /** Корневая причина: отправитель отсутствует / не найден. */
    public static final String PRIMARY_MISSING_SENDER = "MISSING_SENDER";
    /** Неоднозначное сопоставление в домене. */
    public static final String PRIMARY_AMBIGUOUS = "AMBIGUOUS";
    /** Прочие отказы (период, parse, base RA, disallowed sign, …). */
    public static final String PRIMARY_OTHER = "OTHER";

    /** Макс. значений в категории при SUMMARY. */
    public static final int SUMMARY_VALUE_LIMIT = 40;
    /** Макс. Excel-строк в одном значении при SUMMARY. */
    public static final int SUMMARY_ROWS_PER_VALUE = 30;

    private Type5ReconcileErrorGrouper() {
    }

    /**
     * Одна отказной строки staging с выбранной primary reason.
     *
     * @param excelSign     Excel-признак ({@code ОА} / {@code ОА прочие} / {@code ОА изм})
     * @param excelRow      1-based Excel или {@code null}
     * @param primaryReason код primary ({@link #PRIMARY_MISSING_CSTAP} и т.п.)
     * @param groupValue    значение для группировки (код стройки / имя отправителя); для OTHER может быть null
     * @param reasonCode    технический код отказа
     * @param detail        человекочитаемый текст
     * @param domainRaType  для RC: {@code ОА} / {@code ОА, прочие} после resolve; иначе null (orphan)
     */
    public record ErrorHit(
            String excelSign,
            Integer excelRow,
            String primaryReason,
            String groupValue,
            String reasonCode,
            String detail,
            String domainRaType
    ) {
        /** Hit без доменного типа базы. */
        public static ErrorHit of(
                String excelSign,
                Integer excelRow,
                String primaryReason,
                String groupValue,
                String reasonCode,
                String detail
        ) {
            return new ErrorHit(excelSign, excelRow, primaryReason, groupValue, reasonCode, detail, null);
        }
    }

    /**
     * Группа «значение → список Excel-строк».
     *
     * @param value              значение (код/имя)
     * @param excelRows          показанные номера строк
     * @param suppressedRowCount скрытые сверх лимита
     * @param reasonCodeSample   sample reasonCode для meta
     */
    public record ValueGroup(
            String value,
            List<Integer> excelRows,
            int suppressedRowCount,
            String reasonCodeSample
    ) {
    }

    /**
     * Прочая ошибка без value-группировки.
     *
     * @param excelRow   Excel-строка
     * @param message    текст
     * @param reasonCode код
     */
    public record OtherHit(Integer excelRow, String message, String reasonCode) {
    }

    /**
     * Дерево ошибок одной конечной ветки сверки.
     *
     * @param totalHits      всего hit'ов
     * @param missingCstap   отсутствуют стройки
     * @param missingSender  отсутствует отправитель
     * @param ambiguous      неоднозначность
     * @param others         иные
     * @param othersOverflow сколько «иных» скрыто лимитом
     */
    public record ErrorTree(
            int totalHits,
            List<ValueGroup> missingCstap,
            List<ValueGroup> missingSender,
            List<ValueGroup> ambiguous,
            List<OtherHit> others,
            int othersOverflow
    ) {
        /** Пустое дерево. */
        public static ErrorTree empty() {
            return new ErrorTree(0, List.of(), List.of(), List.of(), List.of(), 0);
        }

        /** @return есть ли хотя бы одна ошибка */
        public boolean hasErrors() {
            return totalHits > 0;
        }
    }

    /**
     * Группирует hit'ы с учётом лимитов SUMMARY/VERBOSE.
     *
     * @param hits  отказы
     * @param limit лимит значений / прочих строк ({@link Integer#MAX_VALUE} = без лимита; 0 = пусто)
     * @return дерево для лога
     */
    public static ErrorTree group(List<ErrorHit> hits, int limit) {
        if (hits == null || hits.isEmpty() || limit <= 0) {
            int total = hits == null ? 0 : hits.size();
            return total == 0 ? ErrorTree.empty() : new ErrorTree(total, List.of(), List.of(), List.of(), List.of(), total);
        }
        int valueLimit = Math.min(limit, SUMMARY_VALUE_LIMIT);
        int rowsPerValue = limit >= Integer.MAX_VALUE / 2
                ? Integer.MAX_VALUE
                : SUMMARY_ROWS_PER_VALUE;

        List<ValueGroup> cstap = groupByValue(
                hits.stream().filter(h -> PRIMARY_MISSING_CSTAP.equals(h.primaryReason())).toList(),
                valueLimit,
                rowsPerValue
        );
        List<ValueGroup> sender = groupByValue(
                hits.stream().filter(h -> PRIMARY_MISSING_SENDER.equals(h.primaryReason())).toList(),
                valueLimit,
                rowsPerValue
        );
        List<ValueGroup> ambiguous = groupByValue(
                hits.stream().filter(h -> PRIMARY_AMBIGUOUS.equals(h.primaryReason())).toList(),
                valueLimit,
                rowsPerValue
        );
        List<ErrorHit> otherHits = hits.stream().filter(h -> PRIMARY_OTHER.equals(h.primaryReason())).toList();
        List<OtherHit> others = new ArrayList<>();
        int othersOverflow = 0;
        int shown = 0;
        for (ErrorHit hit : otherHits) {
            if (shown >= valueLimit) {
                othersOverflow++;
                continue;
            }
            shown++;
            String msg = hit.detail() != null && !hit.detail().isBlank()
                    ? hit.detail()
                    : (hit.reasonCode() == null ? "ошибка" : hit.reasonCode());
            others.add(new OtherHit(hit.excelRow(), msg, hit.reasonCode()));
        }
        return new ErrorTree(hits.size(), cstap, sender, ambiguous, List.copyOf(others), othersOverflow);
    }

    private static List<ValueGroup> groupByValue(List<ErrorHit> hits, int valueLimit, int rowsPerValue) {
        Map<String, Acc> byValue = new LinkedHashMap<>();
        for (ErrorHit hit : hits) {
            String key = hit.groupValue() == null || hit.groupValue().isBlank()
                    ? "(пусто)"
                    : hit.groupValue().trim();
            Acc acc = byValue.computeIfAbsent(key, ignored -> new Acc());
            if (hit.excelRow() != null) {
                acc.rows.add(hit.excelRow());
            } else {
                acc.nullRowCount++;
            }
            if (acc.reasonSample == null) {
                acc.reasonSample = hit.reasonCode();
            }
        }
        List<Map.Entry<String, Acc>> ordered = new ArrayList<>(byValue.entrySet());
        ordered.sort(Comparator
                .comparingInt((Map.Entry<String, Acc> e) -> -(e.getValue().rows.size() + e.getValue().nullRowCount))
                .thenComparing(Map.Entry::getKey));

        List<ValueGroup> result = new ArrayList<>();
        int valueIndex = 0;
        for (Map.Entry<String, Acc> entry : ordered) {
            if (valueIndex >= valueLimit) {
                break;
            }
            valueIndex++;
            Acc acc = entry.getValue();
            List<Integer> sortedRows = new ArrayList<>(acc.rows);
            sortedRows.sort(Integer::compareTo);
            int suppressed = 0;
            List<Integer> shownRows;
            if (sortedRows.size() > rowsPerValue) {
                shownRows = List.copyOf(sortedRows.subList(0, rowsPerValue));
                suppressed = sortedRows.size() - rowsPerValue;
            } else {
                shownRows = List.copyOf(sortedRows);
            }
            // null Excel-row учитываем в suppressed, если нечего показать
            if (shownRows.isEmpty() && acc.nullRowCount > 0) {
                suppressed += acc.nullRowCount;
            } else if (sortedRows.size() <= rowsPerValue) {
                suppressed += acc.nullRowCount;
            }
            result.add(new ValueGroup(entry.getKey(), shownRows, suppressed, acc.reasonSample));
        }
        return List.copyOf(result);
    }

    /**
     * Выбирает primary reason для отказа RA с INVALID_CANONICAL / lookup.
     * Приоритет: стройка → отправитель → иное.
     *
     * @param cstapMissing нет/не найдена стройка
     * @param senderMissing нет/не найден отправитель
     * @param periodMissing нет периода
     * @param raNumMissing  нет номера
     * @return primary reason code
     */
    public static String primaryForCanonicalGaps(
            boolean cstapMissing,
            boolean senderMissing,
            boolean periodMissing,
            boolean raNumMissing
    ) {
        if (cstapMissing) {
            return PRIMARY_MISSING_CSTAP;
        }
        if (senderMissing) {
            return PRIMARY_MISSING_SENDER;
        }
        return PRIMARY_OTHER;
    }

    private static final class Acc {
        private final Set<Integer> rows = new LinkedHashSet<>();
        private int nullRowCount;
        private String reasonSample;
    }

    /**
     * Фильтр hit'ов по Excel-признаку (для собственно ОА / ОА прочие).
     *
     * @param hits все hit'ы
     * @param excelSign признак
     * @return отфильтрованный список
     */
    public static List<ErrorHit> filterByExcelSign(List<ErrorHit> hits, String excelSign) {
        if (hits == null || hits.isEmpty()) {
            return List.of();
        }
        List<ErrorHit> out = new ArrayList<>();
        for (ErrorHit hit : hits) {
            if (Objects.equals(excelSign, hit.excelSign())) {
                out.add(hit);
            }
        }
        return out;
    }

    /**
     * Фильтр RC-hit'ов по доменному типу базы; {@code domainRaType == null} — без resolve базы (orphan).
     *
     * @param hits         hit'ы (обычно только «ОА изм»)
     * @param domainRaType {@link Type5ReconcileTreeLogger#DOMAIN_OA} / OTHER / {@code null} для orphan
     * @return отфильтрованный список
     */
    public static List<ErrorHit> filterByDomainRaType(List<ErrorHit> hits, String domainRaType) {
        if (hits == null || hits.isEmpty()) {
            return List.of();
        }
        List<ErrorHit> out = new ArrayList<>();
        for (ErrorHit hit : hits) {
            if (!"ОА изм".equals(hit.excelSign())) {
                continue;
            }
            if (domainRaType == null) {
                if (hit.domainRaType() == null) {
                    out.add(hit);
                }
            } else if (domainRaType.equals(hit.domainRaType())) {
                out.add(hit);
            }
        }
        return out;
    }
}
