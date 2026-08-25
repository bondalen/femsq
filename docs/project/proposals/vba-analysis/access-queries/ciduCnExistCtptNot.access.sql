/*
 * Объект MS Access: сохранённый запрос ciduCnExistCtptNot
 *
 * Назначение: договоры из буфера, у которых нет пары (номер + БУиРГ + дата)
 * в ciduCnCtptList, но они не входят в ciduCnNotLoad (номер уже есть в cnNum).
 *
 * VBA: Form_CnInvDbtUpl_gt_File_f.CnExistCtptNotLoad → OpenRecordset("ciduCnExistCtptNot").
 * Живой SQL: ExistNot LEFT JOIN CnNotLoad WHERE countCnName IS NULL
 * (не HAVING Count(cn_key)>0 — та форма была реконструкцией S61n).
 *
 * FEMSQ: эквивалент HAVING COUNT(cn)>0 по ExistNot. UAT 910 (2026-08-24): оба набора = 2, Δ=0.
 *
 * Дамп: 26-0811_CtInvDbtUpl_/cidu-sql/ 2026-08-24 15:25
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * lastUpdated: 2026-08-24
 */

SELECT ciduCnCtptExistNot.cidutCntrPrtNum, ciduCnCtptExistNot.cidutCntrPrtName, ciduCnCtptExistNot.cidutCntrPrtITN, ciduCnCtptExistNot.cidutCnName, ciduCnCtptExistNot.cidutCnDate, ciduCnCtptExistNot.cidutCnDateNull, ciduCnCtptExistNot.cidutCnNameNull, ciduCnNotLoad.countCnName
FROM ciduCnCtptExistNot LEFT JOIN ciduCnNotLoad ON (ciduCnCtptExistNot.cidutCnDateNull = ciduCnNotLoad.cidutCnDate) AND (ciduCnCtptExistNot.cidutCnNameNull = ciduCnNotLoad.cidutCnName) AND (ciduCnCtptExistNot.cidutCntrPrtNum = ciduCnNotLoad.cidutCntrPrtNum)
WHERE (((ciduCnNotLoad.countCnName) Is Null));
