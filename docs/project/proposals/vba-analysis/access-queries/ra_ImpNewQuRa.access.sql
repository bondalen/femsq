/*
 * Объект MS Access: сохранённый запрос ra_ImpNewQuRa
 *
 * Назначение: сравнение строк промежуточного импорта (ra_ImpNew / ra_ImpNewQu)
 * с доменными ags_ra и суммами ags_raSmLt; вычисление флагов совпадения (rs*).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Связь с Java: эталон для reconcile type=5 (staging ra_stg_ra → ags_ra).
 * Поведение apply по VBA: partial apply (строка-за-строкой) — некондиционные строки
 * логируются и пропускаются, но не блокируют применение кондиционных строк.
 * Политика сумм (подтверждена данными БД): 1:N история в ags.ra_summ допустима;
 * новая запись суммы добавляется только при отличии от предыдущей версии, при равенстве пропускается.
 * Актуальная версия суммы определяется через ags.raSmLt (MAX(ras_date) по ras_ra).
 *
 * lastUpdated: 2026-03-24
 */

SELECT
    w.rainRow,
    w.rainRaNum,
    w.rainSign,
    d.ra_type,
    IIf(
        IIf(IsNull([w.rainSign]), "", [w.rainSign]) = IIf(IsNull([ra_type]), "", [ra_type]),
        True,
        False
    ) AS rsSign,
    w.periodKey,
    w.cstapKey,
    w.ogKey,
    w.ra_key,
    s.ras_total AS dbTtl,
    i.rainTtl AS exTtl,
    IIf(
        IIf(IsNull([s]![ras_total]), 0, [s]![ras_total]) = IIf(IsNull([i]![rainTtl]), 0, [i]![rainTtl]),
        True,
        False
    ) AS rsTtl,
    s.ras_work AS dbWork,
    i.rainWork AS exWork,
    IIf(
        IIf(IsNull([s]![ras_work]), 0, [s]![ras_work]) = IIf(IsNull([i]![rainWork]), 0, [i]![rainWork]),
        True,
        False
    ) AS rsWork,
    s.ras_equip AS dbEquip,
    i.rainEquip AS exEquip,
    IIf(
        IIf(IsNull([s]![ras_equip]), 0, [s]![ras_equip]) = IIf(IsNull([i]![rainEquip]), 0, [i]![rainEquip]),
        True,
        False
    ) AS rsEquip,
    s.ras_others AS dbOthers,
    i.rainOthers AS exOthers,
    IIf(
        IIf(IsNull([s]![ras_others]), 0, [s]![ras_others]) = IIf(IsNull([i]![rainOthers]), 0, [i]![rainOthers]),
        True,
        False
    ) AS rsOthers,
    s.ras_key,
    [rsTtl] And [rsWork] And [rsEquip] And [rsOthers] AS rsSum,
    d.ra_org_sender AS dbSender,
    w.ogKey AS exSender,
    IIf([ra_org_sender] = [ogKey], True, False) AS rsSender,
    d.ra_date AS dbDate,
    i.rainRaDate AS exDate,
    IIf(
        IIf(IsNull([ra_date]), 0, [ra_date]) = IIf(IsNull([i].[rainRaDate]), 0, [i].[rainRaDate]),
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
        And Not IsNull([w].[ra_key]) AS rs
FROM (
    (
        (
            SELECT
                z.rainRow,
                z.rainRaNum,
                z.periodKey,
                z.cstapKey,
                z.ogKey,
                z.rainSign,
                ags_ra.ra_key
            FROM
                (
                    SELECT *
                    FROM ra_ImpNewQu
                    WHERE (((rainSign) <> "ОА изм"))
                ) AS z
                LEFT JOIN ags_ra
                    ON (z.ogKey = ags_ra.ra_org_sender)
                    AND (z.cstapKey = ags_ra.ra_cac)
                    AND (z.periodKey = ags_ra.ra_period)
                    AND (z.rainRaNum = ags_ra.ra_num)
            ORDER BY z.rainRow
        ) AS w
        LEFT JOIN ra_ImpNew AS i
            ON w.rainRow = i.rainRow
    )
    LEFT JOIN ags_ra AS d
        ON w.ra_key = d.ra_key
)
LEFT JOIN ags_raSmLt AS s
    ON d.ra_key = s.ras_ra;
