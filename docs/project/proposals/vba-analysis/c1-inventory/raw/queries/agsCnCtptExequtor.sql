-- Access QueryDef: agsCnCtptExequtor
-- Type: 0

SELECT c.cn_key, IIf(IsNull(c.cn_number),"NullИлиПусто",IIf(c.cn_number="","NullИлиПусто",Trim(c.cn_number))) AS cn_number, s.cn_s_key, s.cn_s_type, os.csosKey, o.cn_s_org_key, c.cn_date, o.date_beg, o.date_end, o.csoAsbuID, o.csoCnDate, i.org_id_value_l, g.ogNm
FROM (((ags_cn AS c INNER JOIN ags_cn_s AS s ON c.cn_key = s.cn_key) INNER JOIN ags_cn_s_org_smpl AS os ON s.cn_s_key = os.csosCn_s) INNER JOIN ags_cn_s_org AS o ON os.csosKey = o.csoCn_s_org_smpl) INNER JOIN (ags_org_id AS i INNER JOIN ags_og AS g ON i.org = g.ogKey) ON os.csosOrgId = i.org_id_key
WHERE (((s.cn_s_type)=2));
