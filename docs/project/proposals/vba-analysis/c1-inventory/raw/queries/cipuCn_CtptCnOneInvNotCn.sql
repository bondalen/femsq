-- Access QueryDef: cipuCn_CtptCnOneInvNotCn
-- Type: 0

SELECT CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key, CnInvPmtUplTblCnInv.ciputciCsosKey, Count(CnInvPmtUplTblCnInv.ciputciCnInv) AS ciputciCnInvCount
FROM CnInvPmtUplTblCnInv
GROUP BY CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key, CnInvPmtUplTblCnInv.ciputciCsosKey;
