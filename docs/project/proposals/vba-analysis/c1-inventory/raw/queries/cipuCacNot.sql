-- Access QueryDef: cipuCacNot
-- Type: 0

SELECT a.cacOrNull
FROM CnInvPmtUplTblNull AS a
WHERE (((a.cacOrNull) Is Not Null))
GROUP BY a.cacOrNull, a.cstapCsta
HAVING (((a.cstapCsta) Is Null));
