/*
 * Объект MS Access: сохранённый запрос ciduCnNumNotLoad
 *
 * Назначение: договоры из буфера (ciduCnCtptExistNot), чей нормализованный номер
 * не встречается ни в одном ags_cnNum.cnnNumNull (Count(cn_key)=0).
 *
 * Родитель: ciduCnNotLoad. Потомок: ciduCnCtptExistNot.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-14).
 *
 * lastUpdated: 2026-08-14
 */

SELECT
    z.cidutCntrPrtNum,
    z.cidutCntrPrtName,
    z.cidutCntrPrtITN,
    z.cidutCnNameNull AS cidutCnName,
    z.cidutCnDateNull AS cidutCnDate,
    Count(y.cn_key) AS cnCount
FROM ciduCnCtptExistNot AS z
LEFT JOIN (
    SELECT
        n.cnnNumNull AS cn_number,
        o.cn_key
    FROM ags_cn AS o
    INNER JOIN ags_cnNum AS n ON o.cn_key = n.cnnCn
) AS y ON z.cidutCnNameNull = y.cn_number
GROUP BY
    z.cidutCntrPrtNum,
    z.cidutCntrPrtName,
    z.cidutCntrPrtITN,
    z.cidutCnNameNull,
    z.cidutCnDateNull
HAVING (((Count(y.cn_key)) = 0));
