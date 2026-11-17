-- Access QueryDef: 24-0618_ИНН_больше_1_КПП
-- Type: 0

SELECT i.org_id_value_t, i.CountKPP, ags_org_id.org_id_value_t_ext, ags_og.ogNm
FROM ((SELECT i.org_id_value_t, i.CountKPP FROM (SELECT i.org_id_value_t, Count(i.org_id_value_t_ext) AS CountKPP FROM ags_org_id AS i WHERE (((i.org_id_type)=2)) GROUP BY i.org_id_value_t)  AS i WHERE (((i.CountKPP)>1)))  AS i LEFT JOIN ags_org_id ON i.org_id_value_t = ags_org_id.org_id_value_t) LEFT JOIN ags_og ON ags_org_id.org = ags_og.ogKey
ORDER BY i.org_id_value_t, ags_og.ogNm, ags_org_id.org_id_value_t_ext;
