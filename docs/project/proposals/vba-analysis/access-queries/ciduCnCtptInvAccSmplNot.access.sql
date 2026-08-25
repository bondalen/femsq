/*
 * Объект MS Access: сохранённый запрос ciduCnCtptInvAccSmplNot
 *
 * Назначение: СФ с парой СГК, без cnInvAccntSmpl (ciasKey IS NULL).
 * Anti-join в родителе All: (ciKey, account_key, БУиРГ).
 *
 * Зависимости: ciduCnCtptInvAccSmplAll.
 * Дамп: 26-0811_CtInvDbtUpl_/cidu-sql/ 2026-08-24 15:25
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * lastUpdated: 2026-08-24
 */

SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCnName, a.cidutCnNameNull, a.cidutCnDate, a.cidutCnDateNull, a.cidutCnInv, a.cidutCnInvNull, a.cn_key, a.cn_s_org_key, a.iKey, a.ciKey, a.account_num, a.account_key, a.ciasKey, a.ciasCn_s_org_smpl
FROM ciduCnCtptInvAccSmplAll AS a
WHERE (((a.ciasKey) Is Null));
