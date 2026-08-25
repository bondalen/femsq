/*
 * Объект MS Access: сохранённый запрос ciduCnCtptExistInvAll
 *
 * Назначение: договоры ExistList + СФ из Tbl + варианты inv/cnInv.
 *
 * Дамп: 26-0811_CtInvDbtUpl_/cidu-sql/ 2026-08-24 15:25
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * lastUpdated: 2026-08-24
 */

SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull, f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, g.iKey, g.ciKey
FROM (SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull, h.cidutCnInv, h.cidutCnInvNull, h.cn_key, h.cn_s_org_key FROM (SELECT u.cidutCntrPrtNum, u.cidutCntrPrtName, u.cidutCntrPrtITN, u.cidutCnName, u.cidutCnNameNull, u.cidutCnDate, u.cidutCnDateNull, u.cn_key, u.cn_s_org_key, t.cidutCnInv, t.cidutCnInvNull, t.cidutAccount FROM ciduCnCtptExistList AS u LEFT JOIN CnInvDbtUplTbl AS t ON (u.cidutCntrPrtNum = t.cidutCntrPrtNum) AND (u.cidutCnNameNull = t.cidutCnNameNull) AND (u.cidutCnDateNull = t.cidutCnDateNull))  AS h GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull, h.cidutCnInv, h.cidutCnInvNull, h.cn_key, h.cn_s_org_key)  AS f LEFT JOIN agsCnInvNumsVariants AS g ON (f.cn_key = g.cn_key) AND (f.cidutCnInvNull = g.inNumNull) AND (f.cidutCnDateNull = g.csoCnDateNull)
GROUP BY f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull, f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, g.iKey, g.ciKey;
