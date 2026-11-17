-- Access QueryDef: invDoubleNum
-- Type: 0

PARAMETERS iKey Long;
SELECT i.iKey, [in].inNum, ist.cidutCnNameNull, ist.cidutCnDateNull, ist.cidutDebt, ist.cidutDebtOverdue, ist.cidutCnInvName, ist.cidutAccount
FROM (ags_inv AS i INNER JOIN ags_invNum AS [in] ON i.iKey = [in].inInv) INNER JOIN CnInvDbtUplTbl AS ist ON [in].inNumNull = ist.cidutCnInvNull
WHERE (((i.iKey)=[iKey]));
