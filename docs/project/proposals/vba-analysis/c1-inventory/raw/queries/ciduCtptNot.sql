-- Access QueryDef: ciduCtptNot
-- Type: 0

SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, x.org_id_value_l, x.org, x.org_id_key
FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM CnInvDbtUplTbl GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN)  AS z LEFT JOIN (SELECT org_id_value_l, org, org_id_type, org_id_key FROM ags_org_id WHERE org_id_type = 1)  AS x ON z.cidutCntrPrtNum = x.org_id_value_l
WHERE (((x.org_id_key) Is Null));
