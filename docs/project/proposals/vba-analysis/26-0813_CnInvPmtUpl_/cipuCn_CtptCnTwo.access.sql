-- Access QueryDef: cipuCn_CtptCnTwo
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT u.CntrPrtNum, u.CntrPrtName, u.CnName, Count(u.cn_key) AS CountCnKey
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, e.cn_key FROM (SELECT CntrPrtNum, CntrPrtName, IIf(isnull(a.CnName),"NullИлиПусто",IIf(a.CnName="","NullИлиПусто",a.CnName)) AS CnName FROM cipuCn_Ctpt AS a)  AS z LEFT JOIN agsCnCtptExequtorSmplBuirg AS e ON (z.CntrPrtNum = e.org_id_value_l) AND (z.CnName = e.cn_number) GROUP BY z.CntrPrtNum, z.CntrPrtName, z.CnName, e.cn_key)  AS u
GROUP BY u.CntrPrtNum, u.CntrPrtName, u.CnName
HAVING (((Count(u.cn_key))>1));
