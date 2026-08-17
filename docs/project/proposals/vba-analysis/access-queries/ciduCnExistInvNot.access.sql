/*
 * Объект MS Access: сохранённый запрос ciduCnExistInvNot
 *
 * Назначение: пары (договор + номер СФ из свода) для уже найденных договоров
 * (ciduCnCtptExistList), с LEFT JOIN к agsCnInvNumsVariants и agsInvNumCount.
 * Потребитель SqlCnCtptExistInvNot: INSERT в CnInvDbtUplTblCnInv WHERE ciKey Is Null.
 *
 * Зависимости: ciduCnCtptExistList, CnInvDbtUplTbl (*Null), agsCnInvNumsVariants,
 * agsInvNumCount.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-15).
 *
 * lastUpdated: 2026-08-15
 */

SELECT
    w.cn_key,
    w.cidutCnNameNull,
    w.cidutCnInvNull,
    w.ciKey,
    agsInvNumCount.inNumCount
FROM (
    SELECT
        f.cn_key,
        f.cidutCnNameNull,
        f.cidutCnInvNull,
        g.ciKey
    FROM (
        SELECT
            u.cn_key,
            u.cidutCnNameNull,
            t.cidutCnInvNull
        FROM ciduCnCtptExistList AS u
        LEFT JOIN CnInvDbtUplTbl AS t
            ON (u.cidutCnDateNull = t.cidutCnDateNull)
            AND (u.cidutCnNameNull = t.cidutCnNameNull)
            AND (u.cidutCntrPrtNum = t.cidutCntrPrtNum)
        GROUP BY
            u.cn_key,
            u.cidutCnNameNull,
            t.cidutCnInvNull
    ) AS f
    LEFT JOIN agsCnInvNumsVariants AS g
        ON (f.cn_key = g.cn_key)
        AND (f.cidutCnInvNull = g.inNumNull)
    GROUP BY
        f.cn_key,
        f.cidutCnNameNull,
        f.cidutCnInvNull,
        g.ciKey
) AS w
LEFT JOIN agsInvNumCount ON w.cidutCnInvNull = agsInvNumCount.inNumNull
GROUP BY
    w.cn_key,
    w.cidutCnNameNull,
    w.cidutCnInvNull,
    w.ciKey,
    agsInvNumCount.inNumCount;
