-- Access QueryDef: ciduTblCnCtptInvAccNameCount
-- Type: 0

SELECT CnInvDbtUplTbl.cidutCntrPrtNum, CnInvDbtUplTbl.cidutCnNameNull, CnInvDbtUplTbl.cidutCnDateNull, CnInvDbtUplTbl.cidutCnInvNull, CnInvDbtUplTbl.cidutCnInvNameNull, CnInvDbtUplTbl.cidutAccount, Count(CnInvDbtUplTbl.FindDbtNum) AS DbtCount
FROM CnInvDbtUplTbl
GROUP BY CnInvDbtUplTbl.cidutCntrPrtNum, CnInvDbtUplTbl.cidutCnNameNull, CnInvDbtUplTbl.cidutCnDateNull, CnInvDbtUplTbl.cidutCnInvNull, CnInvDbtUplTbl.cidutCnInvNameNull, CnInvDbtUplTbl.cidutAccount;
