-- Access QueryDef: ciduCnCtptInvAccSmplExtAccAlld
-- Type: 0

SELECT ciduCnCtptInvAccSmplExtAccAll.*, CnInvDbtUplTbl.*
FROM ciduCnCtptInvAccSmplExtAccAll LEFT JOIN CnInvDbtUplTbl ON (ciduCnCtptInvAccSmplExtAccAll.account_key = CnInvDbtUplTbl.cidutAccount) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnInvNameNull = CnInvDbtUplTbl.cidutCnInvNameNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnInvNull = CnInvDbtUplTbl.cidutCnInvNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnDateNull = CnInvDbtUplTbl.cidutCnDateNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCnNameNull = CnInvDbtUplTbl.cidutCnNameNull) AND (ciduCnCtptInvAccSmplExtAccAll.cidutCntrPrtNum = CnInvDbtUplTbl.cidutCntrPrtNum);
