package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Договор с новыми СФ (шаг {@code CnCtptExistInvNotLoad} / лог Access).
 *
 * @param cnKey ключ договора
 * @param cnName нормализованный номер ({@code cidutCnNameNull})
 * @param invCount число СФ в буфере
 * @param invoices номера СФ (порядок для склейки)
 */
public record SudzDbtUplCnCtptExistInvContract(
        int cnKey,
        String cnName,
        int invCount,
        List<SudzDbtUplCnCtptExistInvItem> invoices
) {
    /**
     * Компактный конструктор: неизменяемый список.
     */
    public SudzDbtUplCnCtptExistInvContract {
        invoices = List.copyOf(invoices);
    }
}
