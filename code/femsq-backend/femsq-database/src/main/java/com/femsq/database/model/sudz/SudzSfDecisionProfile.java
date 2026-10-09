package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * Профиль кандидата СФ для decision-TreeList (КСДСФ pmt).
 *
 * @param invKey {@code ags.inv.iKey}
 * @param invNum номер СФ ({@code inv.iNum})
 * @param invEntered дата/время создания
 * @param preferredCiKey cnInv (если однозначен)
 * @param preferredCnKey договор preferred cnInv
 * @param contract текст договора
 * @param cntrPrtNum БУиРГ исполнителя preferred cn; может быть null
 * @param cntrPrtName имя исполнителя preferred cn; может быть null
 * @param note note preferred cnInv
 * @param pmCount число платежей
 * @param blnsSum Σ сальдо всех pm
 * @param currentUplBlnsSum Σ сальдо текущего пакета (0 если upl не задан)
 * @param currentUplKey пакет экрана
 * @param compare шапка сверки
 * @param invNums алиасы {@code ags.invNum}
 * @param cnInvs договоры (cnInv) и стороны
 * @param payments платежи
 * @param docSums сводка документов
 * @param cias счета ГК
 * @param debts задолженности (stub)
 */
public record SudzSfDecisionProfile(
        int invKey,
        String invNum,
        OffsetDateTime invEntered,
        Integer preferredCiKey,
        Integer preferredCnKey,
        String contract,
        Integer cntrPrtNum,
        String cntrPrtName,
        String note,
        int pmCount,
        BigDecimal blnsSum,
        BigDecimal currentUplBlnsSum,
        Integer currentUplKey,
        SudzSfDecisionCompare compare,
        List<SudzSfDecisionInvNum> invNums,
        List<SudzSfDecisionCnInv> cnInvs,
        List<SudzSfDecisionPayment> payments,
        List<SudzSfDecisionDocSum> docSums,
        List<SudzSfDecisionCias> cias,
        List<SudzSfDecisionDebt> debts
) {
}
