-- Access QueryDef: cipuCn_CtptCnOneInvTwoIns
-- Type: APPEND (64)
-- dumped: 2026-08-17 23:44

INSERT INTO CnInvPmtUplTblCnInv ( ciputciCntrPrtNum, ciputciCntrPrtName, ciputciCnName, ciputciCn_key, ciputciCnInv )
SELECT cipuCn_CtptCnOneInvTwo.CntrPrtNum, cipuCn_CtptCnOneInvTwo.CntrPrtName, cipuCn_CtptCnOneInvTwo.CnName, cipuCn_CtptCnOneInvTwo.cn_key, cipuCn_CtptCnOneInvTwo.ciputCnInv
FROM cipuCn_CtptCnOneInvTwo;
