-- Access QueryDef: cipuCn_CtptCnOneOld
-- Type: 0

SELECT m.CntrPrtNum, m.CntrPrtName, m.CnName, m.org_id_key, m.CountCnKey, agsCnCtptExequtor.cn_s_org_key
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, Count(agsCnCtptExequtor.cn_key) AS CountCnKey FROM (SELECT CntrPrtNum, CntrPrtName, IIf(isnull(a.CnName),"NullИлиПусто",IIf(a.CnName="","NullИлиПусто",a.CnName)) AS CnName, org_id_key FROM cipuCn_Ctpt AS a)  AS z LEFT JOIN agsCnCtptExequtor ON (z.CntrPrtNum = agsCnCtptExequtor.org_id_value_l) AND (z.CnName = agsCnCtptExequtor.cn_number) GROUP BY z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key HAVING (((Count(agsCnCtptExequtor.cn_key))=1)))  AS m LEFT JOIN agsCnCtptExequtor ON (m.CntrPrtNum = agsCnCtptExequtor.org_id_value_l) AND (m.CnName = agsCnCtptExequtor.cn_number);
