package com.femsq.database.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Версия сумм отчёта ({@code ags.ra_summ}).
 *
 * @param rasKey    PRIMARY KEY (identity)
 * @param rasRa     ключ отчёта
 * @param rasTotal  всего
 * @param rasWork   СМР
 * @param rasEquip  оборудование
 * @param rasOthers прочее
 * @param rasDate   дата версии
 */
public record RaSumm(
        Integer rasKey,
        Integer rasRa,
        BigDecimal rasTotal,
        BigDecimal rasWork,
        BigDecimal rasEquip,
        BigDecimal rasOthers,
        LocalDateTime rasDate
) {

    public RaSumm {
        Objects.requireNonNull(rasRa, "rasRa");
    }
}
