-- Access QueryDef: cipuInsPm
-- Type: 0

SELECT c.CntrPrtNum, c.CntrPrtName, c.CnName, c.ciputCnInv, c.ciputAccount, c.ciasKey, c.ciputCnInvDocCode, c.cn_inv_doc_key, c.ciputSheetNum, p.cn_inv_pm_key
FROM cipuCn_CtptCnOneInvOneAcDcExtPmTbl AS c LEFT JOIN ags_cn_inv_pm AS p ON (c.ciputSheetNum = p.number) AND (c.ciputUnloadKey = p.cn_inv_pm_upl) AND (c.cn_inv_doc_key = p.cn_inv_doc) AND (c.ciasKey = p.ciaCnInvAccntSmpl);
