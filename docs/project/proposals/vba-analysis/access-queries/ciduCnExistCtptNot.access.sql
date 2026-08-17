/*
 * Объект MS Access: сохранённый запрос ciduCnExistCtptNot
 *
 * Назначение: договоры из буфера, у которых номер уже есть в БД, но нет пары
 * (номер + БУиРГ исполнителя + дата) в ciduCnCtptList / аналоге.
 * Отличие от ciduCnNumNotLoad: HAVING Count(cn_key) > 0 (номер существует).
 *
 * VBA: Form_CnInvDbtUpl_gt_File_f.CnExistCtptNotLoad → OpenRecordset("ciduCnExistCtptNot").
 * Эталон длинного SQL: SqlLong.SqlCnExistCtptNotLoad() (устаревший join через
 * ags_cn.cn_number / cn_s_org без smpl). В FEMSQ T-SQL — та же семантика, что
 * у CnNotLoad: cnNum.cnnNumNull + cn_s → smpl → cn_s_org (как ciduCnCtptList).
 *
 * Диалект ниже: Microsoft Access SQL (Jet/ACE), реконструкция по SqlLong +
 * современной цепочке QueryDef. Не исполнять как есть на SQL Server.
 *
 * lastUpdated: 2026-08-14
 */

SELECT
    z.cidutCntrPrtNum,
    z.cidutCntrPrtName,
    z.cidutCntrPrtITN,
    z.cidutCnName,
    z.cidutCnDate,
    Count(y.cn_key) AS cnCount
FROM (
    SELECT
        k.cidutCntrPrtNum,
        k.cidutCntrPrtName,
        k.cidutCntrPrtITN,
        k.cidutCnName,
        k.cidutCnDate
    FROM ciduCnCtptExistNot AS k
    GROUP BY
        k.cidutCntrPrtNum,
        k.cidutCntrPrtName,
        k.cidutCntrPrtITN,
        k.cidutCnName,
        k.cidutCnDate
) AS z
LEFT JOIN (
    SELECT
        n.cnnNumNull AS cn_number,
        o.cn_key
    FROM ags_cn AS o
    INNER JOIN ags_cnNum AS n ON o.cn_key = n.cnnCn
) AS y ON z.cidutCnName = y.cn_number
GROUP BY
    z.cidutCntrPrtNum,
    z.cidutCntrPrtName,
    z.cidutCntrPrtITN,
    z.cidutCnName,
    z.cidutCnDate
HAVING (((Count(y.cn_key)) > 0));
