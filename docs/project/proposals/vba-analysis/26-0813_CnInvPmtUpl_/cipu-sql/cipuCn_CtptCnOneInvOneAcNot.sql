-- Access QueryDef: cipuCn_CtptCnOneInvOneAcNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT d.ciKey, d.csosKey, d.ciputAccount, d.CntrPrtNum, d.CntrPrtName, d.CnName, d.cn_key, d.ciputCnInv, d.account_key, f.ciasKey
FROM (SELECT c.ciKey, c.csosKey, c.ciputAccount, a.account_key, c.CntrPrtNum, c.CntrPrtName, c.CnName, c.cn_key, c.ciputCnInv FROM (SELECT a.ciKey, a.csosKey, b.ciputAccount, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.ciputCnInv FROM cipuCn_CtptCnOneInvOne AS a INNER JOIN CnInvPmtUplTblNull AS b ON (a.CntrPrtNum = b.ciputCntrPrtNum) AND (a.CnName = b.ciputCnName) AND (a.ciputCnInv = b.ciputCnInv) GROUP BY a.ciKey, a.csosKey, b.ciputAccount, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.ciputCnInv)  AS c INNER JOIN ags_accnt AS a ON c.ciputAccount = a.account_num)  AS d LEFT JOIN ags_cnInvAccntSmpl AS f ON (d.ciKey = f.ciasCnInv) AND (d.csosKey = f.ciasCn_s_org_smpl) AND (d.account_key = f.ciasAccnt)
GROUP BY d.ciKey, d.csosKey, d.ciputAccount, d.CntrPrtNum, d.CntrPrtName, d.CnName, d.cn_key, d.ciputCnInv, d.account_key, f.ciasKey
HAVING (((f.ciasKey) Is Null));
