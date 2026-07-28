package com.femsq.database.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Отчёт агента ({@code ags.ra}).
 *
 * @param raKey          PRIMARY KEY (identity)
 * @param raNum          номер
 * @param raDate         дата
 * @param raCac          САК ({@code cstAgPn.cstapKey})
 * @param raType         тип
 * @param raWorkType     вид работ
 * @param raPeriod       период ({@code ra_period.key})
 * @param raArrived      поступил (номер)
 * @param raArrivedDate  дата поступления
 * @param raReturned     возвращён
 * @param raReturnedDate дата возврата
 * @param raSent         направлен
 * @param raSentDate     дата направления
 * @param raNoteT        примечание (техническое)
 * @param raCreated      дата создания записи
 * @param raOrgSender    отправитель ({@code og.ogKey})
 * @param raNote         примечание
 */
public record RaReport(
        Integer raKey,
        String raNum,
        LocalDate raDate,
        Integer raCac,
        String raType,
        String raWorkType,
        Integer raPeriod,
        String raArrived,
        LocalDate raArrivedDate,
        String raReturned,
        LocalDate raReturnedDate,
        String raSent,
        LocalDate raSentDate,
        String raNoteT,
        LocalDateTime raCreated,
        Integer raOrgSender,
        String raNote
) {

    public RaReport {
        Objects.requireNonNull(raNum, "raNum");
        Objects.requireNonNull(raCac, "raCac");
        Objects.requireNonNull(raType, "raType");
        Objects.requireNonNull(raPeriod, "raPeriod");
        Objects.requireNonNull(raOrgSender, "raOrgSender");
    }
}
