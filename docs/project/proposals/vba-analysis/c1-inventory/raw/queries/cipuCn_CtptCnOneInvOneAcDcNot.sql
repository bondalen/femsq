-- Access QueryDef: cipuCn_CtptCnOneInvOneAcDcNot
-- Type: 0

SELECT a.ciKey, a.ciputAccount, a.account_key, a.csosKey, a.CntrPrtNum, a.CntrPrtName, a.CnName, a.ciputCnInv, a.ciputCnInvDocCode, a.cn_inv_doc_key
FROM cipuCn_CtptCnOneInvOneAcDc AS a
WHERE (((a.cn_inv_doc_key) Is Null));
