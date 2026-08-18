-- Access QueryDef: cipuCacNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.cacOrNull
FROM CnInvPmtUplTblNull AS a
WHERE (((a.cacOrNull) Is Not Null))
GROUP BY a.cacOrNull, a.cstapCsta
HAVING (((a.cstapCsta) Is Null));
