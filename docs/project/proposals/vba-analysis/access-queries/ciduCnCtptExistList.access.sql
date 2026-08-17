/*
 * Объект MS Access: сохранённый запрос ciduCnCtptExistList
 *
 * Назначение: строки свода с контрагентом в БД, у которых найдена пара
 * номер+дата+исполнитель в ciduCnCtptList (HAVING cn_key Is Not Null).
 * Родитель: ciduCnExistInvNot.
 *
 * Зависимости: ciduTblCtptExist, ciduCnCtptList.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-15).
 *
 * lastUpdated: 2026-08-15
 */

SELECT
    k.cidutCntrPrtNum,
    k.cidutCntrPrtName,
    k.cidutCntrPrtITN,
    k.cidutCnName,
    k.cidutCnNameNull,
    k.cidutCnDate,
    k.cidutCnDateNull,
    l.cn_key,
    l.cn_s_org_key
FROM ciduTblCtptExist AS k
LEFT JOIN ciduCnCtptList AS l
    ON (k.cidutCnNameNull = l.cn_number)
    AND (k.cidutCnDateNull = l.csoCnDateNull)
    AND (k.cidutCntrPrtNum = l.org_id_value_l)
GROUP BY
    k.cidutCntrPrtNum,
    k.cidutCntrPrtName,
    k.cidutCntrPrtITN,
    k.cidutCnName,
    k.cidutCnNameNull,
    k.cidutCnDate,
    k.cidutCnDateNull,
    l.cn_key,
    l.cn_s_org_key
HAVING (((l.cn_key) Is Not Null));
