-- Access QueryDef: agsOrgIdBUiRG
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:58

SELECT a.org_id_value_l, a.org_id_key
FROM ags_org_id AS a
WHERE (((a.org_id_type)=1));
