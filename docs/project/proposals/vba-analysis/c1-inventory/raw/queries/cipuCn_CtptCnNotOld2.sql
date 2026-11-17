-- Access QueryDef: cipuCn_CtptCnNotOld2
-- Type: 0

SELECT u.CntrPrtNum, u.CntrPrtName, u.CnName, u.org_id_key, count(u.cn_key) AS CountCnKey
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, e.cn_key FROM (SELECT CntrPrtNum, CntrPrtName, IIf(isnull(a.CnName),"NullИлиПусто",IIf(a.CnName="","NullИлиПусто",a.CnName)) AS CnName, org_id_key FROM cipuCn_Ctpt AS a)  AS z LEFT JOIN agsCnCtptExequtor AS e ON (z.CntrPrtNum = e.org_id_value_l) AND (z.CnName = e.cn_number) GROUP BY z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, e.cn_key)  AS u
GROUP BY u.CntrPrtNum, u.CntrPrtName, u.CnName, u.org_id_key
HAVING (((Count(u.cn_key))=0));
