-- Access QueryDef: cipuCtpt_All_OidNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT CntrPrtNum, CntrPrtName, org_id_key
FROM cipuCtpt_All_OId
WHERE org_id_key is null
ORDER BY CntrPrtNum;
