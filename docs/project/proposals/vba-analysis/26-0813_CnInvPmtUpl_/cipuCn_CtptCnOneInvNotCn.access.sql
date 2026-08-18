-- Access QueryDef: cipuCn_CtptCnOneInvNotCn
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key, CnInvPmtUplTblCnInv.ciputciCsosKey, Count(CnInvPmtUplTblCnInv.ciputciCnInv) AS ciputciCnInvCount
FROM CnInvPmtUplTblCnInv
GROUP BY CnInvPmtUplTblCnInv.ciputciCntrPrtNum, CnInvPmtUplTblCnInv.ciputciCntrPrtName, CnInvPmtUplTblCnInv.ciputciCnName, CnInvPmtUplTblCnInv.ciputciCn_key, CnInvPmtUplTblCnInv.ciputciCsosKey;
