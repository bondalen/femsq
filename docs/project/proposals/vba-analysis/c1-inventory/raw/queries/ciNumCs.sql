-- Access QueryDef: ciNumCs
-- Type: 0

SELECT ags_cnInv.ciCn, ags_invCs.iKey, ags_invCs.iNum
FROM ags_cnInv INNER JOIN ags_invCs ON ags_cnInv.ciInv = ags_invCs.iKey
ORDER BY ags_invCs.iNum;
