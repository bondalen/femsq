-- Access QueryDef: cipuCn_CtptCnOneInvOneAcDcExt
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciKey, a.ciputAccount, a.account_key, a.csosKey, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.ciputCnInv, a.ciasKey, a.ciputCnInvDocCode, a.cn_inv_doc_key
FROM cipuCn_CtptCnOneInvOneAcDc AS a
WHERE (((a.cn_inv_doc_key) Is Not Null))
GROUP BY a.ciKey, a.ciputAccount, a.account_key, a.csosKey, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.ciputCnInv, a.ciasKey, a.ciputCnInvDocCode, a.cn_inv_doc_key;
