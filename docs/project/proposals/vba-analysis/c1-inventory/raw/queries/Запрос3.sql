-- Access QueryDef: Запрос3
-- Type: 0

SELECT y.[№ контрагента], y.org, y.org_id_type, x.org_id_value_t
FROM (SELECT z.[№ контрагента], i.org, i.org_id_type 
FROM 
(
SELECT q.[№ контрагента] 
FROM [ags_Yr_DbtChangesRsltD644_22-1116] AS q GROUP BY q.[№ контрагента]
)  AS z 
LEFT JOIN 
ags_org_id 
AS i ON z.[№ контрагента] = i.org_id_value_l 
WHERE (((i.org_id_type)=1))
)  AS y LEFT JOIN (SELECT i.org, Min(i.org_id_value_t) AS org_id_value_t
FROM ags_org_id AS i
where (((i.org_id_type)=2))
GROUP BY i.org, i.org_id_type
)  AS x ON y.org = x.org
ORDER BY x.org_id_value_t;
