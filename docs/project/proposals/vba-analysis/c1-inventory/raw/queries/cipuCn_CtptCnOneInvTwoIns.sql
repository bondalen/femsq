-- Access QueryDef: cipuCn_CtptCnOneInvTwoIns
-- Type: 64

INSERT INTO CnInvPmtUplTblCnInv ( ciputciCntrPrtNum, ciputciCntrPrtName, ciputciCnName, ciputciCn_key, ciputciCnInv )
SELECT cipuCn_CtptCnOneInvTwo.CntrPrtNum, cipuCn_CtptCnOneInvTwo.CntrPrtName, cipuCn_CtptCnOneInvTwo.CnName, cipuCn_CtptCnOneInvTwo.cn_key, cipuCn_CtptCnOneInvTwo.ciputCnInv
FROM cipuCn_CtptCnOneInvTwo;
