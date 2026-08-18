-- Access QueryDef: cipuCn_CtptCnOneInvOneAcDcNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciKey, a.ciputAccount, a.account_key, a.csosKey, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.ciputCnInv, a.ciputCnInvDocCode, a.cn_inv_doc_key
FROM cipuCn_CtptCnOneInvOneAcDc AS a
WHERE (((a.cn_inv_doc_key) Is Null));
