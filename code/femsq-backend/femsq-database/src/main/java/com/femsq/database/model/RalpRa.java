package com.femsq.database.model;

import java.time.LocalDate;
import java.util.Objects;

/**
 * Заголовок отчёта аренды земли ({@code ags.ralpRa}).
 *
 * <p>{@code ralprY}/{@code ralprM} — вычисляемые колонки, в INSERT/UPDATE не участвуют.
 *
 * @param ralprKey       PRIMARY KEY (identity)
 * @param ralprNum       номер
 * @param ralprDate      дата
 * @param ralprCstAgPn   САК ({@code cstAgPn.cstapKey})
 * @param ralprOgSender  отправитель (канон {@code og.ogKey}; Stage 2 с 0054.7 пишет {@code onfOg})
 * @param ogNm           наименование отправителя (чтение: сначала {@code og}, иначе legacy {@code ogNmF})
 * @param ralprY         год (read-only, computed)
 * @param ralprM         месяц (read-only, computed)
 */
public record RalpRa(
        Integer ralprKey,
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender,
        String ogNm,
        Integer ralprY,
        Integer ralprM
) {

    public RalpRa {
        Objects.requireNonNull(ralprNum, "ralprNum");
        Objects.requireNonNull(ralprDate, "ralprDate");
        Objects.requireNonNull(ralprCstAgPn, "ralprCstAgPn");
        Objects.requireNonNull(ralprOgSender, "ralprOgSender");
    }
}
