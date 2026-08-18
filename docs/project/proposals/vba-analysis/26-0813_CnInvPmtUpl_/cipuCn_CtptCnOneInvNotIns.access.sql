-- Access QueryDef: cipuCn_CtptCnOneInvNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-17 23:44

INSERT INTO CnInvPmtUplTblCnInv ( ciputciCntrPrtNum, ciputciCntrPrtName, ciputciCnName, ciputciCn_key, ciputciCsosKey, ciputciCnInv, ciputciCnInvNumCount )
SELECT cipuCn_CtptCnOneInvNot.CntrPrtNum, cipuCn_CtptCnOneInvNot.CntrPrtName, cipuCn_CtptCnOneInvNot.CnName, cipuCn_CtptCnOneInvNot.cn_key, cipuCn_CtptCnOneInvNot.csosKey, cipuCn_CtptCnOneInvNot.ciputCnInv, cipuCn_CtptCnOneInvNot.inNumCount
FROM cipuCn_CtptCnOneInvNot;
