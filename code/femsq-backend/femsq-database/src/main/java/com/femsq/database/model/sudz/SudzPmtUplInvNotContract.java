package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Договор с новыми СФ (шаг {@code cipuCn_CtptCnOneInvNotLoad} / лог Access).
 *
 * @param cnKey ключ договора
 * @param cnName нормализованный номер
 * @param buirg БУиРГ исполнителя
 * @param name наименование контрагента
 * @param invCount число СФ в буфере
 * @param invoices номера СФ
 */
public record SudzPmtUplInvNotContract(
        int cnKey,
        String cnName,
        Integer buirg,
        String name,
        int invCount,
        List<SudzDbtUplCnCtptExistInvItem> invoices
) {
    /**
     * Компактный конструктор: неизменяемый список.
     */
    public SudzPmtUplInvNotContract {
        invoices = List.copyOf(invoices);
    }
}
