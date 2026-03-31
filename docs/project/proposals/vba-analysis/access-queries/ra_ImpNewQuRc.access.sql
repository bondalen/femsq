/*
 * Объект MS Access: сохранённый запрос ra_ImpNewQuRc
 *
 * Назначение: сравнение строк изменений отчёта (ветка «ОА изм» из ra_ImpNewQu)
 * с ags_ra_change и суммами ags_ra_chSmLt; вычисление флагов совпадения (rs*).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Связь с Java: эталон для reconcile type=5 (изменения → ags_ra_change / суммы).
 * Read-model 1.3.1: AllAgentsReconcileService (RcStagingLineParser + rc* counters в adt_results).
 * Поведение apply по VBA: partial apply (строка-за-строкой) — некондиционные строки
 * логируются и пропускаются, но не блокируют применение кондиционных строк.
 * Политика сумм изменений (подтверждена данными БД): 1:N история в ags.ra_change_summ допустима;
 * новая запись суммы добавляется только при отличии от предыдущей версии, при равенстве пропускается.
 * Актуальная версия суммы определяется через ags.ra_chSmLt (MAX(raсs_date) по raсs_raс).
 *
 * lastUpdated: 2026-03-24
 */

SELECT
    w.rainRow,
    w.rainRaNum,
    w.rainRaDate,
    w.rcPeriod,
    w.cstapKey,
    w.ogKey,
    w.rainSign,
    w.num,
    w.numRa,
    w.dateRa,
    w.raPeriod,
    w.ra_key,
    w.rac_key,
    s.raсs_total AS dbTtl,
    i.rainTtl AS exTtl,
    IIf(
        IIf(IsNull([s]![raсs_total]), 0, [s]![raсs_total]) = IIf(IsNull([i]![rainTtl]), 0, [i]![rainTtl]),
        True,
        False
    ) AS rsTtl,
    s.raсs_work AS dbWork,
    i.rainWork AS exWork,
    IIf(
        IIf(IsNull([s]![raсs_work]), 0, [s]![raсs_work]) = IIf(IsNull([i]![rainWork]), 0, [i]![rainWork]),
        True,
        False
    ) AS rsWork,
    s.raсs_equip AS dbEquip,
    i.rainEquip AS exEquip,
    IIf(
        IIf(IsNull([s]![raсs_equip]), 0, [s]![raсs_equip]) = IIf(IsNull([i]![rainEquip]), 0, [i]![rainEquip]),
        True,
        False
    ) AS rsEquip,
    s.raсs_others AS dbOthers,
    i.rainOthers AS exOthers,
    IIf(
        IIf(IsNull([s]![raсs_others]), 0, [s]![raсs_others]) = IIf(IsNull([i]![rainOthers]), 0, [i]![rainOthers]),
        True,
        False
    ) AS rsOthers,
    s.raсs_key,
    [rsTtl] And [rsWork] And [rsEquip] And [rsOthers] AS rsSum,
    d.ra_org_sender AS dbSender,
    w.ogKey AS exSender,
    IIf([ra_org_sender] = [ogKey], True, False) AS rsSender,
    d.raс_date AS dbDate,
    w.rainRaDate AS exDate,
    IIf(
        IIf(IsNull([raс_date]), 0, [raс_date]) = IIf(IsNull([w].[rainRaDate]), 0, [w].[rainRaDate]),
        True,
        False
    ) AS rsDate,
    d.ra_arrived AS dbArrv,
    i.rainArrivedNum AS exArrv,
    IIf(
        IIf(IsNull([ra_arrived]), "", [ra_arrived]) = IIf(IsNull([rainArrivedNum]), "", [rainArrivedNum]),
        True,
        False
    ) AS rsArrv,
    d.ra_arrived_date AS dbArrvDate,
    i.rainArrivedDate AS exArrvDate,
    IIf(
        IIf(IsNull([ra_arrived_date]), 0, [ra_arrived_date]) = IIf(IsNull([rainArrivedDate]), 0, [rainArrivedDate]),
        True,
        False
    ) AS rsArrvDate,
    d.ra_arrived_dateFact AS dbArrvDateFact,
    i.rainArrivedDateFact AS exArrvDateFact,
    IIf(
        IIf(IsNull([ra_arrived_dateFact]), 0, [ra_arrived_dateFact]) = IIf(IsNull([rainArrivedDateFact]), 0, [rainArrivedDateFact]),
        True,
        False
    ) AS rsArrvDateFact,
    d.ra_returned AS dbRetn,
    i.rainReturnedNum AS exRetn,
    IIf(
        IIf(IsNull([ra_returned]), "", [ra_returned]) = IIf(IsNull([rainReturnedNum]), "", [rainReturnedNum]),
        True,
        False
    ) AS rsRetn,
    d.ra_returned_date AS dbRetnDate,
    i.rainReturnedDate AS exRetnDate,
    IIf(
        IIf(IsNull([ra_returned_date]), 0, [ra_returned_date]) = IIf(IsNull([rainReturnedDate]), 0, [rainReturnedDate]),
        True,
        False
    ) AS rsRetnDate,
    d.ra_returnedReason AS dbRetnRsn,
    i.rainReturnedReason AS exRetnRsn,
    IIf(
        IIf(IsNull([ra_returnedReason]), "", [ra_returnedReason]) = IIf(IsNull([rainReturnedReason]), "", [rainReturnedReason]),
        True,
        False
    ) AS rsRetnRsn,
    d.ra_sent AS dbSent,
    i.rainSendNum AS exSent,
    IIf(
        IIf(IsNull([ra_sent]), "", [ra_sent]) = IIf(IsNull([rainSendNum]), "", [rainSendNum]),
        True,
        False
    ) AS rsSent,
    d.ra_sent_date AS dbSentDate,
    i.rainSendDate AS exSentDate,
    IIf(
        IIf(IsNull([ra_sent_date]), 0, [ra_sent_date]) = IIf(IsNull([rainSendDate]), 0, [rainSendDate]),
        True,
        False
    ) AS rsSentDate,
    [rsSum]
        And [rsSender]
        And [rsDate]
        And [rsArrv]
        And [rsArrvDate]
        And [rsArrvDateFact]
        And [rsRetn]
        And [rsRetnDate]
        And [rsRetnRsn]
        And [rsSent]
        And [rsSentDate]
        And Not IsNull([w].[rac_key]) AS rs
FROM (
    (
        (
            SELECT
                y.rainRow,
                y.rainRaNum,
                y.rainRaDate,
                y.rcPeriod,
                y.cstapKey,
                y.ogKey,
                y.rainSign,
                y.num,
                y.numRa,
                y.dateRa,
                y.raPeriod,
                y.ra_key,
                c.rac_key
            FROM
                (
                    SELECT
                        x.rainRow,
                        x.rainRaNum,
                        x.rainRaDate,
                        x.rcPeriod,
                        x.cstapKey,
                        x.ogKey,
                        x.rainSign,
                        x.num,
                        x.numRa,
                        x.dateRa,
                        x.raPeriod,
                        r.ra_key
                    FROM
                        (
                            SELECT
                                z.rainRow,
                                z.rainRaNum,
                                z.rainRaDate,
                                z.periodKey AS rcPeriod,
                                z.cstapKey,
                                z.ogKey,
                                z.rainSign,
                                z.num,
                                z.numRa,
                                z.dateRa,
                                p.key AS raPeriod
                            FROM
                                (
                                    SELECT
                                        i.rainRow,
                                        i.rainRaNum,
                                        i.rainRaDate,
                                        i.periodKey,
                                        i.cstapKey,
                                        i.ogKey,
                                        i.rainSign,
                                        RcStringNum([rainRaNum]) AS num,
                                        RcStringRaNum([rainRaNum]) AS numRa,
                                        IIf(
                                            IsNull(RcStringRaDate([rainRaNum])),
                                            Null,
                                            CDate(RcStringRaDate([rainRaNum]))
                                        ) AS dateRa,
                                        IIf(
                                            IsNull(RcStringRaDate([rainRaNum])),
                                            Null,
                                            CDate(PeriodDateOfDate(CDate(RcStringRaDate([rainRaNum]))))
                                        ) AS dateRaPeriod
                                    FROM
                                        ra_ImpNewQu AS i
                                    WHERE
                                        (((i.rainSign) = "ОА изм"))
                                ) AS z
                                LEFT JOIN ags_ra_period AS p
                                    ON z.dateRaPeriod = p.rap_datePeriod
                        ) AS x
                        LEFT JOIN ags_ra AS r
                            ON (x.raPeriod = r.ra_period)
                            AND (x.numRa = r.ra_num)
                ) AS y
                LEFT JOIN ags_ra_change AS c
                    ON (y.rcPeriod = c.ra_period)
                    AND (y.ra_key = c.raс_ra)
                    AND (y.num = c.raс_num)
        ) AS w
        LEFT JOIN ags_ra_change AS d
            ON w.rac_key = d.rac_key
    )
    LEFT JOIN ra_ImpNew AS i
        ON w.rainRow = i.rainRow
)
LEFT JOIN ags_ra_chSmLt AS s
    ON d.rac_key = s.raсs_raс;
