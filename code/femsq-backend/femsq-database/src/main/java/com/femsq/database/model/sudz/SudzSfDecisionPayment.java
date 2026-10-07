package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Платёж профиля кандидата СФ (decision-TreeList).
 *
 * @param pmKey ключ {@code cn_inv_pm}
 * @param uplKey пакет
 * @param uplName имя пакета
 * @param uplDate дата пакета
 * @param docKey ключ документа (может быть null)
 * @param docKod «№ докум.»
 * @param docDate дата документа
 * @param dbt дебет
 * @param cdt кредит
 * @param blns сальдо
 * @param accountNum счёт ГК
 * @param ciKey {@code cnInv.ciKey}
 * @param ciasKey {@code cnInvAccntSmpl.ciasKey}
 * @param cnKey договор
 * @param contract номер/имя договора
 * @param legacyPmInv {@code cn_inv_pm.cn_inv_key}
 * @param cnInvKey {@code cn_inv_pm.cnInvKey}
 * @param hlCurrentUpl пакет = текущий upl экрана
 * @param hlOrphanLink оба legacy-ключа пусты (типичный InsPm)
 * @param hlContractDiff договор строки ≠ Excel
 * @param cstKey {@code cstAgPn.cstapKey} или null
 * @param cstCode полный код САК ({@code cstapIpgPnN})
 * @param cstName имя стройки / пункта
 * @param hlCstDiff код pm ≠ Excel CAC (ни полный, ни хвост)
 * @param hlCstSuffix полный код ≠ Excel, но совпал хвост из 6 символов
 */
public record SudzSfDecisionPayment(
        int pmKey,
        int uplKey,
        String uplName,
        LocalDate uplDate,
        Integer docKey,
        String docKod,
        LocalDate docDate,
        BigDecimal dbt,
        BigDecimal cdt,
        BigDecimal blns,
        String accountNum,
        int ciKey,
        Integer ciasKey,
        Integer cnKey,
        String contract,
        Integer legacyPmInv,
        Integer cnInvKey,
        boolean hlCurrentUpl,
        boolean hlOrphanLink,
        boolean hlContractDiff,
        Integer cstKey,
        String cstCode,
        String cstName,
        boolean hlCstDiff,
        boolean hlCstSuffix
) {
}
