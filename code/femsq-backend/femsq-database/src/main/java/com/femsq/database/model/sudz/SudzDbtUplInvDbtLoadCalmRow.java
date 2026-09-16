package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Строка снимка шага {@code invDbtLoad} для dry-лога (Calm Create / F1 / тихая дыра).
 *
 * @param cidutKey ключ строки Tbl (или {@code null}, если только iKey)
 * @param cnName номер договора из Excel
 * @param cnInv номер СФ из Excel
 * @param debt сумма долга из Excel
 * @param iKey ключ {@code ags.inv}
 * @param idvvKey ключ {@code invDbtVar}
 * @param kind метка: {@code calm_create}, {@code calm_f1}, {@code silent_hole}
 */
public record SudzDbtUplInvDbtLoadCalmRow(
        Integer cidutKey,
        String cnName,
        String cnInv,
        BigDecimal debt,
        int iKey,
        Integer idvvKey,
        String kind
) {
}
