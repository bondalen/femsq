/*
 * Объект MS Access: сохраненный запрос ralpRaAuTestQuAu
 *
 * Назначение: сверка фактов рассмотрения отчетов аренды земли (`ags_ralpRaAu`)
 * с временной таблицей `ralpRaAuTest` по ключу рассмотрения
 * (`ralpraKey` = `ralprtRaAuKey`) в разрезе ревизии (`ra_a`).
 *
 * Где используется: `RAAudit_ralp` в `Form_ra_a.cls` (выборка "лишних рассмотрений в БД"):
 * `SELECT ... FROM ralpRaAuTestQuAu WHERE adt_key = ... AND ralprtRaAuKey Is Null`.
 *
 * Зависимости: `ra_a`, `ra_dir`, `ra_dir_s_p`, `ags_ra_period`, `ags_yyyy`,
 * `ags_ralpRa`, `ags_ralpRaAu`, `ralpRaAuTest`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE).
 *
 * Источник текста: ralpRaAuTestQuAu.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

SELECT
    x.adt_key,
    x.adt_name,
    x.[First-yyyy],
    ags_ralpRa.ralprKey,
    ags_ralpRa.ralprNum,
    ags_ralpRa.ralprDate,
    ags_ralpRa.ralprCstAgPn,
    ags_ralpRa.ralprOgSender,
    ags_ralpRaAu.ralpraKey,
    ralpRaAuTest.ralprtRaAuKey,
    ralpRaAuTest.ralprtKeySQL,
    ralpRaAuTest.ralprtKey,
    ralpRaAuTest.ralprtNum,
    ralpRaAuTest.ralprtDate,
    ralpRaAuTest.ralprtCstAgPn,
    ralpRaAuTest.ralprtOgSender,
    ralpRaAuTest.ralprtNote,
    ags_ralpRaAu.ralpraArrived
FROM (
    (
        (
            SELECT
                ra_a.adt_key,
                ra_a.adt_name,
                First(ags_yyyy.yyyy) AS [First-yyyy]
            FROM ags_yyyy
                INNER JOIN (
                    (
                        (
                            ra_dir
                            INNER JOIN ra_a
                                ON ra_dir.key = ra_a.adt_dir
                        )
                        INNER JOIN ra_dir_s_p
                            ON ra_dir.key = ra_dir_s_p.rdsp_dir
                    )
                    INNER JOIN ags_ra_period
                        ON ra_dir_s_p.rdsp_period = ags_ra_period.key
                )
                    ON ags_yyyy.yKey = ags_ra_period.y
            GROUP BY
                ra_a.adt_key,
                ra_a.adt_name
        ) AS x
        INNER JOIN ags_ralpRa
            ON x.[First-yyyy] = ags_ralpRa.ralprY
    )
    INNER JOIN ags_ralpRaAu
        ON ags_ralpRa.ralprKey = ags_ralpRaAu.ralpraRa
)
    LEFT JOIN ralpRaAuTest
        ON ags_ralpRaAu.ralpraKey = ralpRaAuTest.ralprtRaAuKey;
