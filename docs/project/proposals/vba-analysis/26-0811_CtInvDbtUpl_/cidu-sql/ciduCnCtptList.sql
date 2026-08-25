-- Access QueryDef: ciduCnCtptList
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT c.cn_key, n.cnnNumNull AS cn_number, s.cn_s_key, s.cn_s_type, o.cn_s_org_key, c.cn_date, o.date_beg, o.date_end, o.csoCnDate, i.org_id_value_l, g.ogNm, m.csosKey, IIf(IsNull([csoCnDate]),#1/1/1900#,[csoCnDate]) AS csoCnDateNull
FROM ((((ags_cn AS c INNER JOIN ags_cn_s AS s ON c.cn_key = s.cn_key) INNER JOIN ags_cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s) INNER JOIN ags_cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl) INNER JOIN (ags_org_id AS i INNER JOIN ags_og AS g ON i.org = g.ogKey) ON m.csosOrgId = i.org_id_key) INNER JOIN ags_cnNum AS n ON c.cn_key = n.cnnCn
GROUP BY c.cn_key, n.cnnNumNull, s.cn_s_key, s.cn_s_type, o.cn_s_org_key, c.cn_date, o.date_beg, o.date_end, o.csoCnDate, i.org_id_value_l, g.ogNm, m.csosKey, IIf(IsNull([csoCnDate]),#1/1/1900#,[csoCnDate])
HAVING (((s.cn_s_type)=2));
