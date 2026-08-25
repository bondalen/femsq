-- Access QueryDef: ciduCtptNot
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, x.org_id_value_l, x.org, x.org_id_key
FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM CnInvDbtUplTbl GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN)  AS z LEFT JOIN (SELECT org_id_value_l, org, org_id_type, org_id_key FROM ags_org_id WHERE org_id_type = 1)  AS x ON z.cidutCntrPrtNum = x.org_id_value_l
WHERE (((x.org_id_key) Is Null));
