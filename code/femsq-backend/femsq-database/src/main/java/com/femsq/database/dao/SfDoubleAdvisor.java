package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzSfDoubleAdvice;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import com.femsq.database.model.sudz.SudzSfDoubleHintItem;
import com.femsq.database.model.sudz.SudzSfDoubleHintSection;
import com.femsq.database.model.sudz.SudzSfDoubleHints;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;

/**
 * Эвристики советника КСДСФ: текст {@code [советник]} для оператора.
 */
final class SfDoubleAdvisor {

    private SfDoubleAdvisor() {
    }

    /**
     * Сформировать совет по строке очереди КСДСФ.
     *
     * @param row строка очереди
     * @param excel Excel-кандидат (может быть null)
     * @param hints подсказки по исполнителю
     * @param domainMatches все СФ с тем же номером в ags
     * @return совет
     */
    static SudzSfDoubleAdvice advise(
            SudzCnInvUplSfDouble row,
            SudzSfDoubleExcelCandidate excel,
            SudzSfDoubleHints hints,
            List<SudzSfDoubleDomainMatch> domainMatches
    ) {
        Objects.requireNonNull(row, "row");
        Objects.requireNonNull(hints, "hints");
        List<SudzSfDoubleDomainMatch> domain = domainMatches == null ? List.of() : domainMatches;

        StringBuilder msg = new StringBuilder("[советник]");
        appendLine(msg, "Очередь cius=" + row.ciusKey()
                + " · договор cn=" + (row.ciusCnKey() != null ? row.ciusCnKey() : "—")
                + " «" + nullToDash(row.ciusCnNum()) + "» · СФ «" + nullToDash(row.ciusInvNum()) + "»");
        if (excel != null && excel.cidutDebt() != null) {
            appendLine(msg, "Якорь Excel: сумма " + excel.cidutDebt());
        }

        if (row.ciusCnKey() == null || row.ciusCnKey() <= 0) {
            appendLine(msg, "На строке нет договора (ciusCnKey) — «Создать СФ по Excel» недоступно");
            appendLine(msg, "→ Ручной разбор: привязать договор на предыдущих шагах воронки");
            return finish(msg, "high", "manual", null, null);
        }

        SudzSfDoubleHintSection sfByNum = hints.sfByNum();
        appendLine(msg, "СФ по номеру: " + sfByNum.message());

        if ("yes".equals(sfByNum.status())) {
            if (sfByNum.totalCount() == 1 && !sfByNum.items().isEmpty()) {
                SudzSfDoubleHintItem item = sfByNum.items().get(0);
                if (Objects.equals(item.cnKey(), row.ciusCnKey())) {
                    appendLine(msg, "Один СФ с этим номером и исполнителем Excel на договоре очереди (executor_unique)");
                    return linkAdvice(msg, "high", item, row.ciusCnKey());
                }
                if (cnNumbersAreVariants(row.ciusCnNum(), item.cnNum())) {
                    Integer canonicalCn = item.cnKey();
                    Integer invKey = item.invKey();
                    boolean invOnCanonical = invKey != null && domain.stream()
                            .anyMatch(m -> invKey.equals(m.invKey())
                                    && Objects.equals(m.cnKey(), canonicalCn));
                    boolean queueCnDiffers = canonicalCn != null
                            && !Objects.equals(row.ciusCnKey(), canonicalCn);
                    if (invOnCanonical && queueCnDiffers) {
                        appendLine(msg, "СФ inv=" + invKey + " уже на договоре cn=" + canonicalCn
                                + " «" + nullToDash(item.cnNum()) + "»");
                        appendLine(msg, "Номер Excel «" + nullToDash(row.ciusCnNum())
                                + "» — вероятно второй номер того же договора (cn_num_alias)");
                        appendRecommendAliasCnNum(msg, row, item, confidenceForVariantLink(hints, row));
                        return finish(msg, confidenceForVariantLink(hints, row), "alias_cn_num",
                                invKey, canonicalCn);
                    }
                    appendLine(msg, "СФ с номером и исполнителем Excel на варианте номера договора (cn_num_variant)");
                    appendLine(msg, "Существующий inv=" + (invKey != null ? invKey : item.pickValue())
                            + " на «" + nullToDash(item.cnNum()) + "» (cn=" + item.cnKey()
                            + "), очередь на «" + nullToDash(row.ciusCnNum()) + "» (cn=" + row.ciusCnKey() + ")");
                    String confidence = confidenceForVariantLink(hints, row);
                    if ("high".equals(confidence)) {
                        appendLine(msg, "Уникальное совпадение суммы с исполнителем Excel — уверенность повышена");
                    }
                    return linkAdvice(msg, confidence, item, item.cnKey());
                }
                Optional<SudzSfDoubleAdvice> sumLink = tryLinkByUniqueSumOnExcelCn(msg, hints, row);
                if (sumLink.isPresent()) {
                    return sumLink.get();
                }
                appendLine(msg, "СФ с номером и исполнителем Excel найден на другом договоре (cn_homonym)");
                appendRecommendCreate(msg, "high");
                appendLine(msg, "Причина: inv=" + (item.invKey() != null ? item.invKey() : item.pickValue())
                        + " на cn=" + (item.cnKey() != null ? item.cnKey() : "—")
                        + " «" + nullToDash(item.cnNum()) + "», очередь cn=" + row.ciusCnKey()
                        + " «" + nullToDash(row.ciusCnNum()) + "»");
                return finish(msg, "high", "create", null, row.ciusCnKey());
            }
            if (sfByNum.totalCount() > 1) {
                List<SudzSfDoubleHintItem> onCn = sfByNum.items().stream()
                        .filter(it -> Objects.equals(it.cnKey(), row.ciusCnKey()))
                        .toList();
                if (onCn.size() == 1) {
                    appendLine(msg, "Среди совпадений по исполнителю один СФ на договоре Excel (cn_exact)");
                    return linkAdvice(msg, "high", onCn.get(0), row.ciusCnKey());
                }
                List<SudzSfDoubleHintItem> onVariant = sfByNum.items().stream()
                        .filter(it -> cnNumbersAreVariants(row.ciusCnNum(), it.cnNum()))
                        .toList();
                if (onVariant.size() == 1) {
                    SudzSfDoubleHintItem item = onVariant.get(0);
                    Integer invKey = item.invKey();
                    boolean invOnCanonical = invKey != null && domain.stream()
                            .anyMatch(m -> invKey.equals(m.invKey())
                                    && Objects.equals(m.cnKey(), item.cnKey()));
                    if (invOnCanonical && !Objects.equals(row.ciusCnKey(), item.cnKey())) {
                        appendLine(msg, "Среди совпадений один СФ на варианте номера — cn_num_alias");
                        appendRecommendAliasCnNum(msg, row, item, confidenceForVariantLink(hints, row));
                        return finish(msg, confidenceForVariantLink(hints, row), "alias_cn_num",
                                invKey, item.cnKey());
                    }
                    appendLine(msg, "Среди совпадений один СФ на варианте номера договора (cn_num_variant)");
                    String confidence = confidenceForVariantLink(hints, row);
                    if ("high".equals(confidence)) {
                        appendLine(msg, "Уникальное совпадение суммы с исполнителем Excel — уверенность повышена");
                    }
                    return linkAdvice(msg, confidence, item, item.cnKey());
                }
                if (onCn.size() > 1) {
                    appendLine(msg, "Несколько СФ с номером на договоре Excel — выберите вручную");
                    appendSumHints(msg, hints);
                    return finish(msg, "medium", "manual", null, row.ciusCnKey());
                }
                appendLine(msg, "Совпадения по исполнителю на других договорах — не связывать вслепую");
            }
        }

        if ("no".equals(sfByNum.status())) {
            Optional<SudzSfDoubleAdvice> sumLink = tryLinkByUniqueSumOnExcelCn(msg, hints, row);
            if (sumLink.isPresent()) {
                return sumLink.get();
            }
            long homonymOnExcelCn = domain.stream()
                    .filter(m -> Objects.equals(m.cnKey(), row.ciusCnKey()))
                    .map(SudzSfDoubleDomainMatch::invKey)
                    .distinct()
                    .count();
            long homonymElsewhere = domain.stream()
                    .filter(m -> !Objects.equals(m.cnKey(), row.ciusCnKey()))
                    .map(SudzSfDoubleDomainMatch::invKey)
                    .distinct()
                    .count();
            if (homonymElsewhere > 0 && homonymOnExcelCn == 0) {
                appendLine(msg, "Однофамильцы СФ на других договорах (cn_homonym), исполнитель Excel не совпал");
                appendRecommendCreate(msg, "high");
                appendLine(msg, "Причина: номер занят на чужом договоре — создать новый СФ на договоре Excel");
                return finish(msg, "high", "create", null, row.ciusCnKey());
            }
            appendLine(msg, "Среди однофамильцев нет совпадения исполнителя (executor_none)");
            appendRecommendCreate(msg, "high");
            appendLine(msg, "Причина: в ags нет СФ с этим номером и исполнителем Excel");
            return finish(msg, "high", "create", null, row.ciusCnKey());
        }

        Optional<SudzSfDoubleAdvice> sumLink = tryLinkByUniqueSumOnExcelCn(msg, hints, row);
        if (sumLink.isPresent()) {
            return sumLink.get();
        }
        Optional<SudzSfDoubleHintItem> sumItem = uniqueSumHintForRow(hints, row);
        if (sumItem.isPresent()) {
            List<SudzSfDoubleDomainMatch> onCn = domain.stream()
                    .filter(m -> Objects.equals(m.cnKey(), row.ciusCnKey()))
                    .toList();
            if (onCn.size() == 1) {
                SudzSfDoubleDomainMatch match = onCn.get(0);
                appendLine(msg, "Уникальное совпадение суммы и одного СФ на договоре Excel");
                appendLine(msg, "→ Связать с inv=" + match.invKey()
                        + " (уверенность: " + confidenceRu("medium") + ")");
                return finish(msg, "medium", "link", match.invKey(), match.cnKey());
            }
            appendLine(msg, "Сумма совпадает с исполнителем Excel — сверьте первичку вручную");
        }

        appendSumHints(msg, hints);
        if ("unknown".equals(sfByNum.status()) || "na".equals(sfByNum.status())) {
            appendLine(msg, "Недостаточно данных для автоматической рекомендации");
        } else {
            appendLine(msg, "→ Ручной разбор: выберите СФ в списке или создайте новый");
        }
        appendLine(msg, "Примечание: советник не заменяет первичку");
        return finish(msg, "none", "manual", null, row.ciusCnKey());
    }

    /**
     * Уникальная сумма (old/new) с исполнителем Excel на договоре очереди и известным {@code invKey}.
     * <p>
     * Кейс UAT C.10 / СГМ14-234: номер в Excel — заглушка «Б/С», а тот же долг уже в DbtValue
     * на договоре Excel под другим номером СФ (предыдущая выгрузка). Без этой проверки советник
     * рекомендовал create и плодил дубль.
     *
     * @param msg накопленный текст
     * @param hints подсказки
     * @param row строка очереди
     * @return link-совет или empty
     */
    private static Optional<SudzSfDoubleAdvice> tryLinkByUniqueSumOnExcelCn(
            StringBuilder msg,
            SudzSfDoubleHints hints,
            SudzCnInvUplSfDouble row
    ) {
        Optional<SudzSfDoubleHintItem> sumItem = uniqueSumHintForRow(hints, row);
        if (sumItem.isEmpty()) {
            return Optional.empty();
        }
        SudzSfDoubleHintItem item = sumItem.get();
        Integer invKey = item.invKey();
        if (invKey == null || invKey <= 0) {
            return Optional.empty();
        }
        Integer targetCn = item.cnKey() != null ? item.cnKey() : row.ciusCnKey();
        appendLine(msg, "Уникальная сумма с исполнителем Excel на договоре очереди (sum_same_cn)");
        appendLine(msg, "Номер Excel «" + nullToDash(row.ciusInvNum())
                + "» может отличаться от номера существующего СФ (заглушка / перенумерация между выгрузками)");
        if ("sumsNew".equals(item.zone())) {
            appendLine(msg, "Якорь суммы: dvKey=" + item.pickValue() + " → inv=" + invKey);
        } else if ("sumsOld".equals(item.zone())) {
            appendLine(msg, "Якорь суммы: cidKey=" + item.pickValue() + " → inv=" + invKey);
        }
        appendLine(msg, "→ Связать с inv=" + invKey
                + " · cn=" + (targetCn != null ? targetCn : "—")
                + " (уверенность: " + confidenceRu("high") + ")");
        appendLine(msg, "Примечание: советник не заменяет первичку");
        return Optional.of(finish(msg, "high", "link", invKey, targetCn));
    }

    private static String confidenceForVariantLink(SudzSfDoubleHints hints, SudzCnInvUplSfDouble row) {
        return hasUniqueSumEvidence(hints, row) ? "high" : "medium";
    }

    private static boolean hasUniqueSumEvidence(SudzSfDoubleHints hints, SudzCnInvUplSfDouble row) {
        return uniqueSumHintForRow(hints, row).isPresent();
    }

    /**
     * Уникальное совпадение суммы (old или new) на договоре очереди или его варианте номера.
     */
    private static Optional<SudzSfDoubleHintItem> uniqueSumHintForRow(
            SudzSfDoubleHints hints,
            SudzCnInvUplSfDouble row
    ) {
        for (SudzSfDoubleHintSection sec : List.of(hints.sumsOld(), hints.sumsNew())) {
            if ("yes".equals(sec.status()) && sec.totalCount() == 1 && !sec.items().isEmpty()) {
                SudzSfDoubleHintItem item = sec.items().get(0);
                if (Objects.equals(item.cnKey(), row.ciusCnKey())) {
                    return Optional.of(item);
                }
                if (cnNumbersAreVariants(row.ciusCnNum(), item.cnNum())) {
                    return Optional.of(item);
                }
            }
        }
        return Optional.empty();
    }

    private static SudzSfDoubleAdvice linkAdvice(
            StringBuilder msg,
            String confidence,
            SudzSfDoubleHintItem item,
            Integer targetCnKey
    ) {
        Integer invKey = item.invKey();
        appendLine(msg, "→ Связать с inv=" + (invKey != null ? invKey : item.pickValue())
                + " · cn=" + (targetCnKey != null ? targetCnKey : item.cnKey())
                + " (уверенность: " + confidenceRu(confidence) + ")");
        appendLine(msg, "Примечание: советник не заменяет первичку");
        return finish(msg, confidence, "link", invKey, targetCnKey != null ? targetCnKey : item.cnKey());
    }

    /**
     * Номера договоров считаются вариантами одного (711113884 vs 711113884/ЯРЭС).
     *
     * @param queueCnNum номер из очереди / Excel
     * @param domainCnNum номер у найденного СФ
     * @return true если один — базовый, другой — с суффиксом через «/»
     */
    static boolean cnNumbersAreVariants(String queueCnNum, String domainCnNum) {
        if (queueCnNum == null || domainCnNum == null) {
            return false;
        }
        String q = normalizeCnNum(queueCnNum);
        String d = normalizeCnNum(domainCnNum);
        if (q.isEmpty() || d.isEmpty()) {
            return false;
        }
        if (q.equals(d)) {
            return true;
        }
        return d.startsWith(q + "/") || q.startsWith(d + "/");
    }

    private static String normalizeCnNum(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().replaceAll("\\s+", "").toUpperCase(Locale.ROOT);
    }

    private static void appendRecommendCreate(StringBuilder msg, String confidence) {
        appendLine(msg, "→ Создать СФ по Excel (уверенность: " + confidenceRu(confidence) + ")");
    }

    /**
     * Рекомендация добавить второй номер договора и убрать дубль cn из воронки.
     */
    private static void appendRecommendAliasCnNum(
            StringBuilder msg,
            SudzCnInvUplSfDouble row,
            SudzSfDoubleHintItem item,
            String confidence
    ) {
        appendLine(msg, "→ Добавить номер «" + nullToDash(row.ciusCnNum()) + "» к cn="
                + item.cnKey() + " «" + nullToDash(item.cnNum()) + "» (экран «Договоры» → cnNum)");
        appendLine(msg, "→ Удалить дубль cn=" + row.ciusCnKey() + " «" + nullToDash(row.ciusCnNum())
                + "», если создан только воронкой (без истории долгов)");
        appendLine(msg, "→ Убрать ошибочную связь cnInv inv=" + item.invKey() + " ↔ cn="
                + row.ciusCnKey() + ", если уже привязали к дублю");
        appendLine(msg, "→ Закрыть очередь: inv=" + item.invKey() + " · cn=" + item.cnKey()
                + " (уверенность: " + confidenceRu(confidence) + ")");
    }

    private static void appendSumHints(StringBuilder msg, SudzSfDoubleHints hints) {
        appendLine(msg, "Суммы (old): " + hints.sumsOld().message());
        appendLine(msg, "Суммы (new): " + hints.sumsNew().message());
    }

    private static SudzSfDoubleAdvice finish(
            StringBuilder msg,
            String confidence,
            String action,
            Integer recommendInvKey,
            Integer recommendCnKey
    ) {
        return new SudzSfDoubleAdvice(
                msg.toString(),
                confidence,
                action,
                recommendInvKey,
                recommendCnKey);
    }

    private static String nullToDash(String value) {
        return value == null || value.isBlank() ? "—" : value;
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
}
