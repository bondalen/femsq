/*
 * Объект MS Access: сохранённый запрос ciduCtptNot
 *
 * Назначение: DISTINCT контрагенты из CnInvDbtUplTbl без org_id type=1 (БУиРГ).
 * Тот же смысл, что шаг orgNotInBuirg (лог отсутствующих организаций).
 *
 * Родитель: ciduTblCtptExist. Вложенных QueryDef нет.
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
    x.org_id_value_l,
    x.org,
    x.org_id_key
FROM (
    SELECT
        cidutCntrPrtNum,
        cidutCntrPrtName,
        cidutCntrPrtITN
    FROM CnInvDbtUplTbl
    GROUP BY
        cidutCntrPrtNum,
        cidutCntrPrtName,
        cidutCntrPrtITN
) AS z
LEFT JOIN (
    SELECT
        org_id_value_l,
        org,
        org_id_type,
        org_id_key
    FROM ags_org_id
    WHERE org_id_type = 1
) AS x ON z.cidutCntrPrtNum = x.org_id_value_l
WHERE (((x.org_id_key) Is Null));
