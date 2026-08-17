/*
 * Объект MS Access: сохранённый запрос ciduCnCtptExistNot
 *
 * Назначение: строки буфера (ciduTblCtptExist), для которых нет пары в ciduCnCtptList
 * по (номер договора, БУиРГ исполнителя, дата договора / Null→1900-01-01).
 *
 * Родитель: ciduCnNumNotLoad.
 * Потомки: ciduTblCtptExist, ciduCnCtptList.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-14).
 *
 * lastUpdated: 2026-08-14
 */

SELECT
    k.cidutCntrPrtNum,
    k.cidutCntrPrtName,
    k.cidutCntrPrtITN,
    k.cidutCnName,
    k.cidutCnDate,
    k.cidutCnDateNull,
    k.cidutCnNameNull
FROM ciduTblCtptExist AS k
LEFT JOIN ciduCnCtptList AS l
    ON (k.cidutCnNameNull = l.cn_number)
    AND (k.cidutCntrPrtNum = l.org_id_value_l)
    AND (k.cidutCnDateNull = l.csoCnDateNull)
GROUP BY
    k.cidutCntrPrtNum,
    k.cidutCntrPrtName,
    k.cidutCntrPrtITN,
    k.cidutCnName,
    k.cidutCnDate,
    k.cidutCnDateNull,
    k.cidutCnNameNull,
    l.cn_key
HAVING (((l.cn_key) Is Null));
