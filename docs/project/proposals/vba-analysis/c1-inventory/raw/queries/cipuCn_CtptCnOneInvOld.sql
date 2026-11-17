-- Access QueryDef: cipuCn_CtptCnOneInvOld
-- Type: 0

SELECT a.[ciputCntrPrtNum], a.[ciputCntrPrtName], a.CnName, a.org_id_key, a.cn_s_org_key, a.cn_key, IIf(IsNull(b.ciputCnInv),"NullИлиПусто",IIf(b.ciputCnInv="","NullИлиПусто",b.ciputCnInv)) AS ciputCnInv
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, z.cn_s_org_key, z.CountCnKey, x.cn_key FROM cipuCn_CtptCnOne AS z LEFT JOIN agsCnCtptExequtor AS x ON (z.CnName = x.cn_number) AND (z.CntrPrtNum = x.org_id_value_l))  AS a INNER JOIN (SELECT * FROM CnInvPmtUplTbl)  AS b ON (a.CnName = b.ciputCnName) AND (a.[ciputCntrPrtNum]=b.ciputCntrPrtNum)
GROUP BY a.[ciputCntrPrtNum], a.[ciputCntrPrtName], a.CnName, a.org_id_key, a.cn_s_org_key, a.cn_key, b.ciputCnInv
ORDER BY a.[ciputCntrPrtNum], a.CnName, b.ciputCnInv;
