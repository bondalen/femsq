-- Access QueryDef: cipuCn_CtptCnOneInvTwoCn
-- Type: 0

SELECT CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key, Count(CnInvPmtUplTblCnInv.ciputciCnInv) AS ciputciCnInvCount
FROM CnInvPmtUplTblCnInv
GROUP BY CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key;
