-- Access QueryDef: cipuCn_CtptCnOneInvNotOld
-- Type: 0

SELECT cipuCn_CtptCnOneInv.CntrPrtNum, cipuCn_CtptCnOneInv.CntrPrtName, cipuCn_CtptCnOneInv.CnName, cipuCn_CtptCnOneInv.cn_key, cipuCn_CtptCnOneInv.org_id_key, cipuCn_CtptCnOneInv.cn_s_org_key AS Выражение1, cipuCn_CtptCnOneInv.ciputCnInv, Count(ags_cnInv.ciKey) AS [Count-ciKey]
FROM cipuCn_CtptCnOneInv LEFT JOIN ags_cnInv ON (cipuCn_CtptCnOneInv.ciputCnInv = ags_cnInv.ciNum) AND (cipuCn_CtptCnOneInv.cn_key = ags_cnInv.ciCn)
GROUP BY cipuCn_CtptCnOneInv.CntrPrtNum, cipuCn_CtptCnOneInv.CntrPrtName, cipuCn_CtptCnOneInv.CnName, cipuCn_CtptCnOneInv.cn_key, cipuCn_CtptCnOneInv.org_id_key, cipuCn_CtptCnOneInv.cn_s_org_key, cipuCn_CtptCnOneInv.ciputCnInv
HAVING (((Count(ags_cnInv.ciKey))=0));
