/*
 * Объект MS Access: сохранённый запрос ralpRaAuTestQuRa
 *
 * Назначение: сверка отчётов аренды земли из БД (`ags_ralpRa`) с временной таблицей
 * `ralpRaAuTest` по ключу отчёта (`ralprKey` = `ralprtKeySQL`) в разрезе ревизии (`ra_a`).
 * Поле `First-yyyy` вычисляется как первый год периода ревизии и используется для
 * JOIN к `ags_ralpRa.ralprY`.
 *
 * Где используется: `RAAudit_ralp` в `Form_ra_a.cls` (выборка "лишних отчётов в БД"):
 * `SELECT ... FROM ralpRaAuTestQuRa WHERE adt_key = ... AND ralprtKeySQL Is Null`.
 *
 * Зависимости: `ra_a`, `ra_dir`, `ra_dir_s_p`, `ags_ra_period`, `ags_yyyy`,
 * `ags_ralpRa`, `ralpRaAuTest`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE).
 *
 * Источник текста: ralpRaAuTestQuRa.txt (снято из Access).
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
    ralpRaAuTest.ralprtKeySQL
FROM (
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
    LEFT JOIN ralpRaAuTest
        ON ags_ralpRa.ralprKey = ralpRaAuTest.ralprtKeySQL
GROUP BY
    x.adt_key,
    x.adt_name,
    x.[First-yyyy],
    ags_ralpRa.ralprKey,
    ags_ralpRa.ralprNum,
    ags_ralpRa.ralprDate,
    ags_ralpRa.ralprCstAgPn,
    ags_ralpRa.ralprOgSender,
    ralpRaAuTest.ralprtKeySQL;
