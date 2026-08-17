/*
 * Объект MS Access: сохранённый запрос ciduCnNotLoad
 *
 * Назначение: итоговый набор шага CnNotLoad — «новые договора», не найденные
 * по номеру + дате + исполнителю; плюс org_id_key (БУиРГ) и countCnName (повторы №).
 *
 * Цепочка: ciduCnNotLoad → ciduCnNumNotLoad → ciduCnCtptExistNot
 *          → ciduTblCtptExist / ciduCnCtptList; ciduTblCtptExist → ciduCtptNot.
 *
 * VBA: Form_CnInvDbtUpl_gt_File_f.CnNotLoad → OpenRecordset("ciduCnNotLoad").
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-14).
 *
 * lastUpdated: 2026-08-14
 */

SELECT
    d.cidutCntrPrtNum,
    x.org_id_key,
    d.cidutCntrPrtName,
    d.cidutCntrPrtITN,
    d.cidutCnName,
    d.cidutCnDate,
    d.cnCount,
    e.countCnName
FROM (
    ciduCnNumNotLoad AS d
    LEFT JOIN (
        SELECT
            a.cidutCnName,
            Count(a.cidutCnName) AS countCnName
        FROM ciduCnNumNotLoad AS a
        GROUP BY a.cidutCnName
    ) AS e ON d.cidutCnName = e.cidutCnName
)
LEFT JOIN (
    SELECT
        org_id_value_l,
        org,
        org_id_type,
        org_id_key
    FROM ags_org_id
    WHERE org_id_type = 1
) AS x ON d.cidutCntrPrtNum = x.org_id_value_l;
