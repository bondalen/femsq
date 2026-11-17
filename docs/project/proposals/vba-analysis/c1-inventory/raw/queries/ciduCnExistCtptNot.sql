-- Access QueryDef: ciduCnExistCtptNot
-- Type: 0

SELECT ciduCnCtptExistNot.cidutCntrPrtNum, ciduCnCtptExistNot.cidutCntrPrtName, ciduCnCtptExistNot.cidutCntrPrtITN, ciduCnCtptExistNot.cidutCnName, ciduCnCtptExistNot.cidutCnDate, ciduCnCtptExistNot.cidutCnDateNull, ciduCnCtptExistNot.cidutCnNameNull, ciduCnNotLoad.countCnName
FROM ciduCnCtptExistNot LEFT JOIN ciduCnNotLoad ON (ciduCnCtptExistNot.cidutCnDateNull = ciduCnNotLoad.cidutCnDate) AND (ciduCnCtptExistNot.cidutCnNameNull = ciduCnNotLoad.cidutCnName) AND (ciduCnCtptExistNot.cidutCntrPrtNum = ciduCnNotLoad.cidutCntrPrtNum)
WHERE (((ciduCnNotLoad.countCnName) Is Null));
