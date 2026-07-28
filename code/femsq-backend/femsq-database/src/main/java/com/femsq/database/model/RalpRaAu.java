package com.femsq.database.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Objects;

/**
 * Строка рассмотрения отчёта аренды ({@code ags.ralpRaAu}, Access {@code Au_t}).
 *
 * <p>Поля {@code ralpraTestStartDate}/{@code ralpra_fdKey} в модели не участвуют в UI;
 * UPDATE их не затирает.
 *
 * @param ralpraKey          PRIMARY KEY (identity)
 * @param ralpraRa           FK → {@code ralpRa.ralprKey}
 * @param ralpraCostAndVat   сумма с НДС
 * @param ralpraArrived      поступил (текст)
 * @param ralpraArrivedDate  дата поступления
 * @param ralpraReturned     возвращён
 * @param ralpraReturnedDate дата возврата
 * @param ralpraSent         направлен
 * @param ralpraSentDate     дата направления
 * @param ralpraNote         примечание
 * @param ralpraStatus       статус (0..3)
 */
public record RalpRaAu(
        Integer ralpraKey,
        Integer ralpraRa,
        BigDecimal ralpraCostAndVat,
        String ralpraArrived,
        LocalDate ralpraArrivedDate,
        String ralpraReturned,
        LocalDate ralpraReturnedDate,
        String ralpraSent,
        LocalDate ralpraSentDate,
        String ralpraNote,
        int ralpraStatus
) {

    public RalpRaAu {
        Objects.requireNonNull(ralpraRa, "ralpraRa");
    }
}
