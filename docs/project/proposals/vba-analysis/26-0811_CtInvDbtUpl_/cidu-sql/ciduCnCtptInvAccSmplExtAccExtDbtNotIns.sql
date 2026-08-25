-- Access QueryDef: ciduCnCtptInvAccSmplExtAccExtDbtNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-24 15:25

INSERT INTO ags_cn_inv_dbt ( cidCnInvAccntCtpt, cn_inv_date_start, cn_inv_date_maturity, debt_type, dbt_ttl, dbt_overd, doc_base, link, cn_inv_dbt_upl, [number], cidTimeOfEntry )
SELECT a.ciaKey, t.cidutFormtnDate, t.cidutMatrtyDate, "D" AS debtType, t.cidutDebt, t.cidutDebtOverdue, t.cidutDoc, t.cidutLink, t.cidutUnloadKey, t.cidutSheetNum, Now() AS TimeOfEntry
FROM (SELECT ciaKey, cidutCntrPrtNum, cidutCnNameNull, cidutCnDateNull, cidutCnInvNull, cidutCnInvNameNull, account_key FROM ciduCnCtptInvAccSmplExtAccExtDbtNot GROUP BY ciaKey, cidutCntrPrtNum, cidutCnNameNull, cidutCnDateNull, cidutCnInvNull, cidutCnInvNameNull, account_key)  AS a INNER JOIN CnInvDbtUplTbl AS t ON (a.cidutCntrPrtNum = t.cidutCntrPrtNum) AND (a.cidutCnNameNull = t.cidutCnNameNull) AND (a.cidutCnDateNull = t.cidutCnDateNull) AND (a.cidutCnInvNull = t.cidutCnInvNull) AND (a.cidutCnInvNameNull = t.cidutCnInvNameNull) AND (a.account_key = t.cidutAccount);
