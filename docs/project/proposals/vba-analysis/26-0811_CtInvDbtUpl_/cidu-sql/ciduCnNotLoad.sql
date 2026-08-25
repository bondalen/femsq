-- Access QueryDef: ciduCnNotLoad
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT d.cidutCntrPrtNum, x.org_id_key, d.cidutCntrPrtName, d.cidutCntrPrtITN, d.cidutCnName, d.cidutCnDate, d.cnCount, e.countCnName
FROM (ciduCnNumNotLoad AS d LEFT JOIN (SELECT a.cidutCnName, count(a.cidutCnName) AS countCnName FROM ciduCnNumNotLoad AS a GROUP BY a.cidutCnName)  AS e ON d.cidutCnName = e.cidutCnName) LEFT JOIN (SELECT org_id_value_l, org, org_id_type, org_id_key FROM ags_org_id WHERE org_id_type = 1)  AS x ON d.cidutCntrPrtNum = x.org_id_value_l;
