package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzPmDocForest;
import com.femsq.database.model.sudz.SudzPmDocLink;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * Строка советника по истории платёжного документа. Действие советника не выбирает.
 */
final class PmDocHistoryNote {

    private PmDocHistoryNote() {
    }

    /**
     * Текст для панели «Сообщения». Пустая строка, если сказать нечего.
     *
     * @param row очередь
     * @param excel карточка Excel, может быть null
     * @param domain совпадения по номеру файла
     * @param forest лес документов этой строки
     * @return строка или пусто
     */
    static String text(
            SudzCnInvUplSfDouble row,
            SudzSfDoubleExcelCandidate excel,
            List<SudzSfDoubleDomainMatch> domain,
            SudzPmDocForest forest
    ) {
        if (row.ciusCiput() == null || forest == null) {
            return "";
        }
        int fileCodes = forest.fileCodes();
        int matched = forest.matchedDocs();
        if (fileCodes == 0) {
            return "Документы: в строке нет кода «№ докум.».";
        }
        Integer current = forest.currentUplKey();
        List<SudzPmDocLink> prior = forest.links().stream()
                .filter(link -> current == null || link.uplKey() != current)
                .toList();
        if (prior.isEmpty()) {
            return "Документы: кодов в файле " + fileCodes
                    + ", с платежами в базе " + matched
                    + ". Прежних пакетов по этим кодам нет.";
        }
        Set<Integer> latestInvs = new LinkedHashSet<>();
        boolean splitInside = false;
        for (Integer docKey : prior.stream().map(SudzPmDocLink::docKey).distinct().toList()) {
            int maxUpl = prior.stream()
                    .filter(link -> link.docKey() == docKey)
                    .mapToInt(SudzPmDocLink::uplKey)
                    .max()
                    .orElse(0);
            Set<Integer> atLatest = new LinkedHashSet<>();
            for (SudzPmDocLink link : prior) {
                if (link.docKey() == docKey && link.uplKey() == maxUpl && link.invKey() != null) {
                    atLatest.add(link.invKey());
                }
            }
            if (atLatest.size() != 1) {
                splitInside = true;
            }
            latestInvs.addAll(atLatest);
        }
        if (splitInside || latestInvs.size() != 1) {
            return "Документы: прежние платежи расходятся по разным счетам-фактурам. Автовыбор не делается.";
        }
        int invKey = latestInvs.iterator().next();
        SudzPmDocLink sample = prior.stream()
                .filter(link -> link.invKey() != null && link.invKey() == invKey)
                .reduce((first, second) -> second.uplKey() >= first.uplKey() ? second : first)
                .orElseThrow();
        String fileNum = row.ciusInvNum() == null ? "" : row.ciusInvNum().trim();
        String priorNum = sample.invNum() == null ? "" : sample.invNum().trim();
        boolean sameNum = !fileNum.isEmpty() && fileNum.equals(priorNum);
        boolean sameCn = row.ciusCnKey() != null && Objects.equals(row.ciusCnKey(), sample.cnKey());
        boolean sameAcc = excel == null || excel.cidutAccntNum() == null
                || String.valueOf(excel.cidutAccntNum()).equals(sample.accountNum());
        long onCn = domain == null ? 0 : domain.stream()
                .filter(match -> match.invKey() == invKey && Objects.equals(match.cnKey(), sample.cnKey()))
                .count();
        if (sameNum && sameCn && sameAcc && onCn == 1) {
            return "Документы: код подтверждает СФ «" + priorNum + "» inv=" + invKey
                    + ", договор cn=" + sample.cnKey()
                    + ", счёт " + nullDash(sample.accountNum())
                    + " (пакет " + nullDash(sample.uplName()) + ").";
        }
        if (!sameNum) {
            return "Документы: в пакете " + nullDash(sample.uplName())
                    + " этот код был на СФ «" + nullDash(sample.invNum()) + "» inv=" + invKey
                    + ", в файле сейчас «" + (fileNum.isEmpty() ? "—" : fileNum) + "». Автовыбор не делается.";
        }
        return "Документы: код указывает на inv=" + invKey + " «" + nullDash(sample.invNum())
                + "», но договор, счёт или число кандидатов не сходятся. Автовыбор не делается.";
    }

    private static String nullDash(String value) {
        return value == null || value.isBlank() ? "—" : value;
    }
}
