-- Access QueryDef: cipuCn_CtptCnOneInvOneAcDc
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT e.ciKey, e.ciputAccount, e.account_key, e.csosKey, e.CntrPrtNum, e.CntrPrtName, e.CnName, e.cn_key, e.ciputCnInv, e.ciasKey, e.ciputCnInvDocCode, d.cn_inv_doc_key
FROM (SELECT a.ciKey, a.ciputAccount, a.account_key, a.csosKey, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.ciputCnInv, a.ciasKey, u.ciputCnInvDocCode FROM cipuCn_CtptCnOneInvOneAc AS a INNER JOIN CnInvPmtUplTblNull AS u ON (a.CntrPrtNum = u.ciputCntrPrtNum) AND (a.CnName = u.ciputCnName) AND (a.ciputCnInv = u.ciputCnInv) AND (a.ciputAccount = u.ciputAccount))  AS e LEFT JOIN ags_cn_inv_doc AS d ON e.ciputCnInvDocCode = d.cn_inv_doc_kod;
