-- Access QueryDef: cipuCtpt_All_OidNot
-- Type: 0

SELECT CntrPrtNum, CntrPrtName, org_id_key
FROM cipuCtpt_All_OId
WHERE org_id_key is null
ORDER BY CntrPrtNum;
