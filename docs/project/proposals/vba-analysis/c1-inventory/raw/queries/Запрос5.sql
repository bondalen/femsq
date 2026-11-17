-- Access QueryDef: Запрос5
-- Type: 0

SELECT i.org, Max(i.org_id_value_t) AS [Max-org_id_value_t], Count(i.org_id_key) AS [Count-org_id_key]
FROM ags_org_id AS i
GROUP BY i.org, i.org_id_type
HAVING (((Count(i.org_id_key))>1) AND ((i.org_id_type)=2));
