-- Access QueryDef: cipuCtpt_All_OId
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT c.CntrPrtNum, c.CntrPrtName, d.org_id_key
FROM cipuCtpt_All AS c INNER JOIN agsOrgIdBUiRG AS d ON c.CntrPrtNum = d.org_id_value_l
ORDER BY c.CntrPrtNum;
