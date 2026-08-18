-- Access QueryDef: cipuCn_CtptCnOneInv
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.CntrPrtNum, a.CntrPrtName, a.CnName, a.org_id_key, a.csosKey, a.cn_key, IIf(IsNull(b.ciputCnInv),"NullИлиПусто",IIf(b.ciputCnInv="","NullИлиПусто",b.ciputCnInv)) AS ciputCnInv
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, z.csosKey, z.CountCnKey, x.cn_key FROM cipuCn_CtptCnOne AS z LEFT JOIN agsCnCtptExequtorSmplBuirg AS x ON (z.CntrPrtNum = x.org_id_value_l) AND (z.CnName = x.cn_number))  AS a INNER JOIN (SELECT * FROM CnInvPmtUplTblNull)  AS b ON (a.CntrPrtNum = b.ciputCntrPrtNum) AND (a.CnName = b.ciputCnName)
GROUP BY a.CntrPrtNum, a.CntrPrtName, a.CnName, a.org_id_key, a.csosKey, a.cn_key, b.ciputCnInv
ORDER BY a.CntrPrtNum, a.CnName, b.ciputCnInv;
