-- Access QueryDef: ciduCnCtptInvAccSmplExtAccAlld
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT ciduCnCtptInvAccSmplExtAccAll.*, CnInvDbtUplTbl.*
FROM ciduCnCtptInvAccSmplExtAccAll LEFT JOIN CnInvDbtUplTbl ON (ciduCnCtptInvAccSmplExtAccAll.account_key = CnInvDbtUplTbl.cidutAccount) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnInvNameNull = CnInvDbtUplTbl.cidutCnInvNameNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnInvNull = CnInvDbtUplTbl.cidutCnInvNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnDateNull = CnInvDbtUplTbl.cidutCnDateNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnNameNull = CnInvDbtUplTbl.cidutCnNameNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCntrPrtNum = CnInvDbtUplTbl.cidutCntrPrtNum);
