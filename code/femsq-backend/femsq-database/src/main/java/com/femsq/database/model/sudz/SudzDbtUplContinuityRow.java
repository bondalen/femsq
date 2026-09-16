package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Строка dry-лога непрерывности слотов ({@code dbtValueLoad}, S77.9 M3).
 *
 * @param cidutKey ключ строки Tbl
 * @param iKey ключ {@code ags.inv}
 * @param cnInv номер СФ из Excel
 * @param cnName номер договора из Excel
 * @param debt сумма Excel
 * @param slotCount число {@code invDbt} на {@code iKey}
 * @param chosenSlotKey слот для Value или {@code null} при неоднозначности
 * @param decision {@code pick_base} / {@code pick_last} / {@code ambiguous} / {@code single}
 * @param candidates краткий перечень кандидатов (слот/ранг)
 */
public record SudzDbtUplContinuityRow(
        int cidutKey,
        int iKey,
        String cnInv,
        String cnName,
        BigDecimal debt,
        int slotCount,
        Integer chosenSlotKey,
        String decision,
        String candidates
) {
}
