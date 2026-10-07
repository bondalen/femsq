package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Одна уже сохранённая привязка платёжного документа: платёж пакета и счёт-фактура.
 *
 * @param docKey ключ {@code ags.cn_inv_doc}
 * @param docKod код «№ докум.»
 * @param docDate дата документа
 * @param docSum сумма документа
 * @param pmKey ключ {@code ags.cn_inv_pm}
 * @param uplKey пакет платежей
 * @param uplName имя пакета
 * @param uplDate дата пакета
 * @param blns сальдо платежа
 * @param dbtBlns дебет
 * @param cdtBlns кредит
 * @param invKey {@code ags.inv.iKey}
 * @param invNum номер счёта-фактуры
 * @param cnKey договор
 * @param cnNumber номер договора
 * @param cnName имя договора
 * @param counterparty БУиРГ стороны договора
 * @param accountNum счёт главной книги
 * @param cstKey {@code cstAgPn.cstapKey} или null
 * @param cstCode полный код САК ({@code cstapIpgPnN})
 * @param cstName имя стройки / пункта
 */
public record SudzPmDocLink(
        int docKey,
        String docKod,
        LocalDate docDate,
        BigDecimal docSum,
        int pmKey,
        int uplKey,
        String uplName,
        LocalDate uplDate,
        BigDecimal blns,
        BigDecimal dbtBlns,
        BigDecimal cdtBlns,
        Integer invKey,
        String invNum,
        Integer cnKey,
        String cnNumber,
        String cnName,
        String counterparty,
        String accountNum,
        Integer cstKey,
        String cstCode,
        String cstName
) {
}
