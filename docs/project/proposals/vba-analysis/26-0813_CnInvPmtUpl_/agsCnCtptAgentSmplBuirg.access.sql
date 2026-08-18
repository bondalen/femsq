-- Access QueryDef: agsCnCtptAgentSmplBuirg
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:58

SELECT c.cn_key, n.cnnNum AS cn_number, s.cn_s_key, s.cn_s_type, os.csosKey, i.org_id_key, i.org_id_type, c.cn_date, i.org_id_value_l, g.ogNm
FROM (((ags_cn AS c INNER JOIN ags_cn_s AS s ON c.cn_key = s.cn_key) INNER JOIN ags_cn_s_org_smpl AS os ON s.cn_s_key = os.csosCn_s) INNER JOIN (ags_org_id AS i INNER JOIN ags_og AS g ON i.org = g.ogKey) ON os.csosOrgId = i.org_id_key) INNER JOIN ags_cnNum AS n ON c.cn_key = n.cnnCn
WHERE (((s.cn_s_type)=1) AND ((i.org_id_type)=1));
