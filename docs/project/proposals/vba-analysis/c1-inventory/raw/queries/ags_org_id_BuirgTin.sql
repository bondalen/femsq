-- Access QueryDef: ags_org_id_BuirgTin
-- Type: 0

SELECT c.org_id_value_l AS buirg, IIf(IsNull([d].[org_id_value_t]),"не один ИНН",[d].[org_id_value_t]) AS tin
FROM (SELECT b.org_id_value_l
FROM (SELECT 
i.org, i.org_id_type, i.org_id_value_t
FROM ags_org_id AS i
WHERE i.org_id_type =2 and i.org_id_value_t is not null
GROUP BY i.org, i.org_id_type, i.org_id_value_t
)  AS a INNER JOIN (SELECT o.org, o.org_id_value_l
FROM ags_org_id AS o
WHERE (((o.org_id_type)=1) AND ((o.org_id_value_l) Is Not Null))
GROUP BY o.org, o.org_id_value_l
)  AS b ON a.org = b.org
GROUP BY b.org_id_value_l
HAVING (((Count(a.org_id_value_t))=1))
ORDER BY Count(a.org_id_value_t) DESC
)  AS c LEFT JOIN (SELECT b.org_id_value_l, a.org_id_value_t
FROM (SELECT 
i.org, i.org_id_type, i.org_id_value_t
FROM ags_org_id AS i
WHERE i.org_id_type =2 and i.org_id_value_t is not null
GROUP BY i.org, i.org_id_type, i.org_id_value_t
)  AS a INNER JOIN (SELECT o.org, o.org_id_value_l
FROM ags_org_id AS o
WHERE (((o.org_id_type)=1) AND ((o.org_id_value_l) Is Not Null))
GROUP BY o.org, o.org_id_value_l
)  AS b ON a.org = b.org
)  AS d ON c.org_id_value_l = d.org_id_value_l;
