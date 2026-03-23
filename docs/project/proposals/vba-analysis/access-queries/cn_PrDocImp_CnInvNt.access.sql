/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvNt
 *
 * Назначение: по строкам `cn_PrDocImp` с непустым `cn_key` строится агрегат по паре
 * (договор / СФ / дата в Null-safe полях). LEFT JOIN к серверным `ags_cnInv` / `ags_inv` /
 * `ags_invNum` (`y`) по `cn_key = ciCn`, номеру и дате СФ. Внутренний GROUP BY по `y.ciKey`.
 * Внешний уровень: LEFT JOIN `ags_invNum` по `CnInvNum = inNum` (поле `inNum` в дампе),
 * `Count(ags_invNum.inKey) AS inKeyCount`, итоговый отбор **`HAVING x.ciKey Is Null`**
 * (счёт-фактура в буфере **без** найденной связи `ciKey` на сервере).
 *
 * Зависимости: таблица `cn_PrDocImp`; `ags_cnInv`, `ags_inv`, `ags_invNum`.
 *
 * В коде: `Form_ra_a.cls` → `OpenRecordset("cn_PrDocImp_CnInvNt", …)`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvNt.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

SELECT
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey,
    Count(ags_invNum.inKey) AS inKeyCount
FROM (
    SELECT
        z.cn_key,
        z.CnNum,
        z.CnInvNum,
        z.CnInvDate,
        y.ciKey
    FROM (
        SELECT
            i.cn_key,
            i.cnpdCnNumNull AS CnNum,
            i.cnpdCnInvNumNull AS CnInvNum,
            i.cnpdCnInvDateNull AS CnInvDate
        FROM cn_PrDocImp AS i
        WHERE (((i.cn_key) Is Not Null))
        GROUP BY
            i.cn_key,
            i.cnpdCnNumNull,
            i.cnpdCnInvNumNull,
            i.cnpdCnInvDateNull
    ) AS z
        LEFT JOIN (
            SELECT
                ci.ciKey,
                ci.ciCn,
                i.iDateNull,
                n.inNumNull
            FROM (ags_cnInv AS ci
                INNER JOIN ags_inv AS i
                    ON ci.ciInv = i.iKey)
                INNER JOIN ags_invNum AS n
                    ON i.iKey = n.inInv
        ) AS y
            ON (z.cn_key = y.ciCn)
            AND (z.CnInvNum = y.inNumNull)
            AND (z.CnInvDate = y.iDateNull)
    GROUP BY
        z.cn_key,
        z.CnNum,
        z.CnInvNum,
        z.CnInvDate,
        y.ciKey
) AS x
    LEFT JOIN ags_invNum
        ON x.CnInvNum = ags_invNum.inNum
GROUP BY
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey
HAVING (((x.ciKey) Is Null));
