-- Access QueryDef: ciduTblCnCtptInvAccNameCount
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT CnInvDbtUplTbl.cidutCntrPrtNum, CnInvDbtUplTbl.cidutCnNameNull, CnInvDbtUplTbl.cidutCnDateNull, CnInvDbtUplTbl.cidutCnInvNull, CnInvDbtUplTbl.cidutCnInvNameNull, CnInvDbtUplTbl.cidutAccount, Count(CnInvDbtUplTbl.FindDbtNum) AS DbtCount
FROM CnInvDbtUplTbl
GROUP BY CnInvDbtUplTbl.cidutCntrPrtNum, CnInvDbtUplTbl.cidutCnNameNull, CnInvDbtUplTbl.cidutCnDateNull, CnInvDbtUplTbl.cidutCnInvNull, CnInvDbtUplTbl.cidutCnInvNameNull, CnInvDbtUplTbl.cidutAccount;
